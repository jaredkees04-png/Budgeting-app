import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/app/app.dart';
import 'package:budgeting_app/app/providers.dart';
import 'package:budgeting_app/core/constants/theme_colors.dart';
import 'package:budgeting_app/data/database/app_database.dart';

void main() {
  testWidgets('changing theme mode and accent color updates MaterialApp', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const BudgetingApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
      reason: 'Tapping Dark should flip the whole app into dark mode',
    );

    await tester.tap(find.byTooltip('Purple'));
    await tester.pumpAndSettle();

    final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    expect(
      theme.colorScheme.primary,
      isNot(equals(ColorScheme.fromSeed(seedColor: kThemeColorOptions.first.color).primary)),
      reason: 'Picking Purple should change the seed color away from the default green',
    );

    // Rebuilding the whole app (simulating a reload) should show the
    // persisted choice, not reset to defaults.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const BudgetingApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
      reason: 'Theme choice should persist across an app restart',
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.colorScheme.primary,
      theme.colorScheme.primary,
      reason: 'Accent color should persist across an app restart',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('changing background option updates surface color and persists', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const BudgetingApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    final defaultSurface =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.colorScheme.surface;

    await tester.tap(find.byTooltip('Pure'));
    await tester.pumpAndSettle();

    final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    expect(
      theme.colorScheme.surface,
      isNot(equals(defaultSurface)),
      reason: 'Picking Pure should change the surface color away from the default',
    );
    expect(
      theme.scaffoldBackgroundColor,
      theme.colorScheme.surface,
      reason: 'The scaffold background should track the chosen surface color',
    );

    // Rebuilding the whole app (simulating a reload) should show the
    // persisted choice, not reset to the default background.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const BudgetingApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.colorScheme.surface,
      theme.colorScheme.surface,
      reason: 'Background choice should persist across an app restart',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('Settings shows a Backup & Restore section', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const BudgetingApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // The Background section (added above Backup & Restore) pushes it
    // below the fold, so a lazily-built ListView won't have it in the
    // tree yet without scrolling to it first.
    await tester.scrollUntilVisible(find.text('Backup & Restore'), 200);
    await tester.pumpAndSettle();

    // Actually invoking export/import here would hit real platform
    // channels (path_provider, a browser file dialog) that don't exist in
    // a widget test — BackupRepository's own round-trip logic is covered
    // separately in test/data/backup_repository_test.dart. This just
    // checks the entry points are present and correctly labeled.
    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Export data'), findsOneWidget);
    expect(find.text('Import data'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
