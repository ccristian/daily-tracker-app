import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/activity.dart';
import '../../state/providers.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  final _nameController = TextEditingController();
  ActivityPolarity _newPolarity = ActivityPolarity.doMore;
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
                    const Text('Window: 7 days'),
                    const SizedBox(height: 12),
                    Text('Target successes: $target/7'),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Delete "${activity.name}"? This hides it from tracking, but keeps history.'),
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

    await ref.read(appStateControllerProvider.notifier).deleteActivity(activity.id);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateControllerProvider);

    return appState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (state) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('Add Activity', style: Theme.of(context).textTheme.titleMedium),
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
            const Text('Window: 7 days'),
            const SizedBox(height: 8),
            Text('Target successes: $_newTargetSuccesses/7'),
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
            Text('Current Activities', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...state.activities.map((activity) {
              final summary = activity.polarity == ActivityPolarity.doMore
                  ? 'At least ${activity.targetSuccesses}/${activity.windowDays}'
                  : 'At most ${activity.allowedFailures}/${activity.windowDays}';
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(activity.name),
                      subtitle: Text(
                        '$summary\nStatus: ${activity.isActive ? 'Active (shown on daily screen)' : 'Hidden (not shown on daily screen)'}',
                      ),
                      isThreeLine: true,
                      leading: activity.isPredefined
                          ? const Icon(Icons.bookmark_outline)
                          : const Icon(Icons.person_outline),
                      trailing: Switch(
                        value: activity.isActive,
                        onChanged: (value) {
                          ref.read(appStateControllerProvider.notifier).setActivityActive(activity.id, value);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _editActivity(activity),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _deleteActivity(activity),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
