import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/data/database/app_database.dart';
import 'package:budgeting_app/data/database/daos/transaction_dao.dart';
import 'package:budgeting_app/data/database/tables/categories_table.dart';
import 'package:budgeting_app/data/database/tables/transactions_table.dart';
import 'package:budgeting_app/domain/services/spending_breakdown_service.dart';

Category _category(String id, String name, BudgetGroup group) {
  return Category(
    id: id,
    name: name,
    icon: 'category',
    color: '#000000',
    budgetGroup: group,
    isDefault: false,
    isArchived: false,
    sortOrder: 0,
    createdAt: DateTime(2026, 1, 1),
  );
}

TransactionWithCategory _tx(Category category, int cents) {
  return TransactionWithCategory(
    transaction: Transaction(
      id: 't-${category.id}-$cents',
      amountCents: cents,
      categoryId: category.id,
      date: DateTime(2026, 1, 1),
      source: TransactionSource.manual,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    category: category,
  );
}

void main() {
  final service = SpendingBreakdownService();
  final income = _category('income', 'Income', BudgetGroup.income);
  final groceries = _category('groceries', 'Groceries', BudgetGroup.needs);
  final fun = _category('fun', 'Personal/Fun', BudgetGroup.wants);

  test('returns empty summary for no transactions', () {
    final summary = service.summarize([]);
    expect(summary.totalIncomeCents, 0);
    expect(summary.totalSpendingCents, 0);
    expect(summary.byCategory, isEmpty);
  });

  test('excludes income from spending totals and percentages', () {
    final summary = service.summarize([
      _tx(income, 500000),
      _tx(groceries, 30000),
      _tx(fun, 10000),
    ]);

    expect(summary.totalIncomeCents, 500000);
    expect(summary.totalSpendingCents, 40000);
  });

  test('computes correct percentage-of-spending per category', () {
    final summary = service.summarize([
      _tx(groceries, 7500),
      _tx(fun, 2500),
    ]);

    final byName = {for (final b in summary.byCategory) b.category.name: b};
    expect(byName['Groceries']!.percentOfSpending, closeTo(75, 0.01));
    expect(byName['Personal/Fun']!.percentOfSpending, closeTo(25, 0.01));
  });

  test('aggregates multiple transactions in the same category', () {
    final summary = service.summarize([
      _tx(groceries, 1000),
      _tx(groceries, 2000),
    ]);

    expect(summary.byCategory.single.totalCents, 3000);
  });

  test('sorts categories by spend descending', () {
    final summary = service.summarize([
      _tx(fun, 1000),
      _tx(groceries, 5000),
    ]);

    expect(summary.byCategory.first.category.name, 'Groceries');
  });
}
