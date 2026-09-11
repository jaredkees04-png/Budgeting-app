import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/default_categories.dart';
import '../../core/utils/category_visuals.dart';
import '../../core/utils/money.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/categories_table.dart'
    show BudgetGroup, BillFrequency;

class CategoryEditResult {
  final String name;
  final String icon;
  final String color;
  final BudgetGroup budgetGroup;
  final bool isRecurring;
  final BillFrequency? billFrequency;
  final int? billAmountCents;
  final DateTime? nextDueDate;

  const CategoryEditResult({
    required this.name,
    required this.icon,
    required this.color,
    required this.budgetGroup,
    required this.isRecurring,
    this.billFrequency,
    this.billAmountCents,
    this.nextDueDate,
  });
}

/// Add/edit form for a category, shown as a dialog. Used both for
/// creating custom categories and editing existing ones — including
/// turning any category, built-in or custom, into a recurring bill.
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
  late final TextEditingController _amountController;
  late String _icon;
  late String _color;
  late BudgetGroup _budgetGroup;
  late bool _isRecurring;
  late BillFrequency _frequency;
  late DateTime _nextDueDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _amountController = TextEditingController(
      text: existing?.billAmountCents != null
          ? Money.formatPlain(existing!.billAmountCents!)
          : '',
    );
    _icon = existing?.icon ?? kCategoryIconOptions.keys.first;
    _color = existing?.color ?? kCategoryColorOptions.first;
    _budgetGroup = existing?.budgetGroup ?? BudgetGroup.needs;
    _isRecurring = existing?.isRecurring ?? false;
    _frequency = existing?.billFrequency ?? BillFrequency.monthly;
    _nextDueDate = existing?.nextDueDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<DefaultCategorySeed> _available(List<DefaultCategorySeed> seeds) {
    return seeds
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

  Widget _suggestionWrap(List<DefaultCategorySeed> seeds) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: seeds.map((s) {
        return ActionChip(
          avatar: Icon(iconForKey(s.icon), size: 16),
          label: Text(s.name),
          onPressed: () => _applySuggestion(s),
        );
      }).toList(),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _nextDueDate = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    int? amountCents;
    if (_isRecurring) {
      amountCents = Money.parseToCents(_amountController.text);
      if (amountCents == null || amountCents <= 0) {
        setState(() => _error = 'Enter a bill amount greater than \$0');
        return;
      }
    }

    Navigator.of(context).pop(
      CategoryEditResult(
        name: name,
        icon: _icon,
        color: _color,
        budgetGroup: _budgetGroup,
        isRecurring: _isRecurring,
        billFrequency: _isRecurring ? _frequency : null,
        billAmountCents: amountCents,
        nextDueDate: _isRecurring ? _nextDueDate : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    final List<DefaultCategorySeed> billSuggestions =
        isNew ? _available(kSuggestedBillCategories) : const [];
    final List<DefaultCategorySeed> everydaySuggestions =
        isNew ? _available(kSuggestedEverydayCategories) : const [];

    return AlertDialog(
      title: Text(isNew ? 'New category' : 'Edit category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (billSuggestions.isNotEmpty) ...[
              const Text('Bills — tap to start from one'),
              const SizedBox(height: 8),
              _suggestionWrap(billSuggestions),
              const SizedBox(height: 16),
            ],
            if (everydaySuggestions.isNotEmpty) ...[
              const Text('Everyday spending — tap to start from one'),
              const SizedBox(height: 8),
              _suggestionWrap(everydaySuggestions),
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
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recurring bill'),
              subtitle: const Text('Track a due date and get reminded to log it'),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Bill amount',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Repeats'),
              const SizedBox(height: 8),
              SegmentedButton<BillFrequency>(
                segments: const [
                  ButtonSegment(
                    value: BillFrequency.weekly,
                    label: Text('Weekly'),
                  ),
                  ButtonSegment(
                    value: BillFrequency.monthly,
                    label: Text('Monthly'),
                  ),
                ],
                selected: {_frequency},
                onSelectionChanged: (selection) =>
                    setState(() => _frequency = selection.first),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Next due'),
                subtitle: Text(DateFormat.yMMMd().format(_nextDueDate)),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change'),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
