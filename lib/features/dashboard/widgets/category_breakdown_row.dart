import 'package:flutter/material.dart';

import '../../../core/utils/category_visuals.dart';
import '../../../core/utils/money.dart';
import '../../../domain/models/spending_summary.dart';

class CategoryBreakdownRow extends StatelessWidget {
  final CategoryBreakdown breakdown;

  const CategoryBreakdownRow({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final category = breakdown.category;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(iconForKey(category.icon), color: colorFromHex(category.color), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (breakdown.percentOfSpending / 100).clamp(0, 1),
                    minHeight: 4,
                    backgroundColor:
                        colorFromHex(category.color).withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(colorFromHex(category.color)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Money.format(breakdown.totalCents),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${breakdown.percentOfSpending.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
