# MuscleTrainer media server — free edition (Cloudflare Workers + R2)

The same media server as `backend/`, ported to Cloudflare Workers with videos in R2 object storage. Same API, same admin page, and the iOS app connects to it identically — but it runs **free, always-on, with no sleeping and no bandwidth charges**:

- Workers free plan: 100,000 requests/day — far beyond personal use
- R2 free tier: 10 GB of video storage, $0 egress
- Cloudflare asks for a payment card when enabling R2 as verification, but usage within the free tier costs $0

One limit to know: Workers cap uploads at **100 MB per request**, so keep clips short — a 10–15 second loop is typically 10–30 MB, which is exactly what you want for exercise demos anyway.

## Deploy (about 5 minutes)

```bash
cd backend-cloudflare
npx wrangler login                                  # opens browser to your Cloudflare account
npx wrangler r2 bucket create muscletrainer-videos  # enable R2 in the dashboard if prompted
npx wrangler deploy
```

The deploy prints your URL, e.g. `https://muscletrainer-media.<you>.workers.dev`:

- Open it in any browser → the admin page, upload videos per exercise
- Paste it into the app → Profile → Exercise videos

Then change the admin token: edit `ADMIN_TOKEN` in `wrangler.toml` and redeploy, or set it in the dashboard (Workers & Pages → muscletrainer-media → Settings → Variables).

No terminal at all? Cloudflare can also deploy straight from GitHub: dashboard → Workers & Pages → Create → connect this repo with root directory `backend-cloudflare` — then create the R2 bucket `muscletrainer-videos` in the R2 tab.

## Also free, no card at all

Run the plain Node server (`backend/`) on a computer at home and expose it with [Tailscale Funnel](https://tailscale.com/kb/1223/funnel) (free plan):

```bash
cd backend && ADMIN_TOKEN=pick-a-secret npm start
tailscale funnel 4000
```

You get a stable `https://<machine>.<tailnet>.ts.net` URL that works from anywhere — the trade-off is that videos are only available while that computer is on.

## Files

- `worker.js` — the entire server (routing, R2 storage, Range-request streaming)
- `public/index.html` — admin page (identical to `backend/public/`)
- `exercises.json` — exercise catalog (copy of `backend/exercises.json`; keep both in sync when the app's catalog changes)

All endpoints, including 206 partial responses for video streaming, are covered by the same smoke tests as the Node server.
