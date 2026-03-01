import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_daily_tracker/src/ui/history/activity_color_resolver.dart';

void main() {
  group('resolveActivityColor', () {
    test('returns stable color for same id', () {
      final a = resolveActivityColor(7);
      final b = resolveActivityColor(7);
      expect(a, equals(b));
    });

    test('wraps predictably across palette length', () {
      final first = resolveActivityColor(1);
      final wrapped = resolveActivityColor(11);
      expect(wrapped, equals(first));
    });

    test('returns a concrete color', () {
      final color = resolveActivityColor(3);
      expect(color, isA<Color>());
    });
  });
}
