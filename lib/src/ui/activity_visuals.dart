import 'package:flutter/material.dart';

import '../models/activity.dart';

const _customCategoryColors = <Color>[
  Color(0xFF0F766E),
  Color(0xFF7C3AED),
  Color(0xFFDC2626),
  Color(0xFF2563EB),
  Color(0xFFEA580C),
  Color(0xFFBE185D),
  Color(0xFF0891B2),
  Color(0xFF65A30D),
  Color(0xFF9333EA),
  Color(0xFFB45309),
];

Color colorForCategory(
  String categoryKey, {
  List<ActivityCategoryDefinition>? categories,
}) {
  switch (categoryKey) {
    case ActivityCategory.health:
      return const Color(0xFF2E8B57);
    case ActivityCategory.fitness:
      return const Color(0xFF1D7CF2);
    case ActivityCategory.mind:
      return const Color(0xFF8A5CF6);
    case ActivityCategory.productivity:
      return const Color(0xFFF59E0B);
    case ActivityCategory.reduce:
      return const Color(0xFFE35D6A);
    default:
      return _customCategoryColors[_stableCategoryIndex(
        categoryKey,
        _customCategoryColors.length,
      )];
  }
}

IconData iconForCategory(
  String categoryKey, {
  List<ActivityCategoryDefinition>? categories,
}) {
  final category = categories == null
      ? null
      : ActivityCategory.definitionFor(categoryKey, categories);
  final iconKey = category?.iconKey ??
      ActivityCategory.definitionFor(
        categoryKey,
        ActivityCategory.defaultDefinitions,
      )?.iconKey;
  return _iconForKey(iconKey);
}

IconData iconForActivity(
  Activity activity, {
  List<ActivityCategoryDefinition>? categories,
}) {
  switch (activity.iconKey) {
    case 'water_drop':
      return Icons.water_drop_outlined;
    case 'bedtime':
      return Icons.bedtime_outlined;
    case 'restaurant':
      return Icons.restaurant_outlined;
    case 'stretch':
      return Icons.accessibility_new_outlined;
    case 'pill':
      return Icons.medication_outlined;
    case 'walk':
      return Icons.directions_walk_outlined;
    case 'workout':
      return Icons.fitness_center;
    case 'run':
      return Icons.directions_run_outlined;
    case 'cycle':
      return Icons.pedal_bike_outlined;
    case 'yoga':
      return Icons.sports_gymnastics_outlined;
    case 'meditate':
      return Icons.self_improvement;
    case 'journal':
      return Icons.edit_note_outlined;
    case 'gratitude':
      return Icons.volunteer_activism_outlined;
    case 'breathing':
      return Icons.air_outlined;
    case 'therapy':
      return Icons.psychology_outlined;
    case 'reading':
      return Icons.menu_book_outlined;
    case 'study':
      return Icons.school_outlined;
    case 'deep_work':
      return Icons.center_focus_strong_outlined;
    case 'plan':
      return Icons.event_note_outlined;
    case 'sunrise':
      return Icons.wb_sunny_outlined;
    case 'alcohol':
      return Icons.no_drinks_outlined;
    case 'sugar':
      return Icons.icecream_outlined;
    case 'social':
      return Icons.phonelink_ring_outlined;
    case 'junk_food':
      return Icons.fastfood_outlined;
    case 'smoking':
      return Icons.smoke_free_outlined;
    default:
      return iconForCategory(
        activity.categoryKey,
        categories: categories,
      );
  }
}

IconData _iconForKey(String? iconKey) {
  switch (iconKey) {
    case 'favorite_outline':
      return Icons.favorite_outline;
    case 'fitness_center':
      return Icons.fitness_center;
    case 'self_improvement':
      return Icons.self_improvement;
    case 'bolt_outlined':
      return Icons.bolt_outlined;
    case 'remove_circle_outline':
      return Icons.remove_circle_outline;
    case 'pets':
      return Icons.pets_outlined;
    case 'music_note':
      return Icons.music_note_outlined;
    case 'palette':
      return Icons.palette_outlined;
    case 'travel':
      return Icons.travel_explore_outlined;
    case 'laptop':
      return Icons.laptop_mac_outlined;
    case 'spa':
      return Icons.spa_outlined;
    case 'park':
      return Icons.park_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'savings':
      return Icons.savings_outlined;
    case 'sparkles':
      return Icons.auto_awesome_outlined;
    case 'camera':
      return Icons.camera_alt_outlined;
    case 'sports':
      return Icons.sports_basketball_outlined;
    case 'code':
      return Icons.code_outlined;
    case 'book':
      return Icons.menu_book_outlined;
    case 'movie':
      return Icons.movie_outlined;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'car':
      return Icons.directions_car_outlined;
    case 'flight':
      return Icons.flight_takeoff_outlined;
    case 'gamepad':
      return Icons.sports_esports_outlined;
    case 'restaurant':
      return Icons.restaurant_outlined;
    default:
      return Icons.category_outlined;
  }
}

int _stableCategoryIndex(String value, int modulo) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return modulo == 0 ? 0 : hash % modulo;
}
