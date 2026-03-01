import 'package:flutter/material.dart';

const _activityPalette = <Color>[
  Color(0xFF0EA5E9),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF6366F1),
  Color(0xFF14B8A6),
  Color(0xFFF97316),
  Color(0xFF22C55E),
  Color(0xFFEC4899),
  Color(0xFF3B82F6),
];

Color resolveActivityColor(int activityId) {
  final safeId = activityId.abs();
  final index = safeId % _activityPalette.length;
  return _activityPalette[index];
}
