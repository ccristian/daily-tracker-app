import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_repository.dart';
import '../data/daily_entry_repository.dart';
import '../data/date_key.dart';
import '../data/settings_repository.dart';
import '../models/activity.dart';
import '../models/daily_entry.dart';
import '../models/settings.dart';
import '../services/app_lock_service.dart';
import '../services/feedback_service.dart';
import '../services/reminder_service.dart';
import '../services/streak_service.dart';

class AppViewState {
  const AppViewState({
    required this.selectedDate,
    required this.activities,
    required this.categories,
    required this.entriesByActivity,
    required this.streaks,
    required this.windowSummaries,
    required this.settings,
    required this.feedback,
  });

  final DateTime selectedDate;
  final List<Activity> activities;
  final List<ActivityCategoryDefinition> categories;
  final Map<int, DailyEntry> entriesByActivity;
  final Map<int, int> streaks;
  final Map<int, ActivityWindowSummary> windowSummaries;
  final AppSettings settings;
  final List<String> feedback;

  AppViewState copyWith({
    DateTime? selectedDate,
    List<Activity>? activities,
    List<ActivityCategoryDefinition>? categories,
    Map<int, DailyEntry>? entriesByActivity,
    Map<int, int>? streaks,
    Map<int, ActivityWindowSummary>? windowSummaries,
    AppSettings? settings,
    List<String>? feedback,
  }) {
    return AppViewState(
      selectedDate: selectedDate ?? this.selectedDate,
      activities: activities ?? this.activities,
      categories: categories ?? this.categories,
      entriesByActivity: entriesByActivity ?? this.entriesByActivity,
      streaks: streaks ?? this.streaks,
      windowSummaries: windowSummaries ?? this.windowSummaries,
      settings: settings ?? this.settings,
      feedback: feedback ?? this.feedback,
    );
  }
}

class AppStateController extends StateNotifier<AsyncValue<AppViewState>> {
  AppStateController({
    required ActivityRepository activityRepository,
    required DailyEntryRepository dailyEntryRepository,
    required SettingsRepository settingsRepository,
    required StreakService streakService,
    required FeedbackService feedbackService,
    required ReminderService reminderService,
    required AppLockService appLockService,
  })  : _activityRepository = activityRepository,
        _dailyEntryRepository = dailyEntryRepository,
        _settingsRepository = settingsRepository,
        _streakService = streakService,
        _feedbackService = feedbackService,
        _reminderService = reminderService,
        _appLockService = appLockService,
        super(const AsyncValue.loading());

  final ActivityRepository _activityRepository;
  final DailyEntryRepository _dailyEntryRepository;
  final SettingsRepository _settingsRepository;
  final StreakService _streakService;
  final FeedbackService _feedbackService;
  final ReminderService _reminderService;
  final AppLockService _appLockService;

