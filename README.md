# Pomodoro Focus App 🍅

Cross‑platform Pomodoro timer with a clean UI, local history, and insightful statistics. Built with Flutter for desktop and mobile.

## Features

- Timer modes: Stopwatch and Countdown
- Quick-set focus sessions: Crushed (5m), Half (12m), Whole (25m)
- Session logging: +/- counters per type, then Save Session to store
- Local storage with Hive (offline, on-device)
- Statistics page:
  - Range chips: Day, Week, Month, Year, All
  - Stacked bar trend by type (crushed/half/whole)
  - Today vs Yesterday with deltas (tomatoes and minutes)
  - Totals summary (counts and total time)
  - Recent Saves timeline with timestamps
- Data management: delete a specific record or clear all history (both confirmed)

## Quick start

1) Install Flutter (stable): https://docs.flutter.dev/get-started/install

2) Get dependencies
```sh
flutter pub get
```

3) Run
```sh
flutter run
```

Open the Home screen to track sessions, then tap “Statistics” to view insights.

## Usage tips

- Tap a tomato row (Crushed/Half/Whole) to set the countdown duration instantly.
- Use +/- to adjust the count, then “Save Session” to store it.
- On the Statistics page:
  - Switch ranges with the chips (Day/Week/Month/Year/All).
  - See composition in the stacked bars; hover/tap bars for details.
  - Compare Today vs Yesterday at a glance (green/red delta).
  - Manage history:
    - Delete a single record via the trash icon in “Recent Saves”.
    - Clear all history via the AppBar delete-forever button.

## Project structure

```
lib/
  main.dart
  models/
    pomodoro_record.dart        # Hive model (date, crushed, half, whole)
  screens/
    home_screen.dart            # Timer, counters, save
    stats_screen.dart           # Statistics and history management
  utils/
    stats_utils.dart            # Aggregation, labeling, comparisons
  widgets/
    ambient_background.dart     # Animated gradient background
    glass_container.dart        # Glassy UI container/button
```

## Data and privacy

- Sessions are stored locally in a Hive box named `pomodoro_box`.
- No network calls or external services are used.

## Development

- Analyze code
```sh
flutter analyze
```

- Run tests (widget sample included)
```sh
flutter test
```

- If you modify Hive models, (re)generate adapters
```sh
dart run build_runner build --delete-conflicting-outputs
```

## Builds (optional)

- Android APK
```sh
flutter build apk
```

- Windows desktop
```sh
flutter build windows
```

## License

