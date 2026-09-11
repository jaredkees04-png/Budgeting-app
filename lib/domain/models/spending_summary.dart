import '../../data/database/app_database.dart';
import '../../data/database/tables/categories_table.dart' show BudgetGroup;

class CategoryBreakdown {
  final Category category;
  final int totalCents;

  /// Share of income this category's spending represents, 0.0-100.0 (can
  /// exceed 100 if overspent relative to income — that's a real signal,
  /// not a bug). Null when there's no income for the period yet, matching
  /// [BudgetGroupBreakdown.actualPct]'s convention, since "percent of
  /// income" is meaningless with no income to divide by.
  final double? percentOfIncome;

  const CategoryBreakdown({
    required this.category,
    required this.totalCents,
    required this.percentOfIncome,
  });
}

class SpendingSummary {
  final int totalIncomeCents;
  final int totalSpendingCents;
  final List<CategoryBreakdown> byCategory;

  const SpendingSummary({
    required this.totalIncomeCents,
    required this.totalSpendingCents,
    required this.byCategory,
  });

  static const empty = SpendingSummary(
    totalIncomeCents: 0,
    totalSpendingCents: 0,
    byCategory: [],
  );
}

class BudgetGroupBreakdown {
  final BudgetGroup group;
  final int actualCents;

  /// Share of income this group represents, 0.0-100.0.
  /// Null when there's no income for the period (percentages meaningless).
  final double? actualPct;
  final int targetPct;

  const BudgetGroupBreakdown({
    required this.group,
    required this.actualCents,
    required this.actualPct,
    required this.targetPct,
  });
}

class SavingsRecommendation {
  final List<BudgetGroupBreakdown> groups;
  final List<String> suggestions;
  final bool hasIncomeData;

  const SavingsRecommendation({
    required this.groups,
    required this.suggestions,
    required this.hasIncomeData,
  });
}
