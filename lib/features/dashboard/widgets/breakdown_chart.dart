import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/category_visuals.dart';
import '../../../domain/models/spending_summary.dart';

class BreakdownChart extends StatelessWidget {
  final List<CategoryBreakdown> breakdown;

  const BreakdownChart({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: breakdown.map((entry) {
            final color = colorFromHex(entry.category.color);
            return PieChartSectionData(
              value: entry.totalCents.toDouble(),
              color: color,
              title: entry.percentOfSpending >= 8
                  ? '${entry.percentOfSpending.toStringAsFixed(0)}%'
                  : '',
              radius: 60,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
