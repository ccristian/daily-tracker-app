import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/activity.dart';
import '../../state/providers.dart';
import '../activity_visuals.dart';
import 'activity_history_screen.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  final _nameController = TextEditingController();
  ActivityPolarity _newPolarity = ActivityPolarity.doMore;
  String _newCategoryKey = ActivityCategory.fallbackKey;
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
    final currentCategories =
        ref.read(appStateControllerProvider).value?.categories ??
            ActivityCategory.defaultDefinitions;
    final nameController = TextEditingController(text: activity.name);
    var polarity = activity.polarity;
    var categoryKey = currentCategories
            .any((category) => category.key == activity.categoryKey)
        ? activity.categoryKey
        : currentCategories.first.key;
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
                      items: _categoryMenuItems(currentCategories),
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

  Future<void> _manageCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _ManageCategoriesPage(
        onAddCategory: (name) =>
            ref.read(appStateControllerProvider.notifier).addCategory(name),
        onRenameCategory: (categoryKey, name) => ref
            .read(appStateControllerProvider.notifier)
            .renameCategory(categoryKey: categoryKey, name: name),
        onDeleteCategory: (categoryKey) => ref
            .read(appStateControllerProvider.notifier)
            .deleteCategory(categoryKey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateControllerProvider);

    return appState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (state) {
        final categoryKeys = state.categories.map((category) => category.key).toSet();
        final selectedNewCategoryKey = categoryKeys.contains(_newCategoryKey)
            ? _newCategoryKey
            : state.categories.first.key;
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: _manageCategories,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Manage'),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.categories
                  .map(
                    (category) => Chip(
                      avatar: Icon(
                        iconForCategory(
                          category.key,
                          categories: state.categories,
                        ),
                        size: 18,
                        color: colorForCategory(
                          category.key,
                          categories: state.categories,
                        ),
                      ),
                      label: Text(category.label),
                    ),
                  )
                  .toList(),
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
              initialValue: selectedNewCategoryKey,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categoryMenuItems(state.categories),
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
            ...state.categories
                .map((category) => category.key)
                .where(grouped.containsKey)
                .expand((categoryKey) {
              final activities = grouped[categoryKey]!;
              return [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        iconForCategory(
                          categoryKey,
                          categories: state.categories,
                        ),
                        color: colorForCategory(
                          categoryKey,
                          categories: state.categories,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ActivityCategory.labelFor(categoryKey, state.categories),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colorForCategory(
                                categoryKey,
                                categories: state.categories,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                ...activities.map((activity) => _ActivityListCard(
                      activity: activity,
                      categories: state.categories,
                      onOpenHistory: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              ActivityHistoryScreen(activityId: activity.id),
                        ),
                      ),
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

  List<DropdownMenuItem<String>> _categoryMenuItems(
    List<ActivityCategoryDefinition> categories,
  ) {
    return categories
        .map(
          (category) => DropdownMenuItem<String>(
            value: category.key,
            child: Row(
              children: [
                Icon(
                  iconForCategory(
                    category.key,
                    categories: categories,
                  ),
                  size: 18,
                  color: colorForCategory(
                    category.key,
                    categories: categories,
                  ),
                ),
                const SizedBox(width: 8),
                Text(category.label),
              ],
            ),
          ),
        )
        .toList();
  }
}

class _ManageCategoriesPage extends ConsumerStatefulWidget {
  const _ManageCategoriesPage({
    required this.onAddCategory,
    required this.onRenameCategory,
    required this.onDeleteCategory,
  });

  final Future<void> Function(String name) onAddCategory;
  final Future<void> Function(String categoryKey, String name) onRenameCategory;
  final Future<void> Function(String categoryKey) onDeleteCategory;

  @override
  ConsumerState<_ManageCategoriesPage> createState() =>
      _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends ConsumerState<_ManageCategoriesPage> {
  final _newCategoryController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _submitNewCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) {
      return;
    }
    await _run(() => widget.onAddCategory(name));
    if (mounted) {
      _newCategoryController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _promptRename(ActivityCategoryDefinition category) async {
    final controller = TextEditingController(text: category.label);
    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
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
      ),
    );
    if (didSave != true) {
      return;
    }

    await _run(
      () => widget.onRenameCategory(category.key, controller.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateControllerProvider);
    final categories =
        appState.value?.categories ?? ActivityCategory.defaultDefinitions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Create, rename, and organize your activity categories.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newCategoryController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'New category',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submitNewCategory(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _submitNewCategory,
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
          const SizedBox(height: 20),
          Text(
            'Current Categories',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...categories.map(
            (category) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      colorForCategory(
                        category.key,
                        categories: categories,
                      ).withValues(alpha: 0.14),
                  child: Icon(
                    iconForCategory(
                      category.key,
                      categories: categories,
                    ),
                    color: colorForCategory(
                      category.key,
                      categories: categories,
                    ),
                  ),
                ),
                title: Text(category.label),
                subtitle: Text(category.key),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      onPressed: _busy ? null : () => _promptRename(category),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Rename',
                    ),
                    IconButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                                () => widget.onDeleteCategory(category.key),
                              ),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityListCard extends StatelessWidget {
  const _ActivityListCard({
    required this.activity,
    required this.categories,
    required this.onOpenHistory,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final Activity activity;
  final List<ActivityCategoryDefinition> categories;
  final VoidCallback onOpenHistory;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final categoryColor = colorForCategory(
      activity.categoryKey,
      categories: categories,
    );

    return Card(
      child: Column(
        children: [
          ListTile(
            onTap: onOpenHistory,
            onLongPress: onOpenHistory,
            title: Text(activity.name),
            subtitle: Text(activity.targetSummaryLabel),
            leading: CircleAvatar(
              backgroundColor: categoryColor.withValues(alpha: 0.14),
              child: Icon(
                iconForActivity(activity, categories: categories),
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
