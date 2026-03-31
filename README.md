# WorkoutBuilder

A native iOS fitness app for creating custom workouts, browsing a 800+ exercise library with animated demonstrations, and running fully configurable HIIT timers with live Apple Health integration.

Built with **SwiftUI**, **SwiftData**, **HealthKit**, and **Swift Charts**. Targets **iOS 17+** on iPhone and iPad.

---

## Features

### Workout Builder
- Create, edit, and save custom workout routines
- Browse and search a library of 800+ exercises sourced from the [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
- Filter exercises by category, equipment, and difficulty level
- Configure sets, reps, and duration per exercise
- Mark workouts as complete to track progress over time

### Exercise Detail
- Animated image demonstrations that crossfade between start and end positions
- Muscle group breakdown (primary and secondary)
- Equipment requirements, force type, and difficulty level
- Step-by-step instructions

### HIIT Timer
- Two modes: **Uniform** (equal intervals) and **Work/Rest** (alternating phases)
- Preset intervals from 15s to 2min, total durations up to 60min
- 5 customizable sounds (chime, bell, beep, whistle, buzzer) for interval and completion alerts
- Live progress ring and interval countdown bar
- Pause, resume, reset, and stop controls

### Apple Health Integration
- Reads heart rate, step count, and active calories during sessions
- Writes completed HIIT workouts and calories burned back to Apple Health
- Post-session summary with average/max BPM, calorie count, and a heart rate chart

### Workout History Dashboard
- Weekly streak tracker
- 30-day activity bar chart
- Exercise category donut chart breakdown
- Completed workout log with dates and exercise counts

---

## Architecture

```
WorkoutBuilderApp/
  Main/                  App entry point, SwiftData container setup, legacy migration
  Models/                SwiftData models (Workout, WorkoutExercise), Exercise, HIITTimer
  ViewModels/            WorkoutBuilderViewModel, HIITTimerViewModel
  Services/              ExerciseService (network + cache), HealthKitManager, ImageCache
  Views/                 All SwiftUI views (11 files)
  Resources/             Bundled fallback exercise data
  Sounds/                5 .wav files for timer alerts
```

**Key design decisions:**

- **MVVM with service layer** -- Views are thin and declarative. ViewModels own state and business logic. Services handle network, caching, and system framework integration.
- **SwiftData persistence** -- Workouts are stored in an encrypted SQLite database via SwiftData, with automatic lightweight schema migration. A one-time migration path converts legacy UserDefaults data on first launch.
- **Dependency injection** -- `ExerciseService` accepts a `URLSessionProtocol`, enabling deterministic unit tests with mock network responses.
- **Snapshot-style exercise storage** -- `WorkoutExercise` stores a JSON-encoded copy of the `Exercise` at save time, so workout history is never affected by upstream exercise data changes.
- **Offline-first** -- Exercises are cached with a 7-day TTL. If both network and cache fail, a bundled fallback dataset of 20 exercises loads from the app binary.
- **Image security** -- All image URLs are validated for HTTPS and an allowlisted host before loading. Images are cached in memory via `NSCache` with a 200-item limit.
- **Paginated loading** -- Both workouts (via SwiftData `fetchLimit`) and exercises (via display batching) load in pages of 50 to keep memory usage low.
- **Cached analytics** -- History metrics (streak, daily counts, category breakdown) are computed once and invalidated only when the underlying data changes.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI, Swift Charts |
| Persistence | SwiftData |
| Health | HealthKit |
| Networking | URLSession (async/await) |
| Audio | AVFoundation |
| Image Caching | NSCache |
| Timer | Combine (Timer.publish) |
| Testing | Swift Testing, XCTest |

---

## Testing

**101 tests** across three layers:

| Suite | Tests | Coverage |
|-------|-------|----------|
| Unit - ViewModel | 25 | Workout CRUD, filter combinations, persistence round-trips, completion |
| Unit - HIITTimer | 26 | Defaults, state transitions, tick progression, phase changes, formatting |
| Unit - ExerciseService | 18 | Decoding, error handling, search, filtering, cache TTL, display batching |
| Integration | 18 | HealthKit flow, sound files, network failures, SwiftData cascade deletes, image validation |
| UI | 7 | Tab navigation, workout creation dialog, empty states, launch performance |

Run tests in Xcode with `Cmd+U` or via command line:
```bash
xcodebuild test -scheme WorkoutBuilderApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

---

## Getting Started

1. Clone the repository
2. Open `WorkoutBuilderApp.xcodeproj` in Xcode
3. Select a simulator or device target
4. Build and run (`Cmd+R`)

HealthKit features require a physical device or Xcode simulator with Health data configured.

---

## Privacy

This app collects health and fitness data strictly for app functionality. No data is tracked, linked to identity, or shared with third parties. See `PrivacyInfo.xcprivacy` for the full declaration.


