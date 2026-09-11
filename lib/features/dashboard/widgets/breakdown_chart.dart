import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/category_visuals.dart';
import '../../../domain/models/spending_summary.dart';

/// Each slice's share of the ring is this category's amount over income,
/// with a gray "remaining income" slice filling the rest — so a $1,200
/// rent payment against $4,000 income reads as a small slice of the
/// whole circle, not as 100% of it. fl_chart sizes slices by each
/// section's share of the sum of all section values, so adding that
/// gray section (rather than just labelling percentages differently) is
/// what actually changes the geometry, not just the printed numbers.
///
/// If spending exceeds income there's no "remaining" left to draw, so
/// the ring falls back to showing categories relative to each other
/// (a pie can't exceed a full circle) — the percentage labels still
/// show the true, possibly over-100%, share of income.
class BreakdownChart extends StatelessWidget {
  final SpendingSummary summary;

  const BreakdownChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.totalIncomeCents <= 0) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Log an income transaction to see this breakdown by\nshare of income.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }

    final remaining = summary.totalIncomeCents - summary.totalSpendingCents;
    final outline = Theme.of(context).colorScheme.outline;

    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            ...summary.byCategory.map((entry) {
              final color = colorFromHex(entry.category.color);
              final pct = entry.percentOfIncome ?? 0;
              return PieChartSectionData(
                value: entry.totalCents.toDouble(),
                color: color,
                title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                radius: 60,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }),
            if (remaining > 0)
              PieChartSectionData(
                value: remaining.toDouble(),
                color: outline.withValues(alpha: 0.15),
                title: '',
                radius: 60,
                showTitle: false,
              ),
          ],
        ),
      ),
    );
  }
}
