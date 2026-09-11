import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/utils/money.dart';
import '../../data/database/daos/transaction_dao.dart';
import '../../widgets/amount_input.dart';
import '../../widgets/category_picker.dart';

/// Manual transaction entry — the primary, always-available way to log
/// spending or income. Kept to one screen with no required fields beyond
/// amount and category, so logging a transaction takes a few seconds.
///
/// Doubles as the edit screen: pass [existing] to prefill the form and
/// switch the save button to updating that transaction, with a delete
/// option in the app bar.
class TransactionEntryScreen extends ConsumerStatefulWidget {
  final TransactionWithCategory? existing;

  const TransactionEntryScreen({super.key, this.existing});

  @override
  ConsumerState<TransactionEntryScreen> createState() =>
      _TransactionEntryScreenState();
}

class _TransactionEntryScreenState
    extends ConsumerState<TransactionEntryScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String? _amountError;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing?.transaction;
    if (existing != null) {
      _amountController.text = Money.formatPlain(existing.amountCents);
      _noteController.text = existing.note ?? '';
      _selectedCategoryId = existing.categoryId;
      _selectedDate = existing.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final cents = Money.parseToCents(_amountController.text);
    if (cents == null || cents <= 0) {
      setState(() => _amountError = 'Enter an amount greater than \$0');
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a category')),
      );
      return;
    }

    setState(() => _saving = true);
    final note =
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    final repo = ref.read(transactionRepositoryProvider);
    if (_isEditing) {
      await repo.updateTransaction(
        widget.existing!.transaction,
        amountCents: cents,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: note,
      );
    } else {
      await repo.addTransaction(
        amountCents: cents,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: note,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This can\'t be undone.'),
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
    if (confirmed != true) return;

    await ref
        .read(transactionRepositoryProvider)
        .deleteTransaction(widget.existing!.transaction.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit transaction' : 'Add transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (categories) {
          _selectedCategoryId ??=
              categories.isNotEmpty ? categories.first.id : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AmountInput(
                  controller: _amountController,
                  errorText: _amountError,
                ),
                const SizedBox(height: 24),
                Text('Category', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                CategoryPicker(
                  categories: categories,
                  selectedCategoryId: _selectedCategoryId,
                  onSelected: (id) => setState(() => _selectedCategoryId = id),
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(DateFormat.yMMMd().format(_selectedDate)),
                  trailing: TextButton(
                    onPressed: _pickDate,
                    child: const Text('Change'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save changes' : 'Save transaction'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
