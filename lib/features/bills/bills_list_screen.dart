import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/category_visuals.dart';
import '../../core/utils/money.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/recurring_bill_dao.dart';
import '../../widgets/empty_state.dart';
import 'bill_edit_dialog.dart';

class BillsListScreen extends ConsumerWidget {
  const BillsListScreen({super.key});

  Future<void> _addBill(BuildContext context, WidgetRef ref) async {
    final categories = ref.read(activeCategoriesProvider).value ?? [];
    if (categories.isEmpty) return;
    final result = await showBillEditDialog(context, categories: categories);
    if (result == null) return;
    await ref.read(recurringBillRepositoryProvider).createBill(
          name: result.name,
          amountCents: result.amountCents,
          categoryId: result.categoryId,
          frequency: result.frequency,
          nextDueDate: result.nextDueDate,
        );
  }

  Future<void> _editBill(
    BuildContext context,
    WidgetRef ref,
    RecurringBill bill,
  ) async {
    final categories = ref.read(activeCategoriesProvider).value ?? [];
    final result = await showBillEditDialog(
      context,
      categories: categories,
      existing: bill,
    );
    if (result == null) return;
    await ref.read(recurringBillRepositoryProvider).updateBill(
          bill,
          name: result.name,
          amountCents: result.amountCents,
          categoryId: result.categoryId,
          frequency: result.frequency,
          nextDueDate: result.nextDueDate,
        );
  }

  Future<void> _deleteBill(
    BuildContext context,
    WidgetRef ref,
    RecurringBill bill,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text('"${bill.name}" will be removed. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(recurringBillRepositoryProvider).deleteBill(bill.id);
    }
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    RecurringBill bill,
  ) async {
    await ref.read(recurringBillRepositoryProvider).markPaid(bill);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked "${bill.name}" as paid')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(activeBillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bills')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addBillFab',
        onPressed: () => _addBill(context, ref),
        child: const Icon(Icons.add),
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (bills) {
          if (bills.isEmpty) {
            return const EmptyState(
              icon: Icons.event_repeat_outlined,
              title: 'No recurring bills yet',
              message:
                  'Tap the + button to add a bill like rent or a '
                  'subscription so you can track when it\'s due.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final entry = bills[index];
              return _BillTile(
                entry: entry,
                onTap: () => _editBill(context, ref, entry.bill),
                onMarkPaid: () => _markPaid(context, ref, entry.bill),
                onDelete: () => _deleteBill(context, ref, entry.bill),
              );
            },
          );
        },
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  final RecurringBillWithCategory entry;
  final VoidCallback onTap;
  final VoidCallback onMarkPaid;
  final VoidCallback onDelete;

  const _BillTile({
    required this.entry,
    required this.onTap,
    required this.onMarkPaid,
    required this.onDelete,
  });

  ({String label, Color? color}) _dueStatus(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);
    final due = entry.bill.nextDueDate;
    final due0 = DateTime(due.year, due.month, due.day);
    final diff = due0.difference(today0).inDays;

    if (diff < 0) {
      return (label: 'Overdue by ${-diff}d', color: theme.colorScheme.error);
    }
    if (diff == 0) {
      return (label: 'Due today', color: theme.colorScheme.primary);
    }
    return (label: 'Due in ${diff}d', color: null);
  }

  @override
  Widget build(BuildContext context) {
    final category = entry.category;
    final status = _dueStatus(context);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: colorFromHex(category.color),
        child: Icon(iconForKey(category.icon), color: Colors.white),
      ),
      title: Text(entry.bill.name),
      subtitle: Text(status.label, style: TextStyle(color: status.color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Money.format(entry.bill.amountCents),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'paid') onMarkPaid();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'paid', child: Text('Mark as paid')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
