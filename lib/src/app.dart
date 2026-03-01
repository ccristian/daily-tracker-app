import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/providers.dart';
import 'ui/screens/activities_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/widgets/pin_dialogs.dart';

class DailyTrackerApp extends ConsumerStatefulWidget {
  const DailyTrackerApp({super.key});

  @override
  ConsumerState<DailyTrackerApp> createState() => _DailyTrackerAppState();
}

class _DailyTrackerAppState extends ConsumerState<DailyTrackerApp> with WidgetsBindingObserver {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(lockStateProvider.notifier).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(lockStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A6F4F)),
      ),
      home: !lockState.initialized
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : lockState.pinEnabled && lockState.locked
              ? UnlockScreen(
                  onVerifyPin: (pin) => ref.read(appLockServiceProvider).verifyPin(pin),
                  onUnlock: () => ref.read(lockStateProvider.notifier).unlock(),
                )
              : Scaffold(
                  appBar: AppBar(
                    title: const Text('Daily Tracker'),
                  ),
                  body: IndexedStack(
                    index: _tabIndex,
                    children: const [
                      HomeScreen(),
                      HistoryScreen(),
                      ActivitiesScreen(),
                      SettingsScreen(),
                    ],
                  ),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _tabIndex,
                    destinations: const [
                      NavigationDestination(icon: Icon(Icons.today), label: 'Home'),
                      NavigationDestination(icon: Icon(Icons.history), label: 'History'),
                      NavigationDestination(icon: Icon(Icons.list), label: 'Activities'),
                      NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
                    ],
                    onDestinationSelected: (index) {
                      setState(() {
                        _tabIndex = index;
                      });
                    },
                  ),
                ),
    );
  }
}
