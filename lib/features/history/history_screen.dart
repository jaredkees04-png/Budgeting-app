import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/utils/category_visuals.dart';
import '../../core/utils/money.dart';
import '../../data/database/daos/transaction_dao.dart';
import '../../data/database/tables/categories_table.dart';
import '../../widgets/empty_state.dart';
import '../transaction_entry/transaction_entry_screen.dart';

/// Every logged transaction, newest first, grouped by day — the place to
/// find and fix a mistake regardless of which week/month the dashboard
/// happens to be showing.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'historyAddTransactionFab',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransactionEntryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'No transactions yet',
              message: 'Everything you log will show up here, newest first.',
            );
          }

          final groups = _groupByDay(transactions);
          return ListView.builder(
            // Extra bottom padding reserves space for the FAB, which
            // floats at a fixed screen position above the scroll content
            // — without it, a transaction scrolled to the bottom of a
            // long history can end up underneath it.
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      _dayLabel(group.date),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                  ...group.entries.map(
                    (entry) => _HistoryTile(entry: entry),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<_DayGroup> _groupByDay(List<TransactionWithCategory> transactions) {
    final groups = <DateTime, List<TransactionWithCategory>>{};
    for (final entry in transactions) {
      final date = entry.transaction.date;
      final day = DateTime(date.year, date.month, date.day);
      groups.putIfAbsent(day, () => []).add(entry);
    }
    return groups.entries
        .map((e) => _DayGroup(date: e.key, entries: e.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _dayLabel(DateTime day) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (_isSameDay(day, today)) return 'Today';
    if (_isSameDay(day, yesterday)) return 'Yesterday';
    return DateFormat.yMMMd().format(day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayGroup {
  final DateTime date;
  final List<TransactionWithCategory> entries;

  const _DayGroup({required this.date, required this.entries});
}

class _HistoryTile extends StatelessWidget {
  final TransactionWithCategory entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final category = entry.category;
    final transaction = entry.transaction;
    final isIncome = category.budgetGroup == BudgetGroup.income;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorFromHex(category.color),
        child: Icon(iconForKey(category.icon), color: Colors.white, size: 20),
      ),
      title: Text(category.name),
      subtitle: transaction.note != null ? Text(transaction.note!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isIncome ? '+' : '-'}${Money.format(transaction.amountCents)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isIncome ? Colors.green.shade700 : null,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionEntryScreen(existing: entry),
          ),
        );
      },
    );
  }
}
