import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/utils/date_period.dart';
import '../../core/utils/money.dart';
import '../../widgets/empty_state.dart';
import '../recommendations/recommendation_card.dart';
import '../settings/settings_screen.dart';
import '../transaction_entry/transaction_entry_screen.dart';
import 'widgets/breakdown_chart.dart';
import 'widgets/category_breakdown_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _shiftAnchor(WidgetRef ref, int direction) {
    final type = ref.read(selectedPeriodTypeProvider);
    final anchor = ref.read(selectedAnchorDateProvider);
    final next = type == PeriodType.week
        ? anchor.add(Duration(days: 7 * direction))
        : DateTime(anchor.year, anchor.month + direction, 1);
    ref.read(selectedAnchorDateProvider.notifier).state = next;
  }

  String _rangeLabel(PeriodType type, DateRange range) {
    if (type == PeriodType.month) {
      return DateFormat.yMMMM().format(range.start);
    }
    final end = range.end.subtract(const Duration(days: 1));
    return '${DateFormat.MMMd().format(range.start)} - ${DateFormat.MMMd().format(end)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodType = ref.watch(selectedPeriodTypeProvider);
    final range = ref.watch(selectedDateRangeProvider);
    final summaryAsync = ref.watch(spendingSummaryProvider);
    final recommendationAsync = ref.watch(savingsRecommendationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        actions: [
          SegmentedButton<PeriodType>(
            segments: const [
              ButtonSegment(value: PeriodType.week, label: Text('Week')),
              ButtonSegment(value: PeriodType.month, label: Text('Month')),
            ],
            selected: {periodType},
            onSelectionChanged: (selection) {
              ref.read(selectedPeriodTypeProvider.notifier).state =
                  selection.first;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboardAddTransactionFab',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransactionEntryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          // Extra bottom padding reserves space for the FAB, which floats
          // at a fixed screen position above the scroll content — without
          // it, content scrolled to the bottom can end up underneath it.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftAnchor(ref, -1),
                ),
                Text(
                  _rangeLabel(periodType, range),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftAnchor(ref, 1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $err'),
              ),
              data: (summary) {
                if (summary.byCategory.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions yet',
                    message:
                        'Tap the + button to log your first expense or income for this period.',
                  );
                }
                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _TotalStat(
                                  label: 'Income',
                                  amountCents: summary.totalIncomeCents,
                                ),
                                _TotalStat(
                                  label: 'Spent',
                                  amountCents: summary.totalSpendingCents,
                                ),
                                _TotalStat(
                                  label: 'Remaining',
                                  amountCents: summary.remainingCents,
                                  valueColor: summary.remainingCents < 0
                                      ? Theme.of(context).colorScheme.error
                                      : Colors.green.shade700,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            BreakdownChart(summary: summary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: summary.byCategory
                              .map((b) => CategoryBreakdownRow(breakdown: b))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            recommendationAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, _) => Text('Error: $err'),
              data: (recommendation) =>
                  RecommendationCard(recommendation: recommendation),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalStat extends StatelessWidget {
  final String label;
  final int amountCents;
  final Color? valueColor;

  const _TotalStat({
    required this.label,
    required this.amountCents,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          Money.format(amountCents),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
