import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/theme_builder.dart';
import '../features/lock/app_lock_screen.dart';
import 'home_shell.dart';
import 'providers.dart';

class BudgetingApp extends ConsumerWidget {
  const BudgetingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);
    final themeMode = ref.watch(themeModeProvider);
    final background = ref.watch(backgroundOptionProvider);

    return MaterialApp(
      title: 'Budget Tracker',
      themeMode: themeMode,
      theme: buildAppTheme(
        accentColor: accentColor,
        brightness: Brightness.light,
        background: background,
      ),
      darkTheme: buildAppTheme(
        accentColor: accentColor,
        brightness: Brightness.dark,
        background: background,
      ),
      home: const _AppGate(),
    );
  }
}

/// Decides between the startup spinner, the lock screen, and the real
/// app. Settings (which is where "is a lock even configured" lives) load
/// asynchronously, so this waits for that to resolve rather than
/// showing [HomeShell] first and only then possibly slamming the lock
/// screen on top — a "flash of the unlocked app" would defeat the point
/// of having a lock at all.
class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    if (!settingsAsync.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLockEnabled = settingsAsync.value?.isLockEnabled ?? false;
    final isUnlocked = ref.watch(isUnlockedProvider);
    if (isLockEnabled && !isUnlocked) {
      return const AppLockScreen();
    }
    return const HomeShell();
  }
}
