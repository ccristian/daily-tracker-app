import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/activity.dart';
import '../../state/providers.dart';
import '../activity_visuals.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  final _nameController = TextEditingController();
  ActivityPolarity _newPolarity = ActivityPolarity.doMore;
  String _newCategoryKey = ActivityCategory.health;
  int _newTargetSuccesses = 5;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addActivity() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity name is required')),
      );
      return;
    }

    try {
      await ref.read(appStateControllerProvider.notifier).addCustomActivity(
            name: name,
            polarity: _newPolarity,
            windowDays: 7,
            targetSuccesses: _newTargetSuccesses,
            categoryKey: _newCategoryKey,
          );
      _nameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity added')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _editActivity(Activity activity) async {
    final nameController = TextEditingController(text: activity.name);
    var polarity = activity.polarity;
    var categoryKey = activity.categoryKey;
    const windowDays = 7;
    var target = activity.targetSuccesses;
    var isActive = activity.isActive;

    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Activity'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ActivityPolarity>(
                      initialValue: polarity,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                          value: ActivityPolarity.doMore,
                          child: Text('Build habit (do more)'),
                        ),
                        DropdownMenuItem(
                          value: ActivityPolarity.doLess,
                          child: Text('Limit habit (do less)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          polarity = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categoryKey,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categoryMenuItems(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          categoryKey = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Window: 7 days'),
                    const SizedBox(height: 12),
                    Text(
                      Activity.buildTargetLabel(
                        polarity: polarity,
                        targetSuccesses: target,
                        windowDays: windowDays,
                      ),
                    ),
                    Slider(
                      min: 1,
                      max: 7,
                      divisions: 6,
                      value: target.toDouble(),
                      onChanged: (value) {
                        setState(() {
                          target = value.round();
                        });
                      },
                    ),
                    SwitchListTile(
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      onChanged: (value) {
                        setState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (didSave != true) {
      return;
    }

    try {
      await ref.read(appStateControllerProvider.notifier).updateActivityConfig(
            activity: activity,
            name: nameController.text.trim(),
            polarity: polarity,
            windowDays: windowDays,
            targetSuccesses: target,
            isActive: isActive,
            categoryKey: categoryKey,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity updated')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text(
          'Delete "${activity.name}"? History is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref
        .read(appStateControllerProvider.notifier)
        .deleteActivity(activity.id);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateControllerProvider);

    return appState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (state) {
        final grouped = <String, List<Activity>>{};
        for (final activity in state.activities) {
          grouped
              .putIfAbsent(activity.categoryKey, () => <Activity>[])
              .add(activity);
        }
        for (final entry in grouped.entries) {
          entry.value.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              'Add Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Activity name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ActivityPolarity>(
              initialValue: _newPolarity,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: ActivityPolarity.doMore,
                  child: Text('Build habit (do more)'),
                ),
                DropdownMenuItem(
                  value: ActivityPolarity.doLess,
                  child: Text('Limit habit (do less)'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _newPolarity = value;
                });
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _newCategoryKey,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categoryMenuItems(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _newCategoryKey = value;
                });
              },
            ),
            const SizedBox(height: 8),
            const Text('Window: 7 days'),
            const SizedBox(height: 8),
            Text(
              Activity.buildTargetLabel(
                polarity: _newPolarity,
                targetSuccesses: _newTargetSuccesses,
                windowDays: 7,
              ),
            ),
            Slider(
              min: 1,
              max: 7,
              divisions: 6,
              value: _newTargetSuccesses.toDouble(),
              onChanged: (value) {
                setState(() {
                  _newTargetSuccesses = value.round();
                });
              },
            ),
            FilledButton.icon(
              onPressed: _addActivity,
              icon: const Icon(Icons.add),
              label: const Text('Add Activity'),
            ),
            const SizedBox(height: 16),
            Text(
              'Habit Library',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...ActivityCategory.orderedKeys
                .where(grouped.containsKey)
                .expand((categoryKey) {
              final activities = grouped[categoryKey]!;
              return [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        iconForCategory(categoryKey),
                        color: colorForCategory(categoryKey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ActivityCategory.label(categoryKey),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colorForCategory(categoryKey),
                            ),
                      ),
                    ],
                  ),
                ),
                ...activities.map((activity) => _ActivityListCard(
                      activity: activity,
                      onToggleActive: (value) {
                        ref
                            .read(appStateControllerProvider.notifier)
                            .setActivityActive(activity.id, value);
                      },
                      onEdit: () => _editActivity(activity),
                      onDelete: () => _deleteActivity(activity),
                    )),
              ];
            }),
          ],
        );
      },
    );
  }

  List<DropdownMenuItem<String>> _categoryMenuItems() {
    return ActivityCategory.orderedKeys
        .map(
          (key) => DropdownMenuItem<String>(
            value: key,
            child: Text(ActivityCategory.label(key)),
          ),
        )
        .toList();
  }
}

class _ActivityListCard extends StatelessWidget {
  const _ActivityListCard({
    required this.activity,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final Activity activity;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final categoryColor = colorForCategory(activity.categoryKey);

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(activity.name),
            subtitle: Text(
              '${activity.targetSummaryLabel}\nStatus: ${activity.isActive ? 'Active (shown on daily screen)' : 'Hidden (available in library)'}',
            ),
            isThreeLine: true,
            leading: CircleAvatar(
              backgroundColor: categoryColor.withValues(alpha: 0.14),
              child: Icon(
                iconForActivity(activity),
                color: categoryColor,
              ),
            ),
            trailing: Switch(
              value: activity.isActive,
              onChanged: onToggleActive,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
