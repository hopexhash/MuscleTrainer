# MuscleTrainer

A modern, native iOS fitness app built around an **interactive human anatomy model**. Tap a muscle, discover the right exercises, build workouts manually or with the AI coach, train with a guided workout player, and track your progress with muscle heatmaps.

## Features

- **Interactive anatomy** — vector muscle regions (front/back, male/female) with tap selection, blue glow highlighting, and haptic feedback. Paths are cached and hit-tested against real shapes, not invisible rectangles.
- **Exercise library** — 97 realistic exercises covering 20+ muscle groups, with search, difficulty/equipment filter chips, step-by-step instructions, set recommendations per goal, and target-muscle visualizations.
- **AI Coach** — a sequential, card-based questionnaire (focus → muscles → goal → experience → location → equipment → duration → intensity) feeding a deterministic local workout generator behind an `AIWorkoutService` protocol, ready to swap in a real LLM backend. Generated workouts support swap, remove, reorder, tune, make easier/harder, shorten, and regenerate.
- **Workout builder** — name → pick muscles on the anatomy figure → pick exercises → tune sets/reps/rest, with drag-to-reorder.
- **Workout player** — set-by-set logging with weight/reps input, automatic rest timer (+15s / skip, haptic on finish), and a completion screen with duration, sets, reps, volume, and a trained-muscle heatmap.
- **Progress** — weekly count, streak, totals, volume trend, most/least trained muscles, and an aggregate body heatmap.
- **Theming** — System/Light/Dark with a centralized theme manager and a full semantic color system (electric-blue accent on deep dark surfaces).
- **Persistence** — SwiftData for profile, workouts, favorites, and full session history; seeded with 5 example workouts on first launch.

## Tech

- Swift + SwiftUI, MVVM, Swift Concurrency (async/await)
- SwiftData persistence, `@Observable` state
- No third-party dependencies
- iOS 17+, Xcode 16+ (uses file-system-synchronized project groups)

## Structure

```
MuscleTrainer/
  App/                  Entry point, root tabs, app state, seeding
  Core/DesignSystem/    Colors, tokens, typography, reusable components
  Core/Services/        Haptics
  Models/               Muscle, Exercise (+97-exercise catalog), SwiftData models
  Features/
    Anatomy/            Shape store (vector regions), interactive figure, Train screen
    Exercises/          Library, detail
    AIWorkout/          Coach, questionnaire flow, generator service, result editor
    Workouts/           Workouts tab, builder, add-to-workout
    Training/           Workout player, rest timer, completion
    Progress/           Dashboard + heatmap
    Profile/            Profile & settings
    Onboarding/         3-screen onboarding
```

## Notes

- Anatomy artwork is a clean, original vector representation authored in a normalized design space; professional SVG anatomy can be swapped into `AnatomyShapeStore` without touching exercise or selection logic.
- Exercise media uses an honest placeholder system (`ExerciseMedia`) that supports bundled animations, video, image sequences, and remote assets once real footage exists.
- Architecture leaves room for accounts, cloud sync, HealthKit, StoreKit 2 premium, and a hosted AI API.

## Build

Open `MuscleTrainer.xcodeproj` in Xcode 16 or newer and run on an iOS 17+ simulator or device.
