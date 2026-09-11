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

  testWidgets(
    'the dashboard shows what remains of income after spending, and turns '
    'red once spending exceeds it',
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

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.tap(find.text('Income'));
      await tester.tap(find.text('Save transaction'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '600');
      await tester.tap(find.text('Groceries'));
      await tester.tap(find.text('Save transaction'));
      await tester.pumpAndSettle();

      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('\$400.00'), findsOneWidget);
      final remainingText = tester.widget<Text>(
        find.text('\$400.00'),
      );
      expect(
        remainingText.style?.color,
        isNot(equals(Theme.of(tester.element(find.text('Remaining'))).colorScheme.error)),
        reason: 'Still in the black, so it should not be styled as an error',
      );

      // Spend more than the remaining income: it goes negative and red.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '500');
      await tester.tap(find.text('Groceries'));
      await tester.tap(find.text('Save transaction'));
      await tester.pumpAndSettle();

      expect(find.text('-\$100.00'), findsOneWidget);
      final overspentText = tester.widget<Text>(find.text('-\$100.00'));
      expect(
        overspentText.style?.color,
        Theme.of(tester.element(find.text('Remaining'))).colorScheme.error,
        reason: 'Overspending should be styled as an error, not a normal amount',
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'the 50/30/20 guideline card renders real figures, not blank',
    (tester) async {
      // Regression test: the settings row's id ended up 1 (SQLite assigns
      // the next rowid when an INTEGER PRIMARY KEY is omitted from an
      // INSERT, ignoring its declared default of 0), so every settings
      // query filtered by id.equals(0) silently matched nothing and this
      // card rendered as an empty SizedBox — with no test ever asserting
      // on its actual content, that went unnoticed.
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
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.tap(find.text('Income'));
      await tester.tap(find.text('Save transaction'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '600');
      await tester.tap(find.text('Groceries'));
      await tester.tap(find.text('Save transaction'));
      await tester.pumpAndSettle();

      // The card is below the fold in the test surface's default size;
      // ListView only mounts elements for children near the viewport, so
      // it has to actually be scrolled into view rather than just present
      // in the list's widget/data — otherwise find() can't see it.
      await tester.scrollUntilVisible(
        find.text('50/30/20 guideline'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('50/30/20 guideline'), findsOneWidget);
      // Groceries is the only "needs" spending: $600 of $1000 income.
      expect(find.text('60% / ~50%'), findsOneWidget);
      expect(
        find.textContaining("You're at 60% on Groceries"),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

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

      // On the Bills tab (categories, some of which can be recurring
      // bills), the + button must open "New category" — not "Add
      // transaction" from some other tab's leftover FAB.
      await tester.tap(find.text('Bills'));
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
