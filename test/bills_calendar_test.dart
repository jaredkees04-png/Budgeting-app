import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/app/app.dart';
import 'package:budgeting_app/app/providers.dart';
import 'package:budgeting_app/data/database/app_database.dart';
import 'package:budgeting_app/features/calendar/bills_calendar_screen.dart';
import 'package:budgeting_app/features/history/history_screen.dart';

void main() {
  testWidgets(
    'Calendar tab: adding a bill via its + button pins it to the selected '
    "day (recurring switched on by default) and shows up in that day's "
    'list; marking it paid there logs a real transaction',
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

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      final calendarScreen = find.byType(BillsCalendarScreen);
      expect(
        find.descendant(
          of: calendarScreen,
          matching: find.text('No bills due this day'),
        ),
        findsOneWidget,
      );

      // Adding from the calendar's + button pins the new bill to whatever
      // day is currently selected (today, by default) and switches
      // "Recurring bill" on already, since pinning a due date is the
      // whole point of adding it here.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('New category'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Netflix');
      await tester.ensureVisible(find.byType(TextField).at(1));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), '15.00');
      await tester.ensureVisible(find.text('Monthly'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: calendarScreen, matching: find.text('Netflix')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: calendarScreen, matching: find.text('\$15.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: calendarScreen,
          matching: find.text('No bills due this day'),
        ),
        findsNothing,
      );

      // Marking it paid from the calendar logs a real transaction, same
      // as marking paid from the Bills tab does. The calendar grid above
      // pushes this list below the fold in the test surface's default
      // size — Flutter's default cacheExtent still builds it (so find()
      // can see it) without actually painting it on-screen, so it has to
      // be scrolled into view before tapping or the tap lands past the
      // visible viewport and misses.
      await tester.ensureVisible(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      final historyScreen = find.byType(HistoryScreen);
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: historyScreen, matching: find.text('-\$15.00')),
        findsOneWidget,
        reason: 'Marking a bill paid from the calendar should log a transaction',
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
