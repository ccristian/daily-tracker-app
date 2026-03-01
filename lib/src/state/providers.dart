import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_repository.dart';
import '../data/daily_entry_repository.dart';
import '../data/database_helper.dart';
import '../data/settings_repository.dart';
import '../services/app_lock_service.dart';
import '../services/feedback_service.dart';
import '../services/reminder_service.dart';
import '../services/secure_store.dart';
import '../services/streak_service.dart';
import 'app_state_controller.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper());

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(databaseHelperProvider)),
);

final dailyEntryRepositoryProvider = Provider<DailyEntryRepository>(
  (ref) => DailyEntryRepository(ref.watch(databaseHelperProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseHelperProvider)),
);

final secureStoreProvider = Provider<SecureStore>((ref) => FlutterSecureStoreAdapter());

final streakServiceProvider = Provider<StreakService>((ref) => StreakService());

final feedbackServiceProvider = Provider<FeedbackService>((ref) => FeedbackService());

final reminderServiceProvider = Provider<ReminderService>((ref) => ReminderService());

final appLockServiceProvider = Provider<AppLockService>(
  (ref) => AppLockService(
    ref.watch(settingsRepositoryProvider),
    ref.watch(secureStoreProvider),
  ),
);

final appStateControllerProvider =
    StateNotifierProvider<AppStateController, AsyncValue<AppViewState>>(
  (ref) => AppStateController(
    activityRepository: ref.watch(activityRepositoryProvider),
    dailyEntryRepository: ref.watch(dailyEntryRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    streakService: ref.watch(streakServiceProvider),
    feedbackService: ref.watch(feedbackServiceProvider),
    reminderService: ref.watch(reminderServiceProvider),
    appLockService: ref.watch(appLockServiceProvider),
  )..load(),
);

final lockStateProvider = StateNotifierProvider<LockStateController, LockState>(
  (ref) => LockStateController(ref.watch(appLockServiceProvider))..initialize(),
);
