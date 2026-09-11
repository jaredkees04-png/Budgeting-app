import 'package:flutter/material.dart';

import '../../core/constants/default_categories.dart';
import '../../core/utils/category_visuals.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/categories_table.dart' show BudgetGroup;

class CategoryEditResult {
  final String name;
  final String icon;
  final String color;
  final BudgetGroup budgetGroup;

  const CategoryEditResult({
    required this.name,
    required this.icon,
    required this.color,
    required this.budgetGroup,
  });
}

/// Add/edit form for a category, shown as a dialog. Used both for
/// creating custom categories and reclassifying/renaming existing ones.
Future<CategoryEditResult?> showCategoryEditDialog(
  BuildContext context, {
  Category? existing,
  Set<String> existingNames = const {},
}) {
  return showDialog<CategoryEditResult>(
    context: context,
    builder: (context) => _CategoryEditDialog(
      existing: existing,
      existingNames: existingNames,
    ),
  );
}

class _CategoryEditDialog extends StatefulWidget {
  final Category? existing;
  final Set<String> existingNames;

  const _CategoryEditDialog({this.existing, this.existingNames = const {}});

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  late final TextEditingController _nameController;
  late String _icon;
  late String _color;
  late BudgetGroup _budgetGroup;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _icon = existing?.icon ?? kCategoryIconOptions.keys.first;
    _color = existing?.color ?? kCategoryColorOptions.first;
    _budgetGroup = existing?.budgetGroup ?? BudgetGroup.needs;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<DefaultCategorySeed> get _availableSuggestions {
    return kSuggestedBillCategories
        .where((s) => !widget.existingNames.contains(s.name.toLowerCase()))
        .toList();
  }

  void _applySuggestion(DefaultCategorySeed suggestion) {
    setState(() {
      _nameController.text = suggestion.name;
      _icon = suggestion.icon;
      _color = suggestion.color;
      _budgetGroup = suggestion.budgetGroup;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<DefaultCategorySeed> suggestions =
        widget.existing == null ? _availableSuggestions : const [];

    return AlertDialog(
      title: Text(widget.existing == null ? 'New category' : 'Edit category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (suggestions.isNotEmpty) ...[
              const Text('Common bills — tap to start from one'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.map((s) {
                  return ActionChip(
                    avatar: Icon(iconForKey(s.icon), size: 16),
                    label: Text(s.name),
                    onPressed: () => _applySuggestion(s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            const Text('Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: kCategoryIconOptions.entries.map((entry) {
                return ChoiceChip(
                  selected: _icon == entry.key,
                  onSelected: (_) => setState(() => _icon = entry.key),
                  avatar: Icon(entry.value, size: 18),
                  label: const SizedBox.shrink(),
                  labelPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: kCategoryColorOptions.map((hex) {
                final color = colorFromHex(hex);
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 16,
                    child: _color == hex
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Counts toward'),
            const SizedBox(height: 8),
            DropdownButton<BudgetGroup>(
              value: _budgetGroup,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: BudgetGroup.income,
                  child: Text('Income'),
                ),
                DropdownMenuItem(
                  value: BudgetGroup.needs,
                  child: Text('Needs (50%)'),
                ),
                DropdownMenuItem(
                  value: BudgetGroup.wants,
                  child: Text('Wants (30%)'),
                ),
                DropdownMenuItem(
                  value: BudgetGroup.savings,
                  child: Text('Savings (20%)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _budgetGroup = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              CategoryEditResult(
                name: name,
                icon: _icon,
                color: _color,
                budgetGroup: _budgetGroup,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
