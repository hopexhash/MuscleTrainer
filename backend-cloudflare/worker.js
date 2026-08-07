/**
 * MuscleTrainer media server — Cloudflare Workers + R2 edition.
 *
 * Free-tier friendly: always-on (no sleeping), videos live in an R2 bucket
 * (10 GB free, no egress charges). Same API surface as the Node server, so the
 * iOS app and the admin page work unchanged:
 *
 *   GET    /api/exercises     catalog + upload status (admin UI)
 *   GET    /api/manifest      { videos: { exerciseID: "/videos/<file>" } }
 *   POST   /api/videos/:id    multipart upload, field "video"  (X-Admin-Token)
 *   DELETE /api/videos/:id    remove a video                   (X-Admin-Token)
 *   GET    /videos/<file>     streams from R2 with Range support (looping playback)
 *
 * The admin page itself is served from ./public via the Workers assets binding.
 *
 * Note: Workers requests are capped at 100 MB, so keep clips short (a 10–15s
 * loop is typically 10–30 MB). ADMIN_TOKEN is set in wrangler.toml or the dashboard.
 */

import exercises from './exercises.json';

const ALLOWED_EXT = ['.mp4', '.mov', '.m4v', '.webm'];
const CONTENT_TYPES = {
  '.mp4': 'video/mp4',
  '.mov': 'video/quicktime',
  '.m4v': 'video/x-m4v',
  '.webm': 'video/webm',
};
const exerciseIDs = new Set(exercises.map(e => e.id));

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  });

function extOf(name) {
  const i = name.lastIndexOf('.');
  return i === -1 ? '' : name.slice(i).toLowerCase();
}

async function findVideoKey(env, exerciseID) {
  for (const ext of ALLOWED_EXT) {
    const head = await env.VIDEOS.head(exerciseID + ext);
    if (head) return exerciseID + ext;
  }
  return null;
}

async function listVideoKeys(env) {
  const keys = new Map(); // exerciseID -> key
  let cursor;
  do {
    const page = await env.VIDEOS.list({ cursor });
    for (const obj of page.objects) {
      const ext = extOf(obj.key);
      const id = obj.key.slice(0, obj.key.length - ext.length);
      if (ALLOWED_EXT.includes(ext) && exerciseIDs.has(id)) keys.set(id, obj.key);
    }
    cursor = page.truncated ? page.cursor : undefined;
  } while (cursor);
  return keys;
}

async function removeVideos(env, exerciseID) {
  await env.VIDEOS.delete(ALLOWED_EXT.map(ext => exerciseID + ext));
}

function requireToken(request, env) {
  const expected = env.ADMIN_TOKEN || 'muscle-admin';
  return request.headers.get('x-admin-token') === expected;
}

async function serveVideo(request, env, key) {
  const rangeHeader = request.headers.get('Range');
  const contentType = CONTENT_TYPES[extOf(key)] || 'video/mp4';
  const baseHeaders = {
    'Content-Type': contentType,
    'Accept-Ranges': 'bytes',
    'Cache-Control': 'public, max-age=60',
    'Access-Control-Allow-Origin': '*',
  };

  if (rangeHeader) {
    const match = /^bytes=(\d*)-(\d*)$/.exec(rangeHeader.trim());
    if (match && (match[1] !== '' || match[2] !== '')) {
      let object;
      let start;
      if (match[1] === '') {
        // suffix range: last N bytes
        const suffix = Number(match[2]);
        object = await env.VIDEOS.get(key, { range: { suffix } });
        if (!object) return json({ error: 'Not found.' }, 404);
        start = object.size - Math.min(suffix, object.size);
      } else {
        start = Number(match[1]);
        const end = match[2] === '' ? undefined : Number(match[2]);
        const length = end === undefined ? undefined : end - start + 1;
        object = await env.VIDEOS.get(key, { range: { offset: start, length } });
        if (!object) return json({ error: 'Not found.' }, 404);
      }
      const served = object.range
        ? (object.range.length ?? object.size - (object.range.offset ?? 0))
        : object.size;
      const offset = object.range?.offset ?? start ?? 0;
      return new Response(object.body, {
        status: 206,
        headers: {
          ...baseHeaders,
          'Content-Length': String(served),
          'Content-Range': `bytes ${offset}-${offset + served - 1}/${object.size}`,
        },
      });
    }
  }

  const object = await env.VIDEOS.get(key);
  if (!object) return json({ error: 'Not found.' }, 404);
  return new Response(object.body, {
    headers: { ...baseHeaders, 'Content-Length': String(object.size), ETag: object.httpEtag },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname } = url;
    const method = request.method;

    if (method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS',
          'Access-Control-Allow-Headers': 'x-admin-token,content-type',
        },
      });
    }

    if (pathname === '/api/exercises' && method === 'GET') {
      const keys = await listVideoKeys(env);
      return json({
        exercises: exercises.map(e => ({
          ...e,
          hasVideo: keys.has(e.id),
          videoURL: keys.has(e.id) ? `/videos/${keys.get(e.id)}` : null,
        })),
      });
    }

    if (pathname === '/api/manifest' && method === 'GET') {
      const keys = await listVideoKeys(env);
      const videos = {};
      for (const [id, key] of keys) videos[id] = `/videos/${key}`;
      return json({ videos, updatedAt: new Date().toISOString() });
    }

    const apiVideo = pathname.match(/^\/api\/videos\/([a-z0-9-]+)$/);
    if (apiVideo && (method === 'POST' || method === 'DELETE')) {
      if (!requireToken(request, env)) return json({ error: 'Invalid admin token.' }, 401);
      const id = apiVideo[1];
      if (!exerciseIDs.has(id)) return json({ error: `Unknown exercise "${id}".` }, 404);

      if (method === 'DELETE') {
        await removeVideos(env, id);
        return json({ ok: true });
      }

      let form;
      try {
        form = await request.formData();
      } catch {
        return json({ error: 'Expected a multipart upload with field "video".' }, 400);
      }
      const file = form.get('video');
      if (!file || typeof file === 'string') {
        return json({ error: 'No video file received. Use form field "video".' }, 400);
      }
      const ext = extOf(file.name || '');
      if (!ALLOWED_EXT.includes(ext)) {
        return json({ error: `Unsupported file type "${ext || 'unknown'}". Use ${ALLOWED_EXT.join(', ')}.` }, 400);
      }
      await removeVideos(env, id);
      await env.VIDEOS.put(id + ext, await file.arrayBuffer(), {
        httpMetadata: { contentType: CONTENT_TYPES[ext] },
      });
      return json({ ok: true, videoURL: `/videos/${id}${ext}` });
    }

    const videoFile = pathname.match(/^\/videos\/([a-z0-9-]+\.[a-z0-9]+)$/);
    if (videoFile && method === 'GET') {
      return serveVideo(request, env, videoFile[1]);
    }

    // Anything else falls through to the assets binding (admin page) via wrangler's
    // asset routing; direct worker hits for unknown paths get a 404.
    if (env.ASSETS) return env.ASSETS.fetch(request);
    return json({ error: 'Not found.' }, 404);
  },
};
