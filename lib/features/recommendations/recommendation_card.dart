import 'package:flutter/material.dart';

import '../../data/database/tables/categories_table.dart';
import '../../domain/models/spending_summary.dart';

class RecommendationCard extends StatelessWidget {
  final SavingsRecommendation recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  static const _groupLabels = {
    BudgetGroup.needs: 'Needs',
    BudgetGroup.wants: 'Wants',
    BudgetGroup.savings: 'Savings',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('50/30/20 guideline', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (recommendation.hasIncomeData)
              ...recommendation.groups
                  .where((g) => g.group != BudgetGroup.income)
                  .map((g) => _GroupBar(
                        label: _groupLabels[g.group] ?? g.group.name,
                        actualPct: g.actualPct ?? 0,
                        targetPct: g.targetPct,
                      )),
            const SizedBox(height: 8),
            ...recommendation.suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(s, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A general rule of thumb, not personalized financial advice.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupBar extends StatelessWidget {
  final String label;
  final double actualPct;
  final int targetPct;

  const _GroupBar({
    required this.label,
    required this.actualPct,
    required this.targetPct,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final over = actualPct > targetPct + 5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(label, style: theme.textTheme.bodyMedium)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (actualPct / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  over ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              '${actualPct.toStringAsFixed(0)}% / ~$targetPct%',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
