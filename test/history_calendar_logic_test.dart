import 'package:flutter_test/flutter_test.dart';
import 'package:offline_daily_tracker/src/models/activity.dart';
import 'package:offline_daily_tracker/src/ui/history/history_calendar_logic.dart';

void main() {
  group('buildDayMarkerPresentation', () {
    test('limits visible markers and computes overflow', () {
      final presentation = buildDayMarkerPresentation(6);
      expect(presentation.visibleCount, 4);
      expect(presentation.overflowCount, 2);
      expect(presentation.hasOverflow, isTrue);
    });

    test('shows all markers when below max', () {
      final presentation = buildDayMarkerPresentation(3);
      expect(presentation.visibleCount, 3);
      expect(presentation.overflowCount, 0);
      expect(presentation.hasOverflow, isFalse);
    });
  });

  group('isEditableHistoryDate', () {
    test('allows only today to today-6', () {
      final now = DateTime(2026, 3, 1);
      expect(isEditableHistoryDate(DateTime(2026, 3, 1), now: now), isTrue);
      expect(isEditableHistoryDate(DateTime(2026, 2, 23), now: now), isTrue);
      expect(isEditableHistoryDate(DateTime(2026, 2, 22), now: now), isFalse);
      expect(isEditableHistoryDate(DateTime(2026, 3, 2), now: now), isFalse);
    });
  });

  group('buildStreakHighlightKeys', () {
    Activity buildActivity(int id, int windowDays) {
      return Activity(
        id: id,
        name: 'A$id',
        type: ActivityType.yesNo,
        polarity: ActivityPolarity.doMore,
        windowDays: windowDays,
        targetSuccesses: 3,
        isPredefined: false,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        deletedAt: null,
      );
    }

    test('marks one full 7-day window for streak 1', () {
      final keys = buildStreakHighlightKeys(
        activities: [buildActivity(1, 7)],
        streaks: const {1: 1},
        now: DateTime(2026, 3, 1),
      );

      expect(keys.length, 7);
      expect(keys.contains('2026-03-01'), isTrue);
      expect(keys.contains('2026-02-23'), isTrue);
    });

    test('marks consecutive windows for multi-week streak', () {
      final keys = buildStreakHighlightKeys(
        activities: [buildActivity(1, 7)],
        streaks: const {1: 2},
        now: DateTime(2026, 3, 1),
      );

      expect(keys.length, 14);
      expect(keys.contains('2026-02-22'), isTrue);
      expect(keys.contains('2026-02-16'), isTrue);
    });
  });
}
