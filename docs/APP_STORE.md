# Getting MuscleTrainer on the App Store

Everything code-side is already in the repo. This is the checklist for the parts only you can do, plus copy-paste metadata for App Store Connect.

## Already in the project ✅

| Requirement | Where |
|---|---|
| App icon (1024×1024, required — builds fail validation without it) | `MuscleTrainer/Assets.xcassets/AppIcon.appiconset` |
| Privacy manifest (`PrivacyInfo.xcprivacy`, required since 2024; declares UserDefaults use, no tracking, no data collection) | `MuscleTrainer/PrivacyInfo.xcprivacy` |
| Privacy policy — in-app (Profile → Privacy & Terms) | `PrivacyPolicyView.swift` |
| Privacy policy + support — public URLs (Apple requires both in Connect) | served by your deployed media server at `/privacy.html` and `/support.html` |
| Export compliance (`ITSAppUsesNonExemptEncryption = NO` — skips the encryption questionnaire; the app only uses HTTPS, which is exempt) | `SupportFiles/Info.plist` |
| Health/medical disclaimer | inside the privacy policy (in-app + hosted) |
| iPhone-only targeting (so you don't need iPad screenshots) | project settings |

## Before you submit — one edit

`backend/public/support.html` and `backend-cloudflare/public/support.html` contain `CONTACT_EMAIL_HERE` — replace it with the email you want users to contact (I didn't want to hardcode your personal address without asking). Apple requires working support contact info.

## Your checklist (in order)

1. **Apple Developer Program** — enroll at developer.apple.com ($99/year).
2. **Bundle ID** — the project uses `com.muscletrainer.app`. Either register exactly that in your developer account, or change `PRODUCT_BUNDLE_IDENTIFIER` in Xcode (target → Signing & Capabilities) to something you own, e.g. `com.yourname.muscletrainer`. Set your **Team** there too — automatic signing handles the rest.
3. **Deploy the media server** (`backend-cloudflare/` is the free option) — its URL doubles as your privacy/support URLs.
4. **Create the app in App Store Connect** — My Apps → “+” → New App → iOS, name **MuscleTrainer**, your bundle ID, SKU `muscletrainer-001`.
5. **Archive & upload** — in Xcode: select “Any iOS Device (arm64)” → Product → Archive → Distribute App → App Store Connect. 
6. **Fill in the metadata** (copy below), add screenshots, submit for review.

## Copy-paste metadata

- **Name:** MuscleTrainer
- **Subtitle:** Tap a muscle. Train it right.
- **Category:** Health & Fitness
- **Price:** Free
- **Privacy Policy URL:** `https://<your-server>/privacy.html`
- **Support URL:** `https://<your-server>/support.html`

**Promotional text**
> Tap any muscle on the interactive body to find the right exercises — or let the AI Coach build your whole session.

**Description**
> MuscleTrainer is built around one idea: your body is the menu. Tap any muscle on the interactive anatomy figure — front or back, male or female — and instantly see every exercise that targets it, with clear step-by-step instructions and set recommendations for your goal.
>
> TRAIN
> • Interactive anatomy: tap a muscle, get its exercises
> • 97-exercise library with search and equipment/difficulty filters
> • Add your own looping demo video to any exercise
>
> AI COACH
> • Answer a few quick questions — focus, goal, experience, equipment, time
> • Get a balanced session: compounds first, sensible sets, reps and rest
> • Swap exercises, make it easier or harder, save it for later
>
> WORKOUT PLAYER
> • Log weight and reps set by set
> • Automatic rest timer with one-tap adjust
> • Finish with a summary and a muscle heatmap of what you trained
>
> PROGRESS
> • Streaks, weekly volume, most- and least-trained muscles
> • A body heatmap that shows where your training actually goes
>
> Private by design: everything stays on your iPhone. No account, no ads, no tracking.

**Keywords** (100 chars max)
> workout,gym,muscle,anatomy,exercise,fitness,training,strength,bodybuilding,hypertrophy,log,tracker

**App Privacy (the questionnaire):** answer **“Data is not collected”** for everything — the app has no accounts, no analytics, and stores all data on-device. (The optional media-server connection contacts only a server the user configures themselves and sends no personal data.)

**Age rating questionnaire:** answer None/No to everything → rating 4+.

**App Review notes** (paste into the review notes field)
> All features work without an account or any setup. Workout data is stored locally with SwiftData. “AI” workout generation runs entirely on-device with deterministic logic — no external AI service is contacted. The optional “Exercise videos” feature in Profile lets users stream exercise demo clips from a personal server they host themselves; the app makes no network requests unless that URL is configured.

## Screenshots

Required: **6.9-inch** iPhone set (e.g. iPhone 16 Pro Max simulator), 3–10 images. Suggested five, in this order:
1. Body tab with a muscle selected and the bottom sheet up
2. Exercise library (Chest)
3. AI Coach orb screen
4. Generated workout plan
5. Workout player mid-set (or the rest ring)

Take them in the Simulator: `Cmd+S` saves a correctly sized PNG. No device frames or extra marketing text needed.

## Sanity checks before submitting

- Run on a real device once; complete one workout end-to-end.
- Product → Analyze (no warnings expected).
- Settings → General → check the app's privacy label preview in Connect matches "Data Not Collected".
