import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/domain/services/bank_statement_parser.dart';

void main() {
  final parser = BankStatementParser();

  test('parses a standard single-amount-column CSV', () {
    const csv = '''
Date,Description,Amount
09/01/2026,NETFLIX.COM,-15.99
09/02/2026,PAYCHECK DEPOSIT,2000.00
''';
    final result = parser.parse(csv);

    expect(result.transactions, hasLength(2));
    expect(result.skippedRowCount, 0);
    expect(result.transactions[0].date, DateTime(2026, 9, 1));
    expect(result.transactions[0].description, 'NETFLIX.COM');
    expect(result.transactions[0].amountCents, -1599);
    expect(result.transactions[1].amountCents, 200000);
  });

  test('parses separate debit/credit columns', () {
    const csv = '''
Date,Description,Debit,Credit
09/01/2026,NETFLIX.COM,15.99,
09/02/2026,PAYCHECK DEPOSIT,,2000.00
''';
    final result = parser.parse(csv);

    expect(result.transactions, hasLength(2));
    expect(result.transactions[0].amountCents, -1599);
    expect(result.transactions[1].amountCents, 200000);
  });

  test('handles currency symbols, thousands separators, and parentheses '
      'as negative', () {
    const csv = '''
Date,Description,Amount
09/01/2026,BIG PURCHASE,"\$1,234.56"
09/02/2026,REFUND ADJUSTMENT,(42.00)
''';
    final result = parser.parse(csv);

    expect(result.transactions[0].amountCents, 123456);
    expect(result.transactions[1].amountCents, -4200);
  });

  test('matches headers case-insensitively and in any column order', () {
    const csv = '''
AMOUNT,DESCRIPTION,DATE
-9.99,SPOTIFY,2026-09-01
''';
    final result = parser.parse(csv);

    expect(result.transactions, hasLength(1));
    expect(result.transactions.single.description, 'SPOTIFY');
    expect(result.transactions.single.date, DateTime(2026, 9, 1));
  });

  test('skips rows with an unparseable date or amount instead of failing '
      'the whole import', () {
    const csv = '''
Date,Description,Amount
not-a-date,SOMETHING,-5.00
09/01/2026,MISSING AMOUNT,
09/02/2026,GOOD ROW,-12.00
''';
    final result = parser.parse(csv);

    expect(result.transactions, hasLength(1));
    expect(result.transactions.single.description, 'GOOD ROW');
    expect(result.skippedRowCount, 2);
  });

  test('throws when no data rows are present', () {
    const csv = 'Date,Description,Amount\n';
    expect(() => parser.parse(csv), throwsFormatException);
  });

  test('throws when the columns can\'t be recognized at all', () {
    const csv = '''
Foo,Bar,Baz
1,2,3
''';
    expect(() => parser.parse(csv), throwsFormatException);
  });
}
