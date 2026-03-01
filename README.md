# Daily Tracker

iOS/Android Flutter app for daily yes/no activity tracking with configurable weekly targets and optional PIN lock.

## Features
- Local-only storage (SQLite), no cloud sync.
- Daily tracking with one check-in per activity.
- Activity type:
  - Yes/No toggle
- Per-activity configuration:
  - Build habit (`do more`) or limit habit (`do less`)
  - Target in rolling week (`X/7`)
- Predefined + custom activities.
- Per-activity current window streaks.
- Last 7 days editable history.
- Optional local daily reminder.
- Optional 4-digit PIN lock on app reopen.
- Rule-based local day feedback.

## Predefined activities
- Stretching/Mobility (3/7, do more)
- Workout (3/7, do more)
- Meditation (3/7, do more)
- Hydration (3/7, do more)
- Walk (3/7, do more)
- Eating Healthy (3/7, do more)

## PIN lock behavior
- Disabled by default.
- 4-digit PIN only.
- App locks on reopen/resume when enabled.
- No cloud recovery. If PIN is forgotten, reinstall is required to reset app lock.

## Run
1. Install Flutter SDK.
2. From this folder:
   - `flutter pub get`
   - `flutter run`
3. Tests:
   - `flutter test`
