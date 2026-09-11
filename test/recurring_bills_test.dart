import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/app/app.dart';
import 'package:budgeting_app/app/providers.dart';
import 'package:budgeting_app/data/database/app_database.dart';
import 'package:budgeting_app/features/categories/category_list_screen.dart';
import 'package:budgeting_app/features/history/history_screen.dart';

void main() {
  testWidgets(
    'Bills tab: a category can become a recurring bill, be marked paid '
    '(logging a transaction and advancing its due date), then turned back '
    'into a plain category',
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

      await tester.tap(find.text('Bills'));
      await tester.pumpAndSettle();

      final billsScreen = find.byType(CategoryListScreen);
      final rentTile = find.descendant(
        of: billsScreen,
        matching: find.widgetWithText(ListTile, 'Rent/Mortgage'),
      );

      // Rent is a plain category by default: no amount, no due date.
      expect(rentTile, findsOneWidget);
      expect(
        find.descendant(of: rentTile, matching: find.text('Needs')),
        findsOneWidget,
        reason: 'A non-recurring category shows its budget group, not a due date',
      );

      // Turn it into a recurring bill.
      await tester.tap(rentTile);
      await tester.pumpAndSettle();
      expect(find.text('Edit category'), findsOneWidget);

      // The dialog's content is a SingleChildScrollView, so anything past
      // the fold needs to be scrolled into view before it can be tapped —
      // its geometric center would otherwise fall outside the dialog's
      // visible bounds and miss.
      await tester.ensureVisible(find.text('Recurring bill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recurring bill'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(TextField).at(1));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), '1200.00');
      await tester.ensureVisible(find.text('Monthly'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: billsScreen, matching: find.text('Due today')),
        findsOneWidget,
        reason: 'A brand new recurring bill defaults its due date to today',
      );
      expect(
        find.descendant(of: billsScreen, matching: find.text('\$1,200.00')),
        findsOneWidget,
      );

      // Mark it as paid: logs a transaction and rolls the due date forward
      // to the same day next month (mirrors _nextOccurrence in
      // CategoryRepository, since the exact day count depends on which
      // month the test happens to run in).
      final today = DateTime.now();
      final today0 = DateTime(today.year, today.month, today.day);
      final nextDue = DateTime(today.year, today.month + 1, today.day);
      final expectedDiff = nextDue.difference(today0).inDays;

      await tester.tap(
        find.descendant(of: rentTile, matching: find.byType(PopupMenuButton<String>)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as paid'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: billsScreen,
          matching: find.text('Due in ${expectedDiff}d'),
        ),
        findsOneWidget,
        reason: 'A monthly bill paid today should next be due next month',
      );

      final historyScreen = find.byType(HistoryScreen);
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: historyScreen, matching: find.text('-\$1,200.00')),
        findsOneWidget,
        reason: 'Marking a bill paid should log a real transaction',
      );

      // Turn recurring back off: the tile reverts to showing its budget
      // group instead of a due date.
      await tester.tap(find.text('Bills'));
      await tester.pumpAndSettle();
      await tester.tap(rentTile);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Recurring bill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recurring bill'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: rentTile, matching: find.text('Needs')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
