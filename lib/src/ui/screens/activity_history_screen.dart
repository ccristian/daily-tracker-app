import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/date_key.dart';
import '../../models/activity.dart';
import '../../state/providers.dart';
import '../activity_visuals.dart';
import '../history/history_calendar_logic.dart';

class ActivityHistoryScreen extends ConsumerStatefulWidget {
  const ActivityHistoryScreen({
    super.key,
    required this.activityId,
  });

  final int activityId;

  @override
  ConsumerState<ActivityHistoryScreen> createState() =>
      _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends ConsumerState<ActivityHistoryScreen> {
  DateTime _visibleMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  Set<String> _doneDateKeys = <String>{};
  bool _loading = false;
  String? _lastLoadedSignature;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateControllerProvider);

    return appState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
      data: (state) {
        final activity = _findActivity(state.activities);
        if (activity == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Activity History')),
            body: const Center(
              child: Text('This activity is no longer available.'),
            ),
          );
        }

        _scheduleLoad(activity);

        final streak = state.streaks[activity.id] ?? 0;
        final categoryColor = colorForCategory(
          activity.categoryKey,
          categories: state.categories,
        );
        final monthDoneCount = _doneDateKeys.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              activity.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: categoryColor.withValues(alpha: 0.14),
                    child: Icon(
                      iconForActivity(activity, categories: state.categories),
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ActivityCategory.labelFor(
                            activity.categoryKey,
                            state.categories,
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(label: activity.targetSummaryLabel),
                  _SummaryChip(label: '$streak wk streak'),
                  _SummaryChip(
                    label: '$monthDoneCount done in ${DateFormat('MMM').format(_visibleMonth)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1, activity),
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
                    onPressed: () => _changeMonth(1, activity),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                _ActivityMonthCalendar(
                  visibleMonth: _visibleMonth,
                  doneDateKeys: _doneDateKeys,
                  onDayTap: (day) => _openDayDetails(
                    context: context,
                    activity: activity,
                    selectedDate: state.selectedDate,
                    day: day,
                    done: _doneDateKeys.contains(dateToKey(day)),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'Tap a day to see or change this activity for that date. Only the last 7 days can be edited.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Activity? _findActivity(List<Activity> activities) {
    for (final activity in activities) {
      if (activity.id == widget.activityId) {
        return activity;
      }
    }
    return null;
  }

  void _scheduleLoad(Activity activity) {
    final signature =
        '${activity.id}-${_visibleMonth.year}-${_visibleMonth.month}';
    if (_lastLoadedSignature == signature) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loading) {
        return;
      }
      _loadMonthData(activity);
    });
  }

  Future<void> _changeMonth(int offset, Activity activity) async {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + offset, 1);
      _lastLoadedSignature = null;
    });
    await _loadMonthData(activity);
  }

  Future<void> _loadMonthData(Activity activity) async {
    setState(() {
      _loading = true;
    });

    final repo = ref.read(dailyEntryRepositoryProvider);
    final start = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final end = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final doneDateKeys = await repo.getCompletionDateKeysForActivityInRange(
      activityId: activity.id,
      start: start,
      end: end,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _doneDateKeys = doneDateKeys.toSet();
      _loading = false;
      _lastLoadedSignature =
          '${activity.id}-${_visibleMonth.year}-${_visibleMonth.month}';
    });
  }

  Future<void> _openDayDetails({
    required BuildContext context,
    required Activity activity,
    required DateTime selectedDate,
    required DateTime day,
    required bool done,
  }) async {
    final editable = isEditableHistoryDate(day);
    final nextValue = !done;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(day),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  done ? 'Status: Yes' : 'Status: No',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (activity.polarity == ActivityPolarity.doLess) ...[
                  const SizedBox(height: 4),
                  Text(
                    'For this activity, Yes means it happened on that day.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                if (editable)
                  FilledButton(
                    onPressed: () async {
                      final repo = ref.read(dailyEntryRepositoryProvider);
                      await repo.upsertEntry(
                        activity: activity,
                        date: day,
                        binaryValue: nextValue,
                      );
                      await ref
                          .read(appStateControllerProvider.notifier)
                          .load(selectedDate: selectedDate);
                      await _loadMonthData(activity);
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text(nextValue ? 'Mark Yes' : 'Mark No'),
                  )
                else
                  Text(
                    'This day is outside the 7-day editable window.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityMonthCalendar extends StatelessWidget {
  const _ActivityMonthCalendar({
    required this.visibleMonth,
    required this.doneDateKeys,
    required this.onDayTap,
  });

  final DateTime visibleMonth;
  final Set<String> doneDateKeys;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leading = firstDay.weekday - 1;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Column(
      children: [
        Row(
          children: labels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
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
            final done = doneDateKeys.contains(key);
            final isFuture = day.isAfter(todayOnly);
            final isToday = _sameDay(day, todayOnly);

            return Padding(
              padding: const EdgeInsets.all(2),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onDayTap(day),
                child: Ink(
                  decoration: BoxDecoration(
                    color: done
                        ? Colors.green.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black12,
                      width: isToday ? 1.8 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontWeight: done ? FontWeight.bold : FontWeight.w500,
                          color: isFuture ? Colors.black38 : null,
                        ),
                      ),
                      if (done)
                        Positioned(
                          bottom: 6,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
