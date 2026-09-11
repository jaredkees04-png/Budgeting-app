import '../../data/database/app_database.dart';
import '../../data/database/daos/transaction_dao.dart';
import '../../data/database/tables/categories_table.dart' show BudgetGroup;
import '../models/spending_summary.dart';

/// Pure logic for turning a list of transactions into totals and
/// per-category percentages. No database or widget dependencies, so
/// it's trivial to unit test.
class SpendingBreakdownService {
  SpendingSummary summarize(List<TransactionWithCategory> transactions) {
    if (transactions.isEmpty) return SpendingSummary.empty;

    int totalIncome = 0;
    int totalSpending = 0;
    final totalsByCategory = <String, int>{};
    final categoriesById = <String, Category>{};

    for (final entry in transactions) {
      final category = entry.category;
      categoriesById[category.id] = category;
      final amount = entry.transaction.amountCents;

      if (category.budgetGroup == BudgetGroup.income) {
        totalIncome += amount;
      } else {
        totalSpending += amount;
        totalsByCategory.update(
          category.id,
          (existing) => existing + amount,
          ifAbsent: () => amount,
        );
      }
    }

    final byCategory = totalsByCategory.entries.map((entry) {
      final category = categoriesById[entry.key]!;
      final pct = totalSpending == 0 ? 0.0 : (entry.value / totalSpending) * 100;
      return CategoryBreakdown(
        category: category,
        totalCents: entry.value,
        percentOfSpending: pct,
      );
    }).toList()
      ..sort((a, b) => b.totalCents.compareTo(a.totalCents));

    return SpendingSummary(
      totalIncomeCents: totalIncome,
      totalSpendingCents: totalSpending,
      byCategory: byCategory,
    );
  }
}
