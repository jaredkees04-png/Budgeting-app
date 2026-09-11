import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/app/app.dart';
import 'package:budgeting_app/app/providers.dart';
import 'package:budgeting_app/data/database/app_database.dart';
import 'package:budgeting_app/features/bills/bills_list_screen.dart';
import 'package:budgeting_app/features/history/history_screen.dart';

void main() {
  testWidgets(
    'bills: add, mark as paid logs a transaction and advances the due '
    'date, edit, then delete',
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
      expect(find.text('No recurring bills yet'), findsOneWidget);

      // Add a weekly bill due today.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('New recurring bill'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Netflix');
      await tester.enterText(find.byType(TextField).at(1), '15.00');
      await tester.tap(find.text('Groceries'));
      await tester.tap(find.text('Weekly'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final billsScreen = find.byType(BillsListScreen);
      expect(
        find.descendant(of: billsScreen, matching: find.text('Netflix')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: billsScreen, matching: find.text('\$15.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: billsScreen, matching: find.text('Due today')),
        findsOneWidget,
      );

      // Mark it as paid: logs a transaction and rolls the due date forward.
      await tester.tap(
        find.descendant(
          of: billsScreen,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as paid'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: billsScreen, matching: find.text('Due in 7d')),
        findsOneWidget,
        reason: 'A weekly bill paid today should next be due in 7 days',
      );

      final historyScreen = find.byType(HistoryScreen);
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: historyScreen, matching: find.text('-\$15.00')),
        findsOneWidget,
        reason: 'Marking a bill paid should log a real transaction',
      );
      expect(
        find.descendant(of: historyScreen, matching: find.text('Netflix')),
        findsOneWidget,
        reason: "The transaction's note should identify which bill it was",
      );

      // Edit the bill's amount.
      await tester.tap(find.text('Bills'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: billsScreen, matching: find.text('Netflix')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit bill'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), '20.00');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: billsScreen, matching: find.text('\$20.00')),
        findsOneWidget,
      );

      // Delete the bill.
      await tester.tap(
        find.descendant(
          of: billsScreen,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete bill?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('No recurring bills yet'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
