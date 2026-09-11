import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/app/app.dart';
import 'package:budgeting_app/app/providers.dart';
import 'package:budgeting_app/data/database/app_database.dart';

void main() {
  testWidgets('app launches to the dashboard with seeded categories', (
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
      find.descendant(of: find.byType(AppBar), matching: find.text('Dashboard')),
      findsOneWidget,
    );
    expect(find.text('No transactions yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add transaction'), findsOneWidget);
    // Default categories seeded on first launch should be selectable.
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);

    // Dispose the widget tree (and its drift stream subscriptions) inside
    // a pump, then pump once more so drift's zero-duration cleanup timer
    // fires before the test binding checks for stray timers.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('logging a transaction updates the dashboard total', (
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

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '42.50');
    await tester.tap(find.text('Groceries'));
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Dashboard')),
      findsOneWidget,
    );
    // Appears twice: the period's "Spent" total and the Groceries row,
    // which are equal since this is the only transaction.
    expect(find.text('\$42.50'), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('history lets you edit and delete a logged transaction', (
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

    // Log a transaction to edit.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '42.50');
    await tester.tap(find.text('Groceries'));
    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();

    // Switch to the History tab and open it.
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('-\$42.50'), findsOneWidget);

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    expect(find.text('Edit transaction'), findsOneWidget);

    // Editing updates the amount shown back in History.
    await tester.enterText(find.byType(TextField).first, '55.00');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('-\$55.00'), findsOneWidget);

    // Deleting removes it and the empty state reappears.
    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No transactions yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    "each tab's own + button opens that tab's action, not another tab's",
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const BudgetingApp(),
        ),
      );
      await tester.pumpAndSettle();

      // On the Categories tab, the + button must open "New category" —
      // not "Add transaction" from some other tab's leftover FAB.
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('New category'), findsOneWidget);
      expect(find.text('Add transaction'), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Adding a category here actually creates it.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Subscriptions');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Subscriptions'), findsOneWidget);

      // And History's + button opens "Add transaction", not "New category".
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Add transaction'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
