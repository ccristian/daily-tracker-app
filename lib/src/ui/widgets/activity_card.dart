import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../models/daily_entry.dart';
import '../activity_visuals.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.categories,
    this.onOpenHistory,
    required this.entry,
    required this.streak,
    required this.windowSummary,
    required this.isEditable,
    required this.onChanged,
  });

  final Activity activity;
  final List<ActivityCategoryDefinition> categories;
  final VoidCallback? onOpenHistory;
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
    final categoryColor = colorForCategory(
      activity.categoryKey,
      categories: categories,
    );

    final goalLabel = activity.polarity == ActivityPolarity.doMore
        ? 'Goal ${activity.targetSuccesses}/${activity.windowDays}'
        : 'Limit ${activity.allowedFailures}/${activity.windowDays} yes';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onOpenHistory,
            onLongPress: onOpenHistory,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (compact) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: categoryColor.withValues(alpha: 0.14),
                        child: Icon(
                          iconForActivity(activity, categories: categories),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity.categoryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _StreakBadge(streak: streak, windowDays: activity.windowDays),
                ] else
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: categoryColor.withValues(alpha: 0.14),
                        child: Icon(
                          iconForActivity(activity, categories: categories),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity.categoryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StreakBadge(
                        streak: streak,
                        windowDays: activity.windowDays,
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoChip(label: goalLabel),
                    _InfoChip(
                      label: 'Window $doneDays/${activity.windowDays}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: value,
                        onChanged: isEditable ? onChanged : null,
                      ),
                      const SizedBox(width: 6),
                      Text(value ? 'Yes' : 'No'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak, required this.windowDays});

  final int streak;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    final label = windowDays == 7 ? '$streak wk' : '$streak x ${windowDays}d';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
