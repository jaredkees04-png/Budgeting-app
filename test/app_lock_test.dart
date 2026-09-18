import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/app/app.dart';
import 'package:budgeting_app/app/providers.dart';
import 'package:budgeting_app/data/database/app_database.dart';

void main() {
  testWidgets(
    'setting a password locks the app on the next launch until the '
    'correct password is entered, and a wrong one is rejected',
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

      // No lock configured yet: the app opens straight to the dashboard.
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Dashboard')),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Require a password to open the app'));
      await tester.pumpAndSettle();
      expect(find.text('Set a password'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Password'), '1234');
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm password'),
        '1234',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Enabling lock takes effect on the next launch, not retroactively
      // on the session already unlocked by being in the app.
      expect(find.text('Change password'), findsOneWidget);

      // Simulate relaunching the app.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const BudgetingApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budget Tracker is locked'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);

      // A wrong password is rejected and stays locked.
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Incorrect password'), findsOneWidget);
      expect(find.text('Budget Tracker is locked'), findsOneWidget);

      // The correct password unlocks it.
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '1234');
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Dashboard')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'turning lock off requires the current password, and changing it '
    'requires the old one before accepting a new one',
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

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Require a password to open the app'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '1234');
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm password'),
        '1234',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Wrong current password when disabling: lock stays on.
      await tester.tap(find.text('Require a password to open the app'));
      await tester.pumpAndSettle();
      expect(find.text('Enter password to turn off lock'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'nope');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Incorrect password'), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget);

      // Changing the password requires the current one first. The
      // Background section above this card can push it below the fold in
      // a lazily-built ListView, so scroll it into view before tapping.
      await tester.scrollUntilVisible(find.text('Change password'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '1234');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '5678');
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm password'),
        '5678',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Password changed'), findsOneWidget);

      // The old password no longer works to disable it...
      await tester.tap(find.text('Require a password to open the app'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '1234');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Incorrect password'), findsOneWidget);

      // ...but the new one does.
      await tester.tap(find.text('Require a password to open the app'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '5678');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Change password'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
