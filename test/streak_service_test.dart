import 'package:flutter_test/flutter_test.dart';
import 'package:offline_daily_tracker/src/models/activity.dart';
import 'package:offline_daily_tracker/src/services/streak_service.dart';

void main() {
  group('StreakService', () {
    final service = StreakService();

    Activity buildActivity({
      required ActivityPolarity polarity,
      required int windowDays,
      required int target,
    }) {
      return Activity(
        id: 1,
        name: 'Test',
        type: ActivityType.yesNo,
        polarity: polarity,
        windowDays: windowDays,
        targetSuccesses: target,
        isPredefined: false,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        deletedAt: null,
      );
    }

    test('do_more meets 5/7 and yields streak 1', () {
      final activity = buildActivity(
        polarity: ActivityPolarity.doMore,
        windowDays: 7,
        target: 5,
      );

      final streak = service.calculateCurrentWindowStreak(
        ['2026-02-22', '2026-02-21', '2026-02-20', '2026-02-19', '2026-02-18'],
        activity,
        now: DateTime(2026, 2, 22),
      );

      expect(streak, 1);
    });

    test('do_less 5/7 fails when event happens 3 days', () {
      final activity = buildActivity(
        polarity: ActivityPolarity.doLess,
        windowDays: 7,
        target: 5,
      );

      final summary = service.summarizeCurrentWindow(
        ['2026-02-22', '2026-02-21', '2026-02-20'],
        activity,
        now: DateTime(2026, 2, 22),
      );

      expect(summary.met, isFalse);
      expect(summary.doneDays, 3);
    });

    test('window streak counts consecutive successful windows', () {
      final activity = buildActivity(
        polarity: ActivityPolarity.doMore,
        windowDays: 7,
        target: 3,
      );

      final doneKeys = [
        '2026-02-22',
        '2026-02-21',
        '2026-02-20',
        '2026-02-15',
        '2026-02-14',
        '2026-02-13',
      ];

      final streak = service.calculateCurrentWindowStreak(
        doneKeys,
        activity,
        now: DateTime(2026, 2, 22),
      );

      expect(streak, 2);
    });

    test('do_less with no events does not hang and returns finite streak', () {
      final activity = buildActivity(
        polarity: ActivityPolarity.doLess,
        windowDays: 7,
        target: 5,
      );

      final streak = service.calculateCurrentWindowStreak(
        const [],
        activity,
        now: DateTime(2026, 2, 22),
      );

      expect(streak, greaterThanOrEqualTo(1));
      expect(streak, lessThan(20));
    });
  });
}
