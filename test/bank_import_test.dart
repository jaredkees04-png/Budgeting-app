import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/app/app.dart';
import 'package:budgeting_app/app/providers.dart';
import 'package:budgeting_app/data/database/app_database.dart';
import 'package:budgeting_app/features/bank_import/bank_import_screen.dart';

void main() {
  testWidgets(
    'Bills tab has an entry point into the bank-statement import screen',
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

      // Actually invoking the file picker here would hit a real platform
      // channel/browser API that doesn't exist in a widget test — parsing
      // and detection are covered separately in
      // test/domain/bank_statement_parser_test.dart and
      // test/domain/recurring_bill_detector_test.dart. This just checks
      // the entry point exists and opens the right screen.
      await tester.tap(find.byIcon(Icons.account_balance_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(BankImportScreen), findsOneWidget);
      expect(find.text('Choose CSV file'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
