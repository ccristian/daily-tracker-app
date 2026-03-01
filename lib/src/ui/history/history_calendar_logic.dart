import '../../data/date_key.dart';
import '../../models/activity.dart';

class DayMarkerPresentation {
  const DayMarkerPresentation({
    required this.visibleCount,
    required this.overflowCount,
  });

  final int visibleCount;
  final int overflowCount;

  bool get hasOverflow => overflowCount > 0;
}

DayMarkerPresentation buildDayMarkerPresentation(
  int total, {
  int maxVisible = 4,
}) {
  if (total <= 0) {
    return const DayMarkerPresentation(visibleCount: 0, overflowCount: 0);
  }
  final visible = total > maxVisible ? maxVisible : total;
  final overflow = total > maxVisible ? total - maxVisible : 0;
  return DayMarkerPresentation(visibleCount: visible, overflowCount: overflow);
}

bool isEditableHistoryDate(
  DateTime day, {
  DateTime? now,
}) {
  final today = _normalize(now ?? DateTime.now());
  final normalized = _normalize(day);
  final minAllowed = today.subtract(const Duration(days: 6));
  if (normalized.isBefore(minAllowed)) {
    return false;
  }
  if (normalized.isAfter(today)) {
    return false;
  }
  return true;
}

Set<String> buildStreakHighlightKeys({
  required Iterable<Activity> activities,
  required Map<int, int> streaks,
  DateTime? now,
}) {
  final today = _normalize(now ?? DateTime.now());
  final output = <String>{};

  for (final activity in activities) {
    final streakLength = streaks[activity.id] ?? 0;
    if (streakLength <= 0) {
      continue;
    }

    for (var windowIndex = 0; windowIndex < streakLength; windowIndex += 1) {
      final windowEnd =
          today.subtract(Duration(days: activity.windowDays * windowIndex));
      for (var dayIndex = 0; dayIndex < activity.windowDays; dayIndex += 1) {
        final day = windowEnd.subtract(Duration(days: dayIndex));
        output.add(dateToKey(day));
      }
    }
  }

  return output;
}

DateTime _normalize(DateTime value) =>
    DateTime(value.year, value.month, value.day);
