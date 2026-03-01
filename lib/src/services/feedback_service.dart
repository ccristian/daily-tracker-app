import '../models/activity.dart';
import '../models/daily_entry.dart';

class FeedbackService {
  List<String> buildDayFeedback({
    required List<Activity> activities,
    required Map<int, DailyEntry> todayEntries,
    required Map<String, Map<int, DailyEntry>> recentEntries,
  }) {
    final insights = <String>[];

    final activityByName = {
      for (final activity in activities) activity.name.toLowerCase(): activity,
    };

    final sleptWell = _isDone(activityByName['quality sleep'], todayEntries);
    final walkDone = _isDone(activityByName['walk'], todayEntries);
    final workoutDone = _isDone(activityByName['workout'], todayEntries);
    final movementDone = walkDone || workoutDone;

    if (!sleptWell && !movementDone) {
      insights.add('Low recovery day. A light walk tomorrow can help reset momentum.');
    }

    if (sleptWell && movementDone) {
      insights.add('Good sleep and movement today. Keep repeating this pattern.');
    }

    final todayCompletionCount = todayEntries.values.where(_entryCompleted).length;
    if (todayCompletionCount >= 3) {
      insights.add('You completed $todayCompletionCount habits today. Consistency is building.');
    }

    final droppedStreak = _hasDroppedRecentHabit(activities, recentEntries, todayEntries);
    if (droppedStreak) {
      insights.add('A recent habit was missed today. Restart with one small action tomorrow.');
    }

    if (insights.isEmpty) {
      insights.add('Good job checking in today. Keep logging to unlock more trend feedback.');
    }

    return insights.take(4).toList();
  }

  bool _hasDroppedRecentHabit(
    List<Activity> activities,
    Map<String, Map<int, DailyEntry>> recentEntries,
    Map<int, DailyEntry> todayEntries,
  ) {
    final historical = recentEntries.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (historical.length < 2) {
      return false;
    }

    final previousDates = historical.take(historical.length - 1).map((e) => e.value);

    for (final activity in activities.where((item) => item.isActive)) {
      final hadAnyRecent = previousDates.any((map) {
        final entry = map[activity.id];
        return entry != null && _entryCompleted(entry);
      });
      if (!hadAnyRecent) {
        continue;
      }
      final todayEntry = todayEntries[activity.id];
      if (todayEntry == null || !_entryCompleted(todayEntry)) {
        return true;
      }
    }
    return false;
  }

  bool _isDone(Activity? activity, Map<int, DailyEntry> entries) {
    if (activity == null) {
      return false;
    }
    final entry = entries[activity.id];
    if (entry == null) {
      return false;
    }
    return _entryCompleted(entry);
  }

  bool _entryCompleted(DailyEntry entry) {
    return entry.binaryValue == true;
  }
}
