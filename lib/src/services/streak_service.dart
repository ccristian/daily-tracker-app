import '../data/date_key.dart';
import '../models/activity.dart';

class StreakService {
  int calculateCurrentWindowStreak(
    List<String> doneDateKeys,
    Activity activity, {
    DateTime? now,
  }) {
    final today = _normalize(now ?? DateTime.now());
    final done = doneDateKeys.toSet();
    final createdAt = _normalize(activity.createdAt);
    final maxWindows = ((today.difference(createdAt).inDays) ~/ activity.windowDays) + 1;

    var streak = 0;
    var windowEnd = today;

    for (var i = 0; i < maxWindows; i += 1) {
      final windowStart =
          windowEnd.subtract(Duration(days: activity.windowDays - 1));
      if (windowStart.isBefore(createdAt)) {
        break;
      }

      final summary = summarizeWindow(
        doneDateKeys: done,
        activity: activity,
        windowEnd: windowEnd,
      );

      if (!summary.met) {
        break;
      }

      streak += 1;
      windowEnd = windowEnd.subtract(Duration(days: activity.windowDays));
    }

    return streak;
  }

  ActivityWindowSummary summarizeCurrentWindow(
    List<String> doneDateKeys,
    Activity activity, {
    DateTime? now,
  }) {
    final today = _normalize(now ?? DateTime.now());
    return summarizeWindow(
      doneDateKeys: doneDateKeys.toSet(),
      activity: activity,
      windowEnd: today,
    );
  }

  ActivityWindowSummary summarizeWindow({
    required Set<String> doneDateKeys,
    required Activity activity,
    required DateTime windowEnd,
  }) {
    var doneDays = 0;
    for (var i = 0; i < activity.windowDays; i += 1) {
      final key = dateToKey(windowEnd.subtract(Duration(days: i)));
      if (doneDateKeys.contains(key)) {
        doneDays += 1;
      }
    }

    final met = activity.polarity == ActivityPolarity.doMore
        ? doneDays >= activity.targetSuccesses
        : doneDays <= activity.allowedFailures;

    return ActivityWindowSummary(doneDays: doneDays, met: met);
  }

  DateTime _normalize(DateTime input) => DateTime(input.year, input.month, input.day);
}
