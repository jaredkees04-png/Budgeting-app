import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/data/database/app_database.dart';
import 'package:budgeting_app/data/database/daos/transaction_dao.dart';
import 'package:budgeting_app/data/database/tables/categories_table.dart';
import 'package:budgeting_app/data/database/tables/transactions_table.dart';
import 'package:budgeting_app/domain/services/savings_recommendation_service.dart';

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
      id: 't-${category.id}-$cents-${DateTime.now().microsecondsSinceEpoch}',
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
  final service = SavingsRecommendationService();
  final income = _category('income', 'Income', BudgetGroup.income);
  final groceries = _category('groceries', 'Groceries', BudgetGroup.needs);
  final rent = _category('rent', 'Rent/Mortgage', BudgetGroup.needs);
  final fun = _category('fun', 'Personal/Fun', BudgetGroup.wants);

  test('reports no income data when there is no income', () {
    final result = service.buildRecommendation(
      transactions: [_tx(groceries, 1000)],
      needsTargetPct: 50,
      wantsTargetPct: 30,
      savingsTargetPct: 20,
    );

    expect(result.hasIncomeData, isFalse);
    expect(result.suggestions, isNotEmpty);
  });

  test('computes group percentages relative to income', () {
    final result = service.buildRecommendation(
      transactions: [
        _tx(income, 100000), // $1000 income
        _tx(groceries, 50000), // 50% -> needs
        _tx(fun, 30000), // 30% -> wants
      ],
      needsTargetPct: 50,
      wantsTargetPct: 30,
      savingsTargetPct: 20,
    );

    expect(result.hasIncomeData, isTrue);
    final needs = result.groups.firstWhere((g) => g.group == BudgetGroup.needs);
    final wants = result.groups.firstWhere((g) => g.group == BudgetGroup.wants);
    final savings =
        result.groups.firstWhere((g) => g.group == BudgetGroup.savings);

    expect(needs.actualPct, closeTo(50, 0.01));
    expect(wants.actualPct, closeTo(30, 0.01));
    expect(savings.actualPct, closeTo(20, 0.01));
  });

  test('surfaces a suggestion when a group is well over its target', () {
    final result = service.buildRecommendation(
      transactions: [
        _tx(income, 100000),
        _tx(groceries, 60000), // 60% needs vs 50% target -> over margin
      ],
      needsTargetPct: 50,
      wantsTargetPct: 30,
      savingsTargetPct: 20,
    );

    expect(
      result.suggestions.any((s) => s.contains('needs')),
      isTrue,
      reason: 'Expected a needs-related suggestion, got: ${result.suggestions}',
    );
  });

  test('surfaces the worked example: groceries far above its guideline', () {
    final result = service.buildRecommendation(
      transactions: [
        _tx(income, 100000),
        _tx(groceries, 35000), // 35% of income on groceries vs ~15% guideline
      ],
      needsTargetPct: 50,
      wantsTargetPct: 30,
      savingsTargetPct: 20,
    );

    expect(
      result.suggestions.any(
        (s) => s.contains('35%') && s.contains('Groceries') && s.contains('15%'),
      ),
      isTrue,
      reason: 'suggestions were: ${result.suggestions}',
    );
  });

  test('does not nag when spending is within the suggestion margin', () {
    final result = service.buildRecommendation(
      transactions: [
        _tx(income, 100000),
        _tx(rent, 27000),
        _tx(groceries, 20000),
        _tx(fun, 30000),
      ],
      needsTargetPct: 50,
      wantsTargetPct: 30,
      savingsTargetPct: 20,
    );

    expect(result.suggestions, ['You\'re tracking close to the 50/30/20 guideline this period. Nice work.']);
  });

  test('surfaces a per-category suggestion for rent/mortgage over its guideline', () {
    final result = service.buildRecommendation(
      transactions: [
        _tx(income, 100000),
        _tx(rent, 40000), // 40% of income on rent vs ~28% guideline
      ],
      needsTargetPct: 50,
      wantsTargetPct: 30,
      savingsTargetPct: 20,
    );

    expect(
      result.suggestions.any(
        (s) => s.contains('40%') && s.contains('Rent/Mortgage') && s.contains('28%'),
      ),
      isTrue,
      reason: 'suggestions were: ${result.suggestions}',
    );
  });
}
