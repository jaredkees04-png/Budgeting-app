import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/data/database/tables/categories_table.dart';
import 'package:budgeting_app/domain/models/bank_transaction.dart';
import 'package:budgeting_app/domain/services/recurring_bill_detector.dart';

BankTransaction _tx(String date, String description, double amount) {
  return BankTransaction(
    date: DateTime.parse(date),
    description: description,
    amountCents: (amount * 100).round(),
  );
}

void main() {
  final detector = RecurringBillDetector();

  test('flags a monthly charge repeating for the same amount', () {
    final candidates = detector.detect([
      _tx('2026-06-01', 'NETFLIX.COM 123', -15.99),
      _tx('2026-07-01', 'NETFLIX.COM 456', -15.99),
      _tx('2026-08-01', 'NETFLIX.COM 789', -15.99),
    ]);

    expect(candidates, hasLength(1));
    final bill = candidates.single;
    expect(bill.frequency, BillFrequency.monthly);
    // Positive, like Category.billAmountCents elsewhere in the app — a
    // bill's amount is always stored as a magnitude, not a signed delta.
    expect(bill.amountCents, 1599);
    expect(bill.occurrenceCount, 3);
    expect(bill.lastOccurrence, DateTime(2026, 8, 1));
    expect(bill.suggestedNextDueDate, DateTime(2026, 9, 1));
  });

  test('flags a weekly charge repeating for the same amount', () {
    final candidates = detector.detect([
      _tx('2026-08-03', 'GYM WEEKLY CLASS', -20.00),
      _tx('2026-08-10', 'GYM WEEKLY CLASS', -20.00),
      _tx('2026-08-17', 'GYM WEEKLY CLASS', -20.00),
      _tx('2026-08-24', 'GYM WEEKLY CLASS', -20.00),
    ]);

    expect(candidates, hasLength(1));
    expect(candidates.single.frequency, BillFrequency.weekly);
    expect(candidates.single.suggestedNextDueDate, DateTime(2026, 8, 31));
  });

  test('does not flag a one-off transaction', () {
    final candidates = detector.detect([
      _tx('2026-08-03', 'ONE TIME PURCHASE', -50.00),
    ]);

    expect(candidates, isEmpty);
  });

  test('does not flag charges with inconsistent amounts', () {
    final candidates = detector.detect([
      _tx('2026-06-01', 'GROCERY STORE', -42.10),
      _tx('2026-07-01', 'GROCERY STORE', -88.53),
      _tx('2026-08-01', 'GROCERY STORE', -15.20),
    ]);

    expect(candidates, isEmpty);
  });

  test('does not flag charges at irregular intervals', () {
    final candidates = detector.detect([
      _tx('2026-06-01', 'RANDOM SHOP', -20.00),
      _tx('2026-06-05', 'RANDOM SHOP', -20.00),
      _tx('2026-08-20', 'RANDOM SHOP', -20.00),
    ]);

    expect(candidates, isEmpty);
  });

  test('never flags income (positive amounts), even if it recurs', () {
    final candidates = detector.detect([
      _tx('2026-06-15', 'PAYCHECK', 2000.00),
      _tx('2026-07-15', 'PAYCHECK', 2000.00),
      _tx('2026-08-15', 'PAYCHECK', 2000.00),
    ]);

    expect(candidates, isEmpty);
  });

  test('groups charges from the same merchant despite embedded '
      'transaction numbers, and detects multiple distinct bills at once', () {
    final candidates = detector.detect([
      _tx('2026-06-01', 'NETFLIX.COM REF00234', -15.99),
      _tx('2026-07-01', 'NETFLIX.COM REF88213', -15.99),
      _tx('2026-08-01', 'NETFLIX.COM REF10029', -15.99),
      _tx('2026-06-15', 'SPOTIFY USA', -9.99),
      _tx('2026-07-15', 'SPOTIFY USA', -9.99),
      _tx('2026-08-15', 'SPOTIFY USA', -9.99),
      _tx('2026-07-03', 'RANDOM COFFEE SHOP', -4.50),
    ]);

    expect(candidates, hasLength(2));
    expect(candidates.map((c) => c.name), containsAll(['Netflix.com', 'Spotify Usa']));
  });
}
