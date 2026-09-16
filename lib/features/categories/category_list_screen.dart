import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/category_visuals.dart';
import '../../core/utils/money.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/categories_table.dart' show BudgetGroup;
import 'category_edit_dialog.dart';

/// Manages categories, and doubles as "Bills": any category — built-in
/// or custom — can be switched into a recurring bill (an amount, a
/// frequency, a due date) since a bill and its category are always 1:1
/// anyway. Recurring ones show their due date and a "Mark as paid"
/// action right in this same list instead of living on a second tab.
class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  static const _groupLabels = {
    BudgetGroup.income: 'Income',
    BudgetGroup.needs: 'Needs',
    BudgetGroup.wants: 'Wants',
    BudgetGroup.savings: 'Savings',
  };

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final existingNames = (ref.read(activeCategoriesProvider).value ?? [])
        .map((c) => c.name.toLowerCase())
        .toSet();
    final result = await showCategoryEditDialog(
      context,
      existingNames: existingNames,
    );
    if (result == null) return;
    await ref.read(categoryRepositoryProvider).createCategory(
          name: result.name,
          icon: result.icon,
          color: result.color,
          budgetGroup: result.budgetGroup,
          isRecurring: result.isRecurring,
          billFrequency: result.billFrequency,
          billAmountCents: result.billAmountCents,
          nextDueDate: result.nextDueDate,
        );
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final result = await showCategoryEditDialog(context, existing: category);
    if (result == null) return;
    await ref.read(categoryRepositoryProvider).updateCategory(
          category,
          name: result.name,
          icon: result.icon,
          color: result.color,
          budgetGroup: result.budgetGroup,
          isRecurring: result.isRecurring,
          billFrequency: result.billFrequency,
          billAmountCents: result.billAmountCents,
          nextDueDate: result.nextDueDate,
        );
  }

  Future<void> _archiveCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove category?'),
        content: Text(
          '"${category.name}" will be hidden, but past transactions in it '
          'are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoryRepositoryProvider).archiveCategory(category.id);
    }
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    await ref.read(categoryRepositoryProvider).markBillPaid(category);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked "${category.name}" as paid')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bills')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCategoryFab',
        onPressed: () => _addCategory(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (categories) {
          return ListView.builder(
            // Extra bottom padding reserves space for the FAB, which
            // floats at a fixed screen position above the scroll content
            // — without it, a category scrolled to the bottom of a long
            // list can end up underneath it, right where its own "mark as
            // paid"/edit menu would be tapped.
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTile(
                category: category,
                onTap: () => _editCategory(context, ref, category),
                onMarkPaid: () => _markPaid(context, ref, category),
                onArchive: () => _archiveCategory(context, ref, category),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onMarkPaid;
  final VoidCallback onArchive;

  const _CategoryTile({
    required this.category,
    required this.onTap,
    required this.onMarkPaid,
    required this.onArchive,
  });

  ({String label, Color? color}) _dueStatus(BuildContext context) {
    final theme = Theme.of(context);
    final due = category.nextDueDate!;
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);
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
    final isRecurring = category.isRecurring;
    final subtitle = isRecurring
        ? _dueStatus(context)
        : (label: CategoryListScreen._groupLabels[category.budgetGroup]!, color: null);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: colorFromHex(category.color),
        child: Icon(iconForKey(category.icon), color: Colors.white),
      ),
      title: Text(category.name),
      subtitle: Text(subtitle.label, style: TextStyle(color: subtitle.color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRecurring)
            Text(
              Money.format(category.billAmountCents!),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onTap();
              if (value == 'paid') onMarkPaid();
              if (value == 'remove') onArchive();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (isRecurring)
                const PopupMenuItem(value: 'paid', child: Text('Mark as paid')),
              if (!category.isDefault)
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }
}
