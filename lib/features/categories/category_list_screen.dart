import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/category_visuals.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/categories_table.dart' show BudgetGroup;
import 'category_edit_dialog.dart';

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
        );
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final result = await showCategoryEditDialog(context, existing: category);
    if (result == null) return;
    final repo = ref.read(categoryRepositoryProvider);
    if (result.name != category.name) {
      await repo.renameCategory(category, result.name);
    }
    if (result.budgetGroup != category.budgetGroup) {
      await repo.reclassifyCategory(category, result.budgetGroup);
    }
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
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
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorFromHex(category.color),
                  child: Icon(iconForKey(category.icon), color: Colors.white),
                ),
                title: Text(category.name),
                subtitle: Text(_groupLabels[category.budgetGroup]!),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCategory(context, ref, category);
                    } else if (value == 'remove') {
                      _archiveCategory(context, ref, category);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (!category.isDefault)
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
