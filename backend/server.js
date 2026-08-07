/**
 * MuscleTrainer media server
 *
 * Hosts exercise demo videos for the iOS app:
 *   - Admin UI at /            → upload a looping video per exercise
 *   - GET  /api/exercises      → catalog + which exercises have videos
 *   - GET  /api/manifest       → { videos: { exerciseID: "/videos/<file>" } } (used by the app)
 *   - POST /api/videos/:id     → upload/replace a video (requires X-Admin-Token)
 *   - DELETE /api/videos/:id   → remove a video (requires X-Admin-Token)
 *   - GET  /videos/<file>      → video files, with HTTP range support for streaming
 *
 * Configuration (environment variables):
 *   PORT         default 4000
 *   ADMIN_TOKEN  token required to upload/delete. Defaults to "muscle-admin" — change it.
 */

const express = require('express');
const multer = require('multer');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 4000;
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || 'muscle-admin';
const VIDEOS_DIR = path.join(__dirname, 'videos');
const ALLOWED_EXT = new Set(['.mp4', '.mov', '.m4v', '.webm']);
const MAX_SIZE_MB = 300;

if (!process.env.ADMIN_TOKEN) {
  console.warn('⚠️  ADMIN_TOKEN not set — using the default "muscle-admin". Set your own before exposing this server.');
}

fs.mkdirSync(VIDEOS_DIR, { recursive: true });

const exercises = JSON.parse(fs.readFileSync(path.join(__dirname, 'exercises.json'), 'utf8'));
const exerciseIDs = new Set(exercises.map(e => e.id));

const app = express();
app.use(cors());

// ---------- helpers ----------

function videoFile(exerciseID) {
  for (const ext of ALLOWED_EXT) {
    const file = exerciseID + ext;
    if (fs.existsSync(path.join(VIDEOS_DIR, file))) return file;
  }
  return null;
}

function removeVideos(exerciseID) {
  for (const ext of ALLOWED_EXT) {
    const p = path.join(VIDEOS_DIR, exerciseID + ext);
    if (fs.existsSync(p)) fs.unlinkSync(p);
  }
}

function requireToken(req, res, next) {
  if (req.get('x-admin-token') !== ADMIN_TOKEN) {
    return res.status(401).json({ error: 'Invalid admin token.' });
  }
  next();
}

// ---------- upload ----------

const storage = multer.diskStorage({
  destination: VIDEOS_DIR,
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, req.params.id + ext);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: MAX_SIZE_MB * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (!ALLOWED_EXT.has(ext)) {
      return cb(new Error(`Unsupported file type "${ext}". Use ${[...ALLOWED_EXT].join(', ')}.`));
    }
    cb(null, true);
  },
});

// ---------- routes ----------

app.get('/api/exercises', (req, res) => {
  res.json({
    exercises: exercises.map(e => {
      const file = videoFile(e.id);
      return { ...e, hasVideo: !!file, videoURL: file ? `/videos/${file}` : null };
    }),
  });
});

app.get('/api/manifest', (req, res) => {
  const videos = {};
  for (const e of exercises) {
    const file = videoFile(e.id);
    if (file) videos[e.id] = `/videos/${file}`;
  }
  res.json({ videos, updatedAt: new Date().toISOString() });
});

app.post('/api/videos/:id', requireToken, (req, res) => {
  if (!exerciseIDs.has(req.params.id)) {
    return res.status(404).json({ error: `Unknown exercise "${req.params.id}".` });
  }
  removeVideos(req.params.id); // replace any previous upload, regardless of extension
  upload.single('video')(req, res, err => {
    if (err) {
      const message = err.code === 'LIMIT_FILE_SIZE'
        ? `File is too large. Maximum is ${MAX_SIZE_MB} MB.`
        : err.message;
      return res.status(400).json({ error: message });
    }
    if (!req.file) return res.status(400).json({ error: 'No video file received. Use form field "video".' });
    res.json({ ok: true, videoURL: `/videos/${req.file.filename}` });
  });
});

app.delete('/api/videos/:id', requireToken, (req, res) => {
  if (!exerciseIDs.has(req.params.id)) {
    return res.status(404).json({ error: `Unknown exercise "${req.params.id}".` });
  }
  removeVideos(req.params.id);
  res.json({ ok: true });
});

// Video files — express.static handles HTTP Range requests, so the app can stream and loop.
app.use('/videos', express.static(VIDEOS_DIR, {
  setHeaders: res => res.set('Cache-Control', 'public, max-age=60'),
}));

app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
  console.log(`MuscleTrainer media server running:`);
  console.log(`  Admin UI   → http://localhost:${PORT}`);
  console.log(`  Manifest   → http://localhost:${PORT}/api/manifest`);
  console.log(`  Videos dir → ${VIDEOS_DIR}`);
});
