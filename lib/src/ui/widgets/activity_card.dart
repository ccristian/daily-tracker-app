import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../models/daily_entry.dart';
import '../activity_visuals.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.entry,
    required this.streak,
    required this.windowSummary,
    required this.isEditable,
    required this.onChanged,
  });

  final Activity activity;
  final DailyEntry? entry;
  final int streak;
  final ActivityWindowSummary? windowSummary;
  final bool isEditable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = entry?.binaryValue ?? false;
    final doneDays = windowSummary?.doneDays ?? 0;
    final categoryColor = colorForCategory(activity.categoryKey);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: categoryColor.withValues(alpha: 0.14),
                  child: Icon(
                    iconForActivity(activity),
                    size: 18,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.categoryLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StreakBadge(streak: streak, windowDays: activity.windowDays),
              ],
            ),
            const SizedBox(height: 6),
            Text(activity.targetSummaryLabel, style: theme.textTheme.bodySmall),
            Text('This window: $doneDays/${activity.windowDays} days',
                style: theme.textTheme.bodySmall),
            if (activity.polarity == ActivityPolarity.doLess)
              Text(activity.trackingHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Row(
              children: [
                Switch(
                  value: value,
                  onChanged: isEditable ? onChanged : null,
                ),
                const SizedBox(width: 8),
                Text(value ? 'Yes' : 'No'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak, required this.windowDays});

  final int streak;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    final label = windowDays == 7 ? 'week streak' : '${windowDays}d streak';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('$streak $label'),
    );
  }
}
