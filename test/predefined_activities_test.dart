import 'package:flutter_test/flutter_test.dart';
import 'package:offline_daily_tracker/src/data/predefined_activities.dart';

void main() {
  group('predefined activity identity', () {
    test('all predefined system keys are unique', () {
      final keys =
          predefinedActivitySpecs.map((spec) => spec.systemKey).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('starter default active set stays stable', () {
      final activeKeys = predefinedActivitySpecs
          .where((spec) => spec.isActiveByDefault)
          .map((spec) => spec.systemKey)
          .toSet();

      expect(activeKeys, {
        'hydration',
        'eat_healthy',
        'walk',
        'workout',
        'meditation',
        'reading',
      });
    });

    test('legacy names resolve to canonical system keys', () {
      expect(
          resolvePredefinedSystemKeyFromName('Quality Sleep'), 'sleep_on_time');
      expect(resolvePredefinedSystemKeyFromName('Eat Healthy'), 'eat_healthy');
      expect(
        resolvePredefinedSystemKeyFromName('Alcohol (Do Less)'),
        'alcohol',
      );
      expect(
        resolvePredefinedSystemKeyFromName('Stretching/Mobility'),
        'stretch',
      );
    });

    test('system key lookup returns the canonical spec', () {
      final spec = predefinedSpecBySystemKey('workout');
      expect(spec, isNotNull);
      expect(spec!.name, 'Workout');
      expect(spec.categoryKey, 'fitness');
    });
  });
}