  Future<void> load({DateTime? selectedDate}) async {
    state = const AsyncValue.loading();
    try {
      final date = selectedDate ?? DateTime.now();
      final settings = await _appLockService.getSettings();
      await _reminderService.applyReminder(settings.reminderSettings);

      final activities =
          await _activityRepository.getAllActivities(includeInactive: true);
      final entries = await _dailyEntryRepository.getEntriesByDate(date);
      final streakData = await _buildStreakData(activities);

      state = AsyncValue.data(
        AppViewState(
          selectedDate: DateTime(date.year, date.month, date.day),
          activities: activities,
          categories: settings.categories,
          entriesByActivity: entries,
          streaks: streakData.streaks,
          windowSummaries: streakData.windowSummaries,
          settings: settings,
          feedback: const [],
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> selectDate(DateTime date) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final normalized = DateTime(date.year, date.month, date.day);
    final minAllowed = DateTime.now().subtract(const Duration(days: 6));
    if (normalized.isBefore(
        DateTime(minAllowed.year, minAllowed.month, minAllowed.day))) {
      return;
    }

    final entries = await _dailyEntryRepository.getEntriesByDate(normalized);
    state = AsyncValue.data(
      current.copyWith(
        selectedDate: normalized,
        entriesByActivity: entries,
        feedback: const [],
      ),
    );
  }

  Future<void> setBinary(Activity activity, bool value) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    await _dailyEntryRepository.upsertEntry(
      activity: activity,
      date: current.selectedDate,
      binaryValue: value,
    );

    await _refreshEntriesAndStreaks();
  }

  Future<void> addCustomActivity({
    required String name,
    required ActivityPolarity polarity,
    required int windowDays,
    required int targetSuccesses,
    required String categoryKey,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Activity name cannot be empty');
    }

    if (!_isValidWindow(windowDays, targetSuccesses)) {
      throw ArgumentError('Invalid target for selected window');
    }

    if (await _activityRepository.existsByName(trimmed)) {
      throw ArgumentError('Activity already exists');
    }

    await _activityRepository.addCustomActivity(
      name: trimmed,
      polarity: polarity,
      windowDays: windowDays,
      targetSuccesses: targetSuccesses,
      categoryKey: categoryKey,
    );
    await _reloadActivities();
  }

  Future<void> updateActivityConfig({
    required Activity activity,
    required String name,
    required ActivityPolarity polarity,
    required int windowDays,
    required int targetSuccesses,
    required bool isActive,
    required String categoryKey,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Activity name cannot be empty');
    }

    if (!_isValidWindow(windowDays, targetSuccesses)) {
      throw ArgumentError('Invalid target for selected window');
    }

    if (await _activityRepository.existsByName(trimmed,
        excludeId: activity.id)) {
      throw ArgumentError('Activity name already exists');
    }

    await _activityRepository.updateActivityConfig(
      activityId: activity.id,
      name: trimmed,
      polarity: polarity,
      windowDays: windowDays,
      targetSuccesses: targetSuccesses,
      isActive: isActive,
      categoryKey: categoryKey,
    );
    await _reloadActivities();
  }

  Future<void> setActivityActive(int activityId, bool isActive) async {
    await _activityRepository.setActive(activityId, isActive);
    await _reloadActivities();
  }

  Future<void> deleteActivity(int activityId) async {
    await _activityRepository.softDelete(activityId);
    await _reloadActivities();
  }

  Future<void> updateReminder(ReminderSettings reminderSettings) async {
    await _settingsRepository.updateReminder(reminderSettings);
    await _reminderService.applyReminder(reminderSettings);

    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          settings:
              current.settings.copyWith(reminderSettings: reminderSettings),
        ),
      );
    }
  }

  Future<void> generateFeedback() async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final recent = await _dailyEntryRepository.getEntriesForLastDays(7);
    final feedback = _feedbackService.buildDayFeedback(
      activities: current.activities.where((item) => item.isActive).toList(),
      todayEntries: current.entriesByActivity,
      recentEntries: recent,
    );

    state = AsyncValue.data(current.copyWith(feedback: feedback));
  }

  Future<void> refreshSettings() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final settings = await _appLockService.getSettings();
    state = AsyncValue.data(
      current.copyWith(
        settings: settings,
        categories: settings.categories,
      ),
    );
  }

  Future<void> addCategory(String name) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final duplicate = current.categories.any(
      (category) => category.label.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      throw ArgumentError('Category already exists');
    }

    final key = ActivityCategory.buildKey(
      trimmed,
      existingKeys: current.categories.map((category) => category.key),
    );
    final categories = [
      ...current.categories,
      ActivityCategoryDefinition(
        key: key,
        label: trimmed,
        iconKey: ActivityCategory.nextCustomIconKey(current.categories),
      ),
    ];
    await _updateCategories(categories);
  }

  Future<void> renameCategory({
    required String categoryKey,
    required String name,
  }) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final duplicate = current.categories.any(
      (category) =>
          category.key != categoryKey &&
          category.label.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      throw ArgumentError('Category already exists');
    }

    final categories = current.categories
        .map(
          (category) => category.key == categoryKey
              ? category.copyWith(label: trimmed)
              : category,
        )
        .toList();
    await _updateCategories(categories);
  }

  Future<void> deleteCategory(String categoryKey) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    if (current.categories.length <= 1) {
      throw ArgumentError('At least one category is required');
    }

    final fallback = current.categories.firstWhere(
      (category) => category.key != categoryKey,
      orElse: () => current.categories.first,
    );
    await _activityRepository.replaceCategoryKey(
      fromCategoryKey: categoryKey,
      toCategoryKey: fallback.key,
    );
    final categories = current.categories
        .where((category) => category.key != categoryKey)
        .toList();
    await _updateCategories(categories, reloadActivities: true);
  }

  Future<_StreakData> _buildStreakData(List<Activity> activities) async {
    final streaks = <int, int>{};
    final summaries = <int, ActivityWindowSummary>{};

    for (final activity in activities.where((item) => item.isActive)) {
      final keys = await _dailyEntryRepository
          .getCompletionDateKeysForActivity(activity.id);
      streaks[activity.id] =
          _streakService.calculateCurrentWindowStreak(keys, activity);
      summaries[activity.id] =
          _streakService.summarizeCurrentWindow(keys, activity);
    }

    return _StreakData(streaks: streaks, windowSummaries: summaries);
  }

  Future<void> _refreshEntriesAndStreaks() async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final entries =
        await _dailyEntryRepository.getEntriesByDate(current.selectedDate);
    final streakData = await _buildStreakData(current.activities);
    state = AsyncValue.data(
      current.copyWith(
        entriesByActivity: entries,
        streaks: streakData.streaks,
        windowSummaries: streakData.windowSummaries,
      ),
    );
  }

  Future<void> _reloadActivities() async {
    final current = state.value;
    if (current == null) {
      return;
    }
    final activities =
        await _activityRepository.getAllActivities(includeInactive: true);
    final streakData = await _buildStreakData(activities);
    final entries =
        await _dailyEntryRepository.getEntriesByDate(current.selectedDate);
    state = AsyncValue.data(
      current.copyWith(
        activities: activities,
        categories: current.categories,
        streaks: streakData.streaks,
        windowSummaries: streakData.windowSummaries,
        entriesByActivity: entries,
      ),
    );
  }

  bool _isValidWindow(int windowDays, int targetSuccesses) {
    if (windowDays != 7) {
      return false;
    }
    return targetSuccesses >= 1 && targetSuccesses <= windowDays;
  }

  Future<void> _updateCategories(
    List<ActivityCategoryDefinition> categories, {
    bool reloadActivities = false,
  }) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final sanitized = ActivityCategory.sanitizeDefinitions(categories);
    await _settingsRepository.updateCategories(sanitized);
    final settings = current.settings.copyWith(categories: sanitized);

    if (reloadActivities) {
      final activities =
          await _activityRepository.getAllActivities(includeInactive: true);
      final streakData = await _buildStreakData(activities);
      final entries =
          await _dailyEntryRepository.getEntriesByDate(current.selectedDate);
      state = AsyncValue.data(
        current.copyWith(
          settings: settings,
          categories: sanitized,
          activities: activities,
          streaks: streakData.streaks,
          windowSummaries: streakData.windowSummaries,
          entriesByActivity: entries,
        ),
      );
      return;
    }

    state = AsyncValue.data(
      current.copyWith(
        settings: settings,
        categories: sanitized,
      ),
    );
  }
}

