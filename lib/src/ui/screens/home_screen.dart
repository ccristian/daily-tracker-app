import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/activity.dart';
import '../../state/app_state_controller.dart';
import '../../state/providers.dart';
import '../activity_visuals.dart';
import '../widgets/activity_card.dart';
import 'activity_history_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateControllerProvider);

    return appState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (state) {
        final categoryOrder = {
          for (var i = 0; i < state.categories.length; i++)
            state.categories[i].key: i,
        };
        final active = state.activities.where((item) => item.isActive).toList()
          ..sort((a, b) {
            final categoryCompare = (categoryOrder[a.categoryKey] ?? 9999)
                .compareTo(categoryOrder[b.categoryKey] ?? 9999);
            if (categoryCompare != 0) {
              return categoryCompare;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
        final isEditable = isDateEditable(state.selectedDate);
        final grouped = <String, List<Activity>>{};
        for (final activity in active) {
          grouped
              .putIfAbsent(activity.categoryKey, () => <Activity>[])
              .add(activity);
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(appStateControllerProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                'Date: ${formatDateLabel(state.selectedDate)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!isEditable)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                      'This date is read-only (outside 7-day edit window).'),
                ),
              const SizedBox(height: 12),
              ...state.categories
                  .map((category) => category.key)
                  .where(grouped.containsKey)
                  .expand((categoryKey) {
                final categoryActivities = grouped[categoryKey]!;
                return [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          iconForCategory(
                            categoryKey,
                            categories: state.categories,
                          ),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ActivityCategory.labelFor(categoryKey, state.categories),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  ...categoryActivities.map((activity) {
                    final entry = state.entriesByActivity[activity.id];
                    final streak = state.streaks[activity.id] ?? 0;
                    final summary = state.windowSummaries[activity.id];

                    return ActivityCard(
                      key: ValueKey<int>(activity.id),
                      activity: activity,
                      categories: state.categories,
                      onOpenHistory: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => ActivityHistoryScreen(
                              activityId: activity.id,
                            ),
                          ),
                        );
                      },
                      entry: entry,
                      streak: streak,
                      windowSummary: summary,
                      isEditable: isEditable,
                      onChanged: (value) {
                        ref
                            .read(appStateControllerProvider.notifier)
                            .setBinary(activity, value);
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                ];
              }),
              const SizedBox(height: 8),
              Text(
                'Daily insights use local rules based on today and recent check-ins.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (state.entriesByActivity.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Log at least one activity for this date to generate insights.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: state.entriesByActivity.isEmpty
                    ? null
                    : () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generating insights...'),
                            duration: Duration(milliseconds: 700),
                          ),
                        );
                        await ref
                            .read(appStateControllerProvider.notifier)
                            .generateFeedback();
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Insights updated below.')),
                        );
                      },
                icon: const Icon(Icons.tips_and_updates),
                label: const Text('Generate Insights'),
              ),
              if (state.feedback.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Insights',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...state.feedback.map((line) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('• $line'),
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
