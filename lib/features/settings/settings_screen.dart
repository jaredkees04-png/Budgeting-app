import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/constants/theme_colors.dart';
import '../../core/utils/backup_io/backup_io.dart';
import '../lock/password_dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Clears any snackbar still showing before queuing the next one, so a
  /// quick sequence of actions (e.g. a rejected password immediately
  /// followed by a successful one) doesn't leave a stale message sitting
  /// in the queue for several seconds before the new one appears.
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleLock(BuildContext context, WidgetRef ref, bool enable) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    if (enable) {
      final password = await showNewPasswordDialog(
        context,
        title: 'Set a password',
      );
      if (password == null) return;
      await settingsRepo.enableLock(password);
    } else {
      final password = await showEnterPasswordDialog(
        context,
        title: 'Enter password to turn off lock',
      );
      if (password == null) return;
      final correct = await settingsRepo.verifyPin(password);
      if (!context.mounted) return;
      if (!correct) {
        _showMessage(context, 'Incorrect password');
        return;
      }
      await settingsRepo.disableLock();
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final current = await showEnterPasswordDialog(
      context,
      title: 'Enter your current password',
    );
    if (current == null) return;
    final correct = await settingsRepo.verifyPin(current);
    if (!context.mounted) return;
    if (!correct) {
      _showMessage(context, 'Incorrect password');
      return;
    }
    final newPassword = await showNewPasswordDialog(
      context,
      title: 'Set a new password',
    );
    if (newPassword == null) return;
    await settingsRepo.enableLock(newPassword);
    if (context.mounted) _showMessage(context, 'Password changed');
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final json = await ref.read(backupRepositoryProvider).exportToJson();
      final filename =
          'budget-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
      await saveBackupFile(filename, json);
      if (context.mounted) _showMessage(context, 'Backup saved');
    } catch (e) {
      if (context.mounted) _showMessage(context, 'Export failed: $e');
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    String? content;
    try {
      content = await pickBackupFile();
    } catch (e) {
      if (context.mounted) _showMessage(context, 'Could not read that file: $e');
      return;
    }
    if (content == null) return; // the picker was dismissed with no file chosen
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
          'This replaces everything currently in the app — all '
          'transactions, categories, and bills — with what\'s in the '
          'backup file. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(backupRepositoryProvider).importFromJson(content);
      if (context.mounted) _showMessage(context, 'Backup restored');
    } catch (e) {
      if (context.mounted) _showMessage(context, 'Import failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final isLockEnabled = ref.watch(isLockEnabledProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme'),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) {
                      settingsRepo.updateThemeMode(selection.first.index);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Accent color'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: kThemeColorOptions.map((option) {
                      final selected = option.color.toARGB32() == accentColor.toARGB32();
                      return GestureDetector(
                        onTap: () {
                          settingsRepo.updateAccentColor(option.color.toARGB32());
                        },
                        child: Tooltip(
                          message: option.name,
                          child: CircleAvatar(
                            backgroundColor: option.color,
                            radius: 18,
                            child: selected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('App Lock', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Require a password to open the app'),
                  subtitle: const Text(
                    'A local passcode for this device only — there\'s no '
                    'account and no way to recover it if forgotten, so '
                    'keep a backup exported (see below) just in case',
                  ),
                  value: isLockEnabled,
                  onChanged: (value) => _toggleLock(context, ref, value),
                ),
                if (isLockEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.password_outlined),
                    title: const Text('Change password'),
                    onTap: () => _changePassword(context, ref),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Backup & Restore', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export data'),
                  subtitle: const Text(
                    'Save every transaction, category, and bill to a file',
                  ),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: const Text('Import data'),
                  subtitle: const Text(
                    'Replace everything with a previously exported file',
                  ),
                  onTap: () => _import(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
