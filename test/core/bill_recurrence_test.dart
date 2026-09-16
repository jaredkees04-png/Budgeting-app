import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/core/utils/bill_recurrence.dart';
import 'package:budgeting_app/data/database/app_database.dart';
import 'package:budgeting_app/data/database/tables/categories_table.dart';

Category _category({
  required bool isRecurring,
  BillFrequency? billFrequency,
  DateTime? nextDueDate,
}) {
  return Category(
    id: 'c1',
    name: 'Rent',
    icon: 'home',
    color: '#C62828',
    budgetGroup: BudgetGroup.needs,
    isDefault: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: DateTime(2026, 1, 1),
    isRecurring: isRecurring,
    billFrequency: billFrequency,
    billAmountCents: isRecurring ? 120000 : null,
    nextDueDate: nextDueDate,
  );
}

void main() {
  test('a non-recurring category is never due', () {
    final category = _category(isRecurring: false);
    expect(billDueOn(category, DateTime(2026, 5, 1)), isFalse);
  });

  test('a monthly bill recurs on the same day-of-month every month', () {
    final category = _category(
      isRecurring: true,
      billFrequency: BillFrequency.monthly,
      nextDueDate: DateTime(2026, 3, 15),
    );

    expect(billDueOn(category, DateTime(2026, 3, 15)), isTrue);
    expect(billDueOn(category, DateTime(2026, 4, 15)), isTrue);
    expect(billDueOn(category, DateTime(2026, 1, 15)), isTrue);
    expect(billDueOn(category, DateTime(2026, 3, 14)), isFalse);
    expect(billDueOn(category, DateTime(2026, 3, 16)), isFalse);
  });

  test(
    'a monthly bill due on the 31st clamps to the last day of shorter months',
    () {
      final category = _category(
        isRecurring: true,
        billFrequency: BillFrequency.monthly,
        nextDueDate: DateTime(2026, 1, 31),
      );

      expect(billDueOn(category, DateTime(2026, 2, 28)), isTrue);
      expect(billDueOn(category, DateTime(2027, 2, 28)), isTrue);
      expect(billDueOn(category, DateTime(2028, 2, 29)), isTrue,
          reason: '2028 is a leap year, so the last day of Feb is the 29th');
      expect(billDueOn(category, DateTime(2026, 4, 30)), isTrue);
    },
  );

  test('a weekly bill recurs on the same weekday every week', () {
    // 2026-03-16 is a Monday.
    final category = _category(
      isRecurring: true,
      billFrequency: BillFrequency.weekly,
      nextDueDate: DateTime(2026, 3, 16),
    );

    expect(billDueOn(category, DateTime(2026, 3, 16)), isTrue);
    expect(billDueOn(category, DateTime(2026, 3, 23)), isTrue);
    expect(billDueOn(category, DateTime(2026, 3, 9)), isTrue);
    expect(billDueOn(category, DateTime(2026, 3, 17)), isFalse);
  });
}
