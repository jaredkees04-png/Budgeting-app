import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/money.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/recurring_bills_table.dart';
import '../../widgets/category_picker.dart';

class BillEditResult {
  final String name;
  final int amountCents;
  final String categoryId;
  final BillFrequency frequency;
  final DateTime nextDueDate;

  const BillEditResult({
    required this.name,
    required this.amountCents,
    required this.categoryId,
    required this.frequency,
    required this.nextDueDate,
  });
}

/// Add/edit form for a recurring bill, shown as a dialog — mirrors
/// [showCategoryEditDialog]'s shape so the two feel consistent.
Future<BillEditResult?> showBillEditDialog(
  BuildContext context, {
  required List<Category> categories,
  RecurringBill? existing,
}) {
  return showDialog<BillEditResult>(
    context: context,
    builder: (context) =>
        _BillEditDialog(categories: categories, existing: existing),
  );
}

class _BillEditDialog extends StatefulWidget {
  final List<Category> categories;
  final RecurringBill? existing;

  const _BillEditDialog({required this.categories, this.existing});

  @override
  State<_BillEditDialog> createState() => _BillEditDialogState();
}

class _BillEditDialogState extends State<_BillEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  String? _categoryId;
  late BillFrequency _frequency;
  late DateTime _nextDueDate;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _amountController = TextEditingController(
      text: existing != null ? Money.formatPlain(existing.amountCents) : '',
    );
    _categoryId = existing?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _frequency = existing?.frequency ?? BillFrequency.monthly;
    _nextDueDate = existing?.nextDueDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
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
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    final cents = Money.parseToCents(_amountController.text);
    if (cents == null || cents <= 0) {
      setState(() => _error = 'Enter an amount greater than \$0');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Choose a category');
      return;
    }
    Navigator.of(context).pop(
      BillEditResult(
        name: name,
        amountCents: cents,
        categoryId: _categoryId!,
        frequency: _frequency,
        nextDueDate: _nextDueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit bill' : 'New recurring bill'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Category'),
            const SizedBox(height: 8),
            CategoryPicker(
              categories: widget.categories,
              selectedCategoryId: _categoryId,
              onSelected: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 16),
            const Text('Repeats'),
            const SizedBox(height: 8),
            SegmentedButton<BillFrequency>(
              segments: const [
                ButtonSegment(value: BillFrequency.weekly, label: Text('Weekly')),
                ButtonSegment(value: BillFrequency.monthly, label: Text('Monthly')),
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
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Save changes' : 'Save'),
        ),
      ],
    );
  }
}