class _StreakData {
  const _StreakData({
    required this.streaks,
    required this.windowSummaries,
  });

  final Map<int, int> streaks;
  final Map<int, ActivityWindowSummary> windowSummaries;
}

class LockState {
  const LockState({
    required this.initialized,
    required this.pinEnabled,
    required this.locked,
  });

  final bool initialized;
  final bool pinEnabled;
  final bool locked;

  LockState copyWith({
    bool? initialized,
    bool? pinEnabled,
    bool? locked,
  }) {
    return LockState(
      initialized: initialized ?? this.initialized,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      locked: locked ?? this.locked,
    );
  }

  static const initial =
      LockState(initialized: false, pinEnabled: false, locked: false);
}

class LockStateController extends StateNotifier<LockState> {
  LockStateController(this._appLockService) : super(LockState.initial);

  final AppLockService _appLockService;

  Future<void> initialize() async {
    final enabled = await _appLockService.isPinEnabled();
    state = LockState(initialized: true, pinEnabled: enabled, locked: enabled);
  }

  Future<void> refresh() async {
    final enabled = await _appLockService.isPinEnabled();
    state = state.copyWith(
        pinEnabled: enabled, locked: enabled ? state.locked : false);
  }

  Future<void> onAppResumed() async {
    final shouldLock = await _appLockService.shouldLockOnResume();
    if (shouldLock) {
      state = state.copyWith(locked: true, pinEnabled: true);
    }
  }

  void unlock() {
    state = state.copyWith(locked: false);
  }

  void lockNow() {
    if (state.pinEnabled) {
      state = state.copyWith(locked: true);
    }
  }
}

bool isDateEditable(DateTime date) {
  final now = DateTime.now();
  final normalized = DateTime(date.year, date.month, date.day);
  final min =
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  return !normalized.isBefore(min) &&
      !normalized.isAfter(DateTime(now.year, now.month, now.day));
}

String formatDateLabel(DateTime date) {
  final now = DateTime.now();
  final todayKey = dateToKey(now);
  final inputKey = dateToKey(date);
  if (todayKey == inputKey) {
    return 'Today';
  }
  final yesterdayKey = dateToKey(now.subtract(const Duration(days: 1)));
  if (yesterdayKey == inputKey) {
    return 'Yesterday';
  }
  return inputKey;
}
