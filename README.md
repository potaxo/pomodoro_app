# Pomodoro Focus 🍅

Lightweight, cross‑platform Pomodoro timer with a clean glass UI, local history, and insightful stats. Built with Flutter for desktop and mobile.

## Highlights

- Two timer modes: Stopwatch and Countdown
- One-tap presets: Crushed (5m), Half (12m), Whole (25m)
- Session logging with +/- counters and Save Session
- Local, offline storage via Hive
- Statistics page with:
  - Range chips: Day, Week, Month, Year, All
  - Stacked bar trend (crushed/half/whole)
  - Today vs Yesterday deltas
  - Totals summary and recent saves timeline
- Performance mode: Toggle in the AppBar to pause background animation and lighten effects

## Get started

Prerequisites: Flutter (stable) installed and set up.

Install dependencies

```powershell
flutter pub get
```

Run the app (auto-detects a connected device or desktop target)

```powershell
flutter run
```

Open the Home screen to track focus, then tap “Statistics” for insights.

## Build targets (optional)

- Android (APK)

```powershell
flutter build apk
```

- iOS (on macOS)

```powershell
flutter build ios
```

- Windows

```powershell
flutter build windows
```

- macOS / Linux / Web

```powershell
flutter build macos
flutter build linux
flutter build web
```

## Project layout

```
lib/
  main.dart                     # App entry, global ambient background
  models/
    pomodoro_record.dart        # Hive model (date, crushed, half, whole)
  screens/
    home_screen.dart            # Timer, counters, save session
    stats_screen.dart           # Charts, summaries, history management
  utils/
    perf.dart                   # Perf mode toggle (persisted)
    stats_utils.dart            # Aggregations, labels, comparisons
  widgets/
    ambient_background.dart     # Animated gradient background
    glass_container.dart        # Frosted glass container & button
```

## Data & privacy

- All data is stored locally in a Hive box named `pomodoro_box`.
- No network calls are made; your data stays on-device.

## Tips

- Tap a tomato row (Crushed/Half/Whole) to quickly set the countdown.
- Use +/- to adjust counts, then Save Session.
- In Statistics, switch ranges with chips; hover/tap bars for details (where supported).
- Use the speed icon to toggle Performance Mode if your device stutters.

## Troubleshooting

- “Adapter not found” after changing models:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

- Desktop targets not available: ensure Flutter desktop is enabled and you’re on a supported OS.
- If builds seem stale, try a clean:

```powershell
flutter clean; flutter pub get
```

## License

This project includes a LICENSE file in the repository root.

