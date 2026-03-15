# Bonora

iOS/Android Flutter app for offline habit tracking with customizable categories, per-activity history, weekly streak logic, and optional PIN lock.

## Features
- Local-only storage (SQLite), no cloud sync.
- Daily tracking with one check-in per activity.
- Yes/No activity toggle with `do more` and `do less` modes.
- Rolling weekly targets (`X/7`) and current window streaks.
- Predefined + custom activities.
- Custom category management with bundled icons for user-created categories.
- Per-activity calendar/history view from the activity card.
- Last 7 days editable history.
- Compact mobile-first activity cards for smaller devices.
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
   - `flutter analyze`
