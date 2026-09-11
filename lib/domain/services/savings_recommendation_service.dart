import '../../core/constants/category_guidelines.dart';
import '../../data/database/daos/transaction_dao.dart';
import '../../data/database/tables/categories_table.dart';
import '../models/spending_summary.dart';

/// How many percentage points off-target before we bother surfacing a
/// suggestion. Keeps the recommendations from nagging over noise.
const double _kSuggestionMarginPct = 5.0;

/// Compares actual spending against the 50/30/20 rule of thumb (and a
/// few well-known per-category guidelines) and produces plain-language
/// suggestions. This is general guidance, not personalized financial
/// advice, and is presented to the user as such.
class SavingsRecommendationService {
  SavingsRecommendation buildRecommendation({
    required List<TransactionWithCategory> transactions,
    required int needsTargetPct,
    required int wantsTargetPct,
    required int savingsTargetPct,
  }) {
    int income = 0;
    int needsCents = 0;
    int wantsCents = 0;
    final categoryTotals = <String, int>{};
    final categoryNames = <String, String>{};

    for (final entry in transactions) {
      final category = entry.category;
      final amount = entry.transaction.amountCents;

      if (category.budgetGroup == BudgetGroup.income) {
        income += amount;
        continue;
      }
      if (category.budgetGroup == BudgetGroup.needs) {
        needsCents += amount;
      } else if (category.budgetGroup == BudgetGroup.wants) {
        wantsCents += amount;
      }

      categoryNames[category.id] = category.name;
      categoryTotals.update(
        category.id,
        (existing) => existing + amount,
        ifAbsent: () => amount,
      );
    }

    if (income <= 0) {
      return SavingsRecommendation(
        groups: [
          BudgetGroupBreakdown(
            group: BudgetGroup.needs,
            actualCents: needsCents,
            actualPct: null,
            targetPct: needsTargetPct,
          ),
          BudgetGroupBreakdown(
            group: BudgetGroup.wants,
            actualCents: wantsCents,
            actualPct: null,
            targetPct: wantsTargetPct,
          ),
          BudgetGroupBreakdown(
            group: BudgetGroup.savings,
            actualCents: 0,
            actualPct: null,
            targetPct: savingsTargetPct,
          ),
        ],
        suggestions: const [
          'Add an income transaction to see how your spending compares '
              'to the 50/30/20 guideline.',
        ],
        hasIncomeData: false,
      );
    }

    final savingsCents = income - needsCents - wantsCents;
    final needsPct = needsCents / income * 100;
    final wantsPct = wantsCents / income * 100;
    final savingsPct = savingsCents / income * 100;

    final suggestions = <String>[];
    _addGroupSuggestion(suggestions, 'needs', needsPct, needsTargetPct, higherIsWorse: true);
    _addGroupSuggestion(suggestions, 'wants', wantsPct, wantsTargetPct, higherIsWorse: true);
    _addGroupSuggestion(suggestions, 'savings', savingsPct, savingsTargetPct, higherIsWorse: false);

    for (final id in categoryTotals.keys) {
      final name = categoryNames[id]!;
      final guideline = kCommonCategoryGuidelinesPct[name.toLowerCase()];
      if (guideline == null) continue;
      final actualPct = categoryTotals[id]! / income * 100;
      if (actualPct - guideline > _kSuggestionMarginPct) {
        suggestions.add(
          "You're at ${actualPct.toStringAsFixed(0)}% on $name; a common "
          'guideline is ~${guideline.toStringAsFixed(0)}%.',
        );
      }
    }

    if (suggestions.isEmpty) {
      suggestions.add(
        "You're tracking close to the 50/30/20 guideline this period. Nice work.",
      );
    }

    return SavingsRecommendation(
      groups: [
        BudgetGroupBreakdown(
          group: BudgetGroup.needs,
          actualCents: needsCents,
          actualPct: needsPct,
          targetPct: needsTargetPct,
        ),
        BudgetGroupBreakdown(
          group: BudgetGroup.wants,
          actualCents: wantsCents,
          actualPct: wantsPct,
          targetPct: wantsTargetPct,
        ),
        BudgetGroupBreakdown(
          group: BudgetGroup.savings,
          actualCents: savingsCents,
          actualPct: savingsPct,
          targetPct: savingsTargetPct,
        ),
      ],
      suggestions: suggestions,
      hasIncomeData: true,
    );
  }

  void _addGroupSuggestion(
    List<String> suggestions,
    String label,
    double actualPct,
    int targetPct, {
    required bool higherIsWorse,
  }) {
    final diff = actualPct - targetPct;
    final isOff = higherIsWorse ? diff > _kSuggestionMarginPct : diff < -_kSuggestionMarginPct;
    if (!isOff) return;

    if (higherIsWorse) {
      suggestions.add(
        "You're at ${actualPct.toStringAsFixed(0)}% on $label; a common "
        'guideline is ~$targetPct%.',
      );
    } else {
      suggestions.add(
        "You're saving ${actualPct.toStringAsFixed(0)}% this period; a "
        'common guideline is ~$targetPct%.',
      );
    }
  }
}
