# MuscleTrainer media server

A small self-hosted backend for your own exercise demo videos. Upload a short clip per exercise through the admin page; the iOS app fetches the manifest and plays your clips as muted loops in the exercise detail screen and workout player.

## Run it

```bash
cd backend
npm install
ADMIN_TOKEN=pick-a-secret npm start        # default port 4000
```

Open http://localhost:4000 — search an exercise, paste your token, and upload an `.mp4`, `.mov`, `.m4v`, or `.webm` (max 300 MB; short 5–15 second clips work best as loops).

Videos land in `backend/videos/` named `<exercise-id>.<ext>` — you can also just drop correctly named files in that folder by hand.

## Connect the app

In the app: **Profile → Exercise videos → Media server URL**, e.g.

- Simulator: `http://localhost:4000`
- iPhone on the same Wi-Fi: `http://<your-mac-ip>:4000`
- Deployed anywhere (see **Deploy it** below): use the `https://` URL

The app refreshes the manifest on launch and when you tap Refresh. Uploading requires the admin token; the manifest and the videos themselves are served without auth, so put the server behind HTTPS/auth if you expose it publicly.

## Deploy it (always online)

Uploads live on the server's disk, so the host **must have a persistent volume** — on ephemeral free tiers your videos disappear on every restart. The server reads `VIDEOS_DIR` so you can point it at the mounted volume. Three good options, all giving you an `https://` URL that works in the app with zero ATS fuss:

### Free: Cloudflare Workers + R2
See [`backend-cloudflare/`](../backend-cloudflare/README.md) — the same server ported to Cloudflare Workers with videos in R2. Always-on, free within generous limits (10 GB storage). Recommended if you want $0.

### Railway (easiest, all in the browser — ~$5/mo usage-based)
1. Go to [railway.app](https://railway.app) → New Project → **Deploy from GitHub repo** → pick this repo.
2. In the service settings, set **Root Directory** to `backend`.
3. **Variables** tab → add `ADMIN_TOKEN` = your secret, `VIDEOS_DIR` = `/data/videos`.
4. Right-click the service → **Attach Volume** → mount path `/data`.
5. **Settings → Networking → Generate Domain.** That `https://…up.railway.app` URL is what you paste into the app (Profile → Exercise videos) and open in a browser for the admin page.

### Render (one-click blueprint — Starter plan, disk included)
The repo root has a `render.yaml`. On [render.com](https://render.com): New → **Blueprint** → select this repo → it creates the service with a 10 GB disk at `/data` and prompts you for `ADMIN_TOKEN`. Free instances are not suitable (no disk, and they sleep).

### Fly.io (CLI)
`backend/fly.toml` is ready — see the comments at the top of that file for the four commands.

### Any VPS (Hetzner/DigitalOcean, ~$5/mo)
```bash
git clone <this repo> && cd MuscleTrainer/backend
npm ci --omit=dev
ADMIN_TOKEN=pick-a-secret nohup node server.js &   # or use pm2/systemd + a caddy/nginx HTTPS proxy
```

After deploying: open `https://your-host/` in any browser to upload videos, and paste the same URL into the app. Reminder: uploads need the token, but the manifest and video files are public — keep the URL to yourself or add auth in front if that matters to you.

## API

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/api/exercises` | – | catalog + upload status (admin UI) |
| GET | `/api/manifest` | – | `{ videos: { "bench-press": "/videos/bench-press.mp4" } }` |
| POST | `/api/videos/:id` | `X-Admin-Token` | multipart upload, field `video` |
| DELETE | `/api/videos/:id` | `X-Admin-Token` | remove a video |
| GET | `/videos/<file>` | – | video files (supports range requests) |

`exercises.json` is generated from the app's `ExerciseDatabase.swift`; regenerate it if you add exercises to the catalog so new IDs become uploadable.
