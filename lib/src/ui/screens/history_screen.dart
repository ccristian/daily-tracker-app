import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/date_key.dart';
import '../../models/activity.dart';
import '../../state/app_state_controller.dart';
import '../../state/providers.dart';
import '../history/activity_color_resolver.dart';
import '../history/history_calendar_logic.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _visibleMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  Map<String, List<_ActivityDayMarker>> _markersByDateKey =
      <String, List<_ActivityDayMarker>>{};
  Set<String> _streakHighlightKeys = <String>{};
  Map<String, List<_DayActivityRecord>> _detailsByDateKey =
      <String, List<_DayActivityRecord>>{};
  Map<String, int> _doneActiveCountByDateKey = <String, int>{};
  int _activeActivityCount = 0;
  bool _loading = false;
  String? _lastLoadedSignature;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateControllerProvider);

    return appState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (state) {
        _scheduleLoad(state);

        final activeActivities = state.activities
            .where((activity) => activity.isActive)
            .toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('Monthly History',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1, state),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_visibleMonth),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1, state),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              _MonthCalendar(
                visibleMonth: _visibleMonth,
                selectedDate: state.selectedDate,
                markersByDateKey: _markersByDateKey,
                doneActiveCountByDateKey: _doneActiveCountByDateKey,
                activeActivityCount: _activeActivityCount,
                streakKeys: _streakHighlightKeys,
                onDayTap: (day) => _onDayTap(day, activeActivities),
                onDayLongPress: _openDayDetails,
              ),
            const SizedBox(height: 10),
            const _Legend(),
          ],
        );
      },
    );
  }

  Future<void> _onDayTap(DateTime day, List<Activity> activeActivities) async {
    if (!isEditableHistoryDate(day)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only last 7 days can be edited.')),
      );
      return;
    }

    if (activeActivities.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No active activities available to edit.')),
      );
      return;
    }

    await _openQuickEditAll(day, activeActivities);
  }

  void _scheduleLoad(AppViewState state) {
    final signature = _buildLoadSignature(state);
    if (_lastLoadedSignature == signature) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loading) {
        return;
      }
      _loadMonthData(state);
    });
  }

  String _buildLoadSignature(AppViewState state) {
    final sortedStreaks = state.streaks.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final streakSignature =
        sortedStreaks.map((entry) => '${entry.key}:${entry.value}').join('|');
    final activitySignature = state.activities
        .map((activity) =>
            '${activity.id}:${activity.isActive}:${activity.deletedAt != null}')
        .join('|');
    final sortedEntries = state.entriesByActivity.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final entriesSignature = sortedEntries
        .map((entry) =>
            '${entry.key}:${entry.value.binaryValue == true ? 1 : 0}')
        .join('|');
    final selectedDateKey = dateToKey(state.selectedDate);

    return '${_visibleMonth.year}-${_visibleMonth.month}-$selectedDateKey-$activitySignature-$streakSignature-$entriesSignature';
  }

  Future<void> _loadMonthData(AppViewState state) async {
    setState(() {
      _loading = true;
    });

    final repo = ref.read(dailyEntryRepositoryProvider);
    final start = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final end = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);

    final recordsByDate =
        await repo.getMonthActivityRecords(start: start, end: end);

    final markersByDate = <String, List<_ActivityDayMarker>>{};
    final detailsByDate = <String, List<_DayActivityRecord>>{};
    final doneActiveCountByDate = <String, Set<int>>{};

    recordsByDate.forEach((dateKey, rawRecords) {
      final markers = <_ActivityDayMarker>[];
      final details = <_DayActivityRecord>[];
      final doneActiveIds = <int>{};

      for (final record in rawRecords) {
        if (!record.done) {
          continue;
        }
        final color = resolveActivityColor(record.activityId);
        final archived = record.isDeleted || !record.isActive;
        markers.add(
          _ActivityDayMarker(
            activityId: record.activityId,
            color: color,
            isArchived: archived,
          ),
        );
        if (record.isActive && !record.isDeleted) {
          doneActiveIds.add(record.activityId);
        }
        details.add(
          _DayActivityRecord(
            activityId: record.activityId,
            name: record.activityName,
            done: true,
            isActive: record.isActive,
            isDeleted: record.isDeleted,
            color: color,
          ),
        );
      }

      details
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (markers.isNotEmpty) {
        markersByDate[dateKey] = markers;
      }
      if (details.isNotEmpty) {
        detailsByDate[dateKey] = details;
      }
      if (doneActiveIds.isNotEmpty) {
        doneActiveCountByDate[dateKey] = doneActiveIds;
      }
    });

    final activeActivityCount =
        state.activities.where((activity) => activity.isActive).length;
    final streakKeys = buildStreakHighlightKeys(
      activities: state.activities.where((activity) => activity.isActive),
      streaks: state.streaks,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _markersByDateKey = markersByDate;
      _detailsByDateKey = detailsByDate;
      _streakHighlightKeys = streakKeys;
      _doneActiveCountByDateKey = doneActiveCountByDate.map(
        (key, value) => MapEntry(key, value.length),
      );
      _activeActivityCount = activeActivityCount;
      _loading = false;
      _lastLoadedSignature = _buildLoadSignature(state);
    });
  }

  Future<void> _changeMonth(int offset, AppViewState state) async {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + offset, 1);
      _lastLoadedSignature = null;
    });
    await _loadMonthData(state);
  }

  Future<void> _openQuickEditAll(
      DateTime day, List<Activity> activeActivities) async {
    final repo = ref.read(dailyEntryRepositoryProvider);
    final entriesByActivity = await repo.getEntriesByDate(day);
    if (!mounted) {
      return;
    }

    final initialValues = <int, bool>{
      for (final activity in activeActivities)
        activity.id: entriesByActivity[activity.id]?.binaryValue ?? false,
    };

    final result = await showModalBottomSheet<Map<int, bool>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final values = Map<int, bool>.from(initialValues);
        return StatefulBuilder(
          builder: (context, setState) {
            return FractionallySizedBox(
              heightFactor: 0.82,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Edit',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(day),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: activeActivities.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final activity = activeActivities[index];
                            final value = values[activity.id] ?? false;
                            return Card(
                              child: SwitchListTile(
                                value: value,
                                title: Text(activity.name),
                                subtitle: Text(value ? 'Yes' : 'No'),
                                onChanged: (next) {
                                  setState(() {
                                    values[activity.id] = next;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(values),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    for (final activity in activeActivities) {
      await repo.upsertEntry(
        activity: activity,
        date: day,
        binaryValue: result[activity.id] ?? false,
      );
    }

    await ref.read(appStateControllerProvider.notifier).load(selectedDate: day);
    final refreshedState = ref.read(appStateControllerProvider).value;
    if (refreshedState != null) {
      await _loadMonthData(refreshedState);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Saved activities for ${DateFormat('yyyy-MM-dd').format(day)}')),
    );
  }

  Future<void> _openDayDetails(DateTime day) async {
    final dateKey = dateToKey(day);
    final records = _detailsByDateKey[dateKey] ?? const <_DayActivityRecord>[];

    await HapticFeedback.lightImpact();

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DayDetailsSheet(
        day: day,
        records: records,
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.visibleMonth,
    required this.selectedDate,
    required this.markersByDateKey,
    required this.doneActiveCountByDateKey,
    required this.activeActivityCount,
    required this.streakKeys,
    required this.onDayTap,
    required this.onDayLongPress,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final Map<String, List<_ActivityDayMarker>> markersByDateKey;
  final Map<String, int> doneActiveCountByDateKey;
  final int activeActivityCount;
  final Set<String> streakKeys;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime> onDayLongPress;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leading = firstDay.weekday - 1;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;

    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        Row(
          children: labels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(label,
                          style: Theme.of(context).textTheme.labelMedium),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leading + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final day =
                DateTime(visibleMonth.year, visibleMonth.month, dayNumber);
            final key = dateToKey(day);
            final selected = _sameDay(day, selectedDate);
            final markers =
                markersByDateKey[key] ?? const <_ActivityDayMarker>[];
            final markerPresentation =
                buildDayMarkerPresentation(markers.length, maxVisible: 8);
            final visibleMarkers =
                markers.take(markerPresentation.visibleCount).toList();
            final hasDone = markers.isNotEmpty;
            final streak = hasDone && streakKeys.contains(key);
            final today = DateTime.now();
            final todayOnly = DateTime(today.year, today.month, today.day);
            final isFuture = day.isAfter(todayOnly);
            final doneActiveCount = doneActiveCountByDateKey[key] ?? 0;
            final qualityRatio = activeActivityCount > 0
                ? (doneActiveCount / activeActivityCount).clamp(0.0, 1.0)
                : 0.0;
            final qualityFill = !isFuture && activeActivityCount > 0
                ? Color.lerp(Colors.red, Colors.green, qualityRatio)!
                    .withValues(alpha: 0.14)
                : null;

            final border = selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2)
                : streak
                    ? Border.all(color: Colors.amber.shade700, width: 1.4)
                    : Border.all(color: Colors.transparent);

            return Padding(
              padding: const EdgeInsets.all(2),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onDayTap(day),
                onLongPress: () => onDayLongPress(day),
                child: Ink(
                  decoration: BoxDecoration(
                    color: qualityFill,
                    borderRadius: BorderRadius.circular(10),
                    border: border,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final dotSize = constraints.maxHeight < 48 ? 5.0 : 6.0;
                      final radius = constraints.biggest.shortestSide * 0.33;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          for (var i = 0; i < visibleMarkers.length; i += 1)
                            Transform.translate(
                              offset: _markerOffsetForIndex(
                                index: i,
                                count: visibleMarkers.length,
                                radius: radius,
                              ),
                              child: Container(
                                width: dotSize,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  color: visibleMarkers[i].isArchived
                                      ? visibleMarkers[i]
                                          .color
                                          .withValues(alpha: 0.55)
                                      : visibleMarkers[i].color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (markerPresentation.hasOverflow)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '+${markerPresentation.overflowCount}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(fontSize: 9),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Offset _markerOffsetForIndex({
    required int index,
    required int count,
    required double radius,
  }) {
    if (count <= 0) {
      return Offset.zero;
    }
    final angle = (-math.pi / 2) + (2 * math.pi * index / count);
    return Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendItem(color: Colors.blue, label: 'Activity ring dot'),
        _LegendItem(color: Colors.red, label: 'Low-quality day'),
        _LegendItem(color: Colors.green, label: 'High-quality day'),
        _LegendItem(borderColor: Colors.amber, label: 'Current streak day'),
        _LegendItem(borderOnly: true, label: 'Selected day'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    this.color,
    this.borderOnly = false,
    this.borderColor,
    required this.label,
  });

  final Color? color;
  final bool borderOnly;
  final Color? borderColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: borderOnly ? null : color,
            borderRadius: BorderRadius.circular(3),
            border: borderOnly
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2)
                : borderColor != null
                    ? Border.all(color: borderColor!, width: 1.5)
                    : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _DayDetailsSheet extends StatelessWidget {
  const _DayDetailsSheet({
    required this.day,
    required this.records,
  });

  final DateTime day;
  final List<_DayActivityRecord> records;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: FractionallySizedBox(
        heightFactor: 0.7,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day Details',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(day),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  records.isEmpty
                      ? 'No completed activities for this day.'
                      : '${records.length} activities completed',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: records.isEmpty
                      ? const Center(
                          child: Text('No activities marked as done.'),
                        )
                      : ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return _AnimatedDetailRow(
                              index: index,
                              child: Card(
                                child: ListTile(
                                  leading: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: record.isArchived
                                          ? record.color.withValues(alpha: 0.55)
                                          : record.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  title: Text(
                                    record.isArchived
                                        ? '${record.name} (archived)'
                                        : record.name,
                                  ),
                                  subtitle: const Text('Done'),
                                  trailing:
                                      const Icon(Icons.check_circle_outline),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDetailRow extends StatelessWidget {
  const _AnimatedDetailRow({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 180 + (index * 40)),
      curve: Curves.easeOut,
      builder: (context, value, rowChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: rowChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _ActivityDayMarker {
  const _ActivityDayMarker({
    required this.activityId,
    required this.color,
    required this.isArchived,
  });

  final int activityId;
  final Color color;
  final bool isArchived;
}

class _DayActivityRecord {
  const _DayActivityRecord({
    required this.activityId,
    required this.name,
    required this.done,
    required this.isActive,
    required this.isDeleted,
    required this.color,
  });

  final int activityId;
  final String name;
  final bool done;
  final bool isActive;
  final bool isDeleted;
  final Color color;

  bool get isArchived => isDeleted || !isActive;
}
