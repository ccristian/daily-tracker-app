import 'package:flutter/material.dart';

import '../models/activity.dart';

IconData iconForCategory(String categoryKey) {
  switch (categoryKey) {
    case ActivityCategory.health:
      return Icons.favorite_outline;
    case ActivityCategory.fitness:
      return Icons.fitness_center;
    case ActivityCategory.mind:
      return Icons.self_improvement;
    case ActivityCategory.productivity:
      return Icons.bolt_outlined;
    case ActivityCategory.reduce:
      return Icons.remove_circle_outline;
    default:
      return Icons.category_outlined;
  }
}

IconData iconForActivity(Activity activity) {
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
      return iconForCategory(activity.categoryKey);
  }
}
