import 'package:flutter_test/flutter_test.dart';
import 'package:offline_daily_tracker/src/models/activity.dart';
import 'package:offline_daily_tracker/src/models/daily_entry.dart';
import 'package:offline_daily_tracker/src/services/feedback_service.dart';

void main() {
  group('FeedbackService', () {
    final service = FeedbackService();

    final sleep = Activity(
      id: 1,
      name: 'Quality Sleep',
      type: ActivityType.yesNo,
      polarity: ActivityPolarity.doMore,
      windowDays: 7,
      targetSuccesses: 6,
      isPredefined: true,
      isActive: true,
      createdAt: DateTime(2026, 2, 20),
      deletedAt: null,
    );
    final walk = Activity(
      id: 2,
      name: 'Walk',
      type: ActivityType.yesNo,
      polarity: ActivityPolarity.doMore,
      windowDays: 7,
      targetSuccesses: 5,
      isPredefined: true,
      isActive: true,
      createdAt: DateTime(2026, 2, 20),
      deletedAt: null,
    );

    test('suggests recovery when sleep is poor and no movement', () {
      final todayEntries = {
        1: DailyEntry(
          id: 1,
          activityId: 1,
          dateKey: '2026-02-22',
          binaryValue: false,
          scaleValue: null,
          updatedAt: DateTime(2026, 2, 22),
        ),
      };

      final insights = service.buildDayFeedback(
        activities: [sleep, walk],
        todayEntries: todayEntries,
        recentEntries: const {},
      );

      expect(
        insights.any((line) => line.toLowerCase().contains('light walk')),
        isTrue,
      );
    });
  });
}
