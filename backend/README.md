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
- Deployed anywhere (Render, Fly, a VPS…): use the `https://` URL

The app refreshes the manifest on launch and when you tap Refresh. Uploading requires the admin token; the manifest and the videos themselves are served without auth, so put the server behind HTTPS/auth if you expose it publicly.

## API

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/api/exercises` | – | catalog + upload status (admin UI) |
| GET | `/api/manifest` | – | `{ videos: { "bench-press": "/videos/bench-press.mp4" } }` |
| POST | `/api/videos/:id` | `X-Admin-Token` | multipart upload, field `video` |
| DELETE | `/api/videos/:id` | `X-Admin-Token` | remove a video |
| GET | `/videos/<file>` | – | video files (supports range requests) |

`exercises.json` is generated from the app's `ExerciseDatabase.swift`; regenerate it if you add exercises to the catalog so new IDs become uploadable.
