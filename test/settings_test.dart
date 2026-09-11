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
}
