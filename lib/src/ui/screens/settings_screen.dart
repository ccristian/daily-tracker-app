import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/settings.dart';
import '../../state/providers.dart';
import '../widgets/pin_dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateControllerProvider);

    return appState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (state) {
        final reminder = state.settings.reminderSettings;

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('Reminders', style: Theme.of(context).textTheme.titleMedium),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable daily reminder'),
                    value: reminder.enabled,
                    onChanged: (value) {
                      ref.read(appStateControllerProvider.notifier).updateReminder(
                            reminder.copyWith(enabled: value),
                          );
                    },
                  ),
                  ListTile(
                    title: const Text('Reminder time'),
                    subtitle: Text('${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
                      );
                      if (picked == null) {
                        return;
                      }
                      await ref.read(appStateControllerProvider.notifier).updateReminder(
                            ReminderSettings(
                              enabled: reminder.enabled,
                              hour: picked.hour,
                              minute: picked.minute,
                            ),
                          );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('App Lock', style: Theme.of(context).textTheme.titleMedium),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(state.settings.pinEnabled ? 'PIN lock is enabled' : 'PIN lock is disabled'),
                    subtitle: const Text('If forgotten, reinstall is required to reset PIN.'),
                  ),
                  if (!state.settings.pinEnabled)
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Enable 4-digit PIN'),
                      onTap: () => _enablePin(context, ref),
                    )
                  else ...[
                    ListTile(
                      leading: const Icon(Icons.password),
                      title: const Text('Change PIN'),
                      onTap: () => _changePin(context, ref),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock_open),
                      title: const Text('Disable PIN'),
                      onTap: () => _disablePin(context, ref),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _enablePin(BuildContext context, WidgetRef ref) async {
    final first = await showPinInputDialog(
      context: context,
      title: 'Create PIN',
      actionLabel: 'Next',
      helper: 'Enter a 4-digit PIN for app access.',
    );
    if (first == null || !context.mounted) {
      return;
    }

    final confirm = await showPinInputDialog(
      context: context,
      title: 'Confirm PIN',
      actionLabel: 'Enable',
    );
    if (confirm == null || !context.mounted) {
      return;
    }

    if (first != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs did not match')),
      );
      return;
    }

    await ref.read(appLockServiceProvider).enablePin(first);
    await ref.read(lockStateProvider.notifier).refresh();
    await ref.read(appStateControllerProvider.notifier).refreshSettings();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN enabled')), 
      );
    }
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final current = await showPinInputDialog(
      context: context,
      title: 'Current PIN',
      actionLabel: 'Next',
    );
    if (current == null || !context.mounted) {
      return;
    }

    final next = await showPinInputDialog(
      context: context,
      title: 'New PIN',
      actionLabel: 'Next',
    );
    if (next == null || !context.mounted) {
      return;
    }

    final confirm = await showPinInputDialog(
      context: context,
      title: 'Confirm New PIN',
      actionLabel: 'Change',
    );
    if (confirm == null || !context.mounted) {
      return;
    }

    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PINs did not match')),
      );
      return;
    }

    final ok = await ref.read(appLockServiceProvider).changePin(current, next);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'PIN changed' : 'Current PIN is incorrect')),
    );

    await ref.read(appStateControllerProvider.notifier).refreshSettings();
  }

  Future<void> _disablePin(BuildContext context, WidgetRef ref) async {
    final pin = await showPinInputDialog(
      context: context,
      title: 'Disable PIN',
      actionLabel: 'Disable',
      helper: 'Enter current PIN to disable lock.',
    );
    if (pin == null || !context.mounted) {
      return;
    }

    final ok = await ref.read(appLockServiceProvider).disablePin(pin);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'PIN disabled' : 'Incorrect PIN')),
    );

    if (ok) {
      await ref.read(lockStateProvider.notifier).refresh();
      await ref.read(appStateControllerProvider.notifier).refreshSettings();
    }
  }
}
