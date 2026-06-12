# Focus Mate

Anti-drowsiness focus timer. You set an interval; at the end of each interval
an alert fires and a math problem blocks the screen. You cannot dismiss the
alert without solving it — so even if you start dozing off, the app forces
periodic cognitive engagement.

## Stack

- **Flutter 3.44+ / Dart 3.12+** — single codebase for iOS and Android with
  native-level performance.
- **flutter_local_notifications** — reliable OS-scheduled notifications that
  fire even when the app is killed. Uses exact alarms on Android and
  `UNCalendarNotificationTrigger` on iOS.
- **shared_preferences** — persistent settings (interval, difficulty, sound,
  vibration, focus-mode state) that survive app restarts and reboots.
- **wakelock_plus** — keeps the screen alive during the math challenge so the
  user can't dismiss by waiting for screen-off.
- **provider** — lightweight state management.

## Project layout

```
lib/
├── main.dart                          # App entry, provider wiring, launch routing
├── core/
│   └── math_problem.dart              # MathProblem + MathProblemGenerator
├── services/
│   ├── notification_service.dart      # flutter_local_notifications wrapper
│   └── settings_repository.dart       # AppSettings + SharedPreferences
├── providers/
│   └── focus_provider.dart            # State machine: idle/running/challenge
└── screens/
    ├── home_screen.dart               # Idle + running home UI
    ├── challenge_screen.dart          # Full-screen math challenge (locked)
    └── settings_screen.dart           # Interval, difficulty, sound/vibration
```

## How the anti-bypass works

1. The notification uses `fullScreenIntent: true` (Android) and
   `interruptionLevel: timeSensitive` (iOS), so it pops up over the lock
   screen if needed.
2. The challenge screen wraps the entire UI in `PopScope(canPop: false)` —
   the system back button and predictive-back gesture do nothing.
3. The submit handler regenerates a *new* problem on a wrong answer — you
   can't blindly tap the same guess twice.
4. `WakelockPlus.enable()` keeps the screen on while the challenge is active,
   so the user can't wait the device out.
5. The notification channel is `ongoing: true` + `autoCancel: false`, so it
   stays pinned until the challenge is solved.

## Permissions

| Platform | Permission                              | Why                                     |
|----------|-----------------------------------------|-----------------------------------------|
| Android  | `POST_NOTIFICATIONS`                    | Show the focus alert                    |
| Android  | `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Trigger alerts at the exact interval |
| Android  | `WAKE_LOCK`                             | Wake device for the alert               |
| Android  | `USE_FULL_SCREEN_INTENT`                | Show over lock screen                   |
| Android  | `RECEIVE_BOOT_COMPLETED`                | Re-arm scheduled alerts after reboot    |
| Android  | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`  | Keep timers reliable on aggressive OEMs |
| iOS      | Notification permission                 | First-launch prompt                     |

## Build & run

```bash
# Get dependencies
flutter pub get

# Run on a connected device / emulator
flutter run

# Build a release APK
flutter build apk --release

# Build a release iOS bundle (macOS only, requires Xcode)
flutter build ios --release
```

## Tests

```bash
flutter test
```

## Settings persistence

All user settings are stored in `SharedPreferences`:

- `interval_minutes` (int, default 60)
- `difficulty_tier` (int 1..5, default 3)
- `focus_mode_enabled` (bool, default false)
- `sound_enabled` (bool, default true)
- `vibration_enabled` (bool, default true)

These persist across app restarts, app updates, and device reboots (the
scheduled notifications re-arm via the boot receiver on Android).

## Math problem difficulty

| Tier | Label    | Examples                                        |
|------|----------|-------------------------------------------------|
| 1    | Easy     | 7×8, 24÷6, 13+27                                |
| 2    | Normal   | 11×12, 84÷7, 145−89                             |
| 3    | Moderate | 23×14, 168÷12, 287+453                          |
| 4    | Hard     | 67×24, 528÷22, 1024−789                         |
| 5    | Brutal   | 312×86, 4096÷64, 5000−3271                      |

The generator rotates through all four operators (+, −, ×, ÷) and division
is always whole-number by construction (divisor × result is generated first,
then divided).

## What's NOT done (future work)

- Statistics: daily/weekly focus minutes, problems solved, attempts per problem
- Multiple "challenge sets" (sequence of N problems instead of one)
- Localized strings (currently English-only)
- iOS Critical Alert entitlement (requires Apple approval) for sound during Do
  Not Disturb
