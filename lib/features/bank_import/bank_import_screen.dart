import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/utils/category_visuals.dart';
import '../../core/utils/csv_io/csv_io.dart';
import '../../core/utils/money.dart';
import '../../data/database/tables/categories_table.dart'
    show BudgetGroup, BillFrequency;
import '../../domain/services/bank_statement_parser.dart';
import '../../domain/services/recurring_bill_detector.dart';

/// Imports a bank statement CSV, looks for charges that repeat on a
/// weekly or monthly cadence for a consistent amount, and lets the user
/// pick which of those to add as recurring bills. Nothing here ever
/// leaves the device — parsing and detection both run locally in Dart,
/// the same as everything else in this app.
class BankImportScreen extends ConsumerStatefulWidget {
  const BankImportScreen({super.key});

  @override
  ConsumerState<BankImportScreen> createState() => _BankImportScreenState();
}

class _BankImportScreenState extends ConsumerState<BankImportScreen> {
  List<RecurringBillCandidate>? _candidates;
  final Set<int> _selected = {};
  String? _error;
  bool _loading = false;
  bool _adding = false;
  int _skippedRowCount = 0;

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await pickCsvFile();
      if (content == null) {
        setState(() => _loading = false);
        return;
      }
      final parsed = BankStatementParser().parse(content);
      final candidates = RecurringBillDetector().detect(parsed.transactions);
      setState(() {
        _candidates = candidates;
        _selected
          ..clear()
          ..addAll(List.generate(candidates.length, (i) => i));
        _skippedRowCount = parsed.skippedRowCount;
        _loading = false;
      });
    } on FormatException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong reading that file: $e';
        _loading = false;
      });
    }
  }

  Future<void> _addSelected() async {
    final candidates = _candidates;
    if (candidates == null || _selected.isEmpty) return;

    setState(() => _adding = true);
    final repo = ref.read(categoryRepositoryProvider);
    var addedCount = 0;
    for (var i = 0; i < candidates.length; i++) {
      if (!_selected.contains(i)) continue;
      final candidate = candidates[i];
      await repo.createCategory(
        name: candidate.name,
        icon: 'receipt_long',
        color: kCategoryColorOptions[addedCount % kCategoryColorOptions.length],
        budgetGroup: BudgetGroup.needs,
        isRecurring: true,
        billFrequency: candidate.frequency,
        billAmountCents: candidate.amountCents,
        nextDueDate: candidate.suggestedNextDueDate,
      );
      addedCount++;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added $addedCount bill${addedCount == 1 ? '' : 's'} — you can '
          'rename, recolor, or reclassify any of them from the Bills tab.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from bank statement')),
      body: _buildBody(context),
      bottomNavigationBar: (_candidates != null && _candidates!.isNotEmpty)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: (_selected.isEmpty || _adding) ? null : _addSelected,
                  child: _adding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _selected.isEmpty
                              ? 'Select bills to add'
                              : 'Add ${_selected.length} bill${_selected.length == 1 ? '' : 's'}',
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    final candidates = _candidates;

    if (candidates == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Export a statement (CSV) from your bank\'s website and '
                'choose it here. It\'s scanned for recurring charges on '
                'your own device — nothing is uploaded anywhere.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loading ? null : _pickFile,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: const Text('Choose CSV file'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (candidates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No recurring charges found in that statement.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => setState(() => _candidates = null),
                child: const Text('Try another file'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (_skippedRowCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Couldn\'t read $_skippedRowCount row${_skippedRowCount == 1 ? '' : 's'} '
              'in that file — the rest looked fine.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Found ${candidates.length} recurring charge${candidates.length == 1 ? '' : 's'} '
            '— pick which to add as bills:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...List.generate(candidates.length, (index) {
          final candidate = candidates[index];
          return CheckboxListTile(
            value: _selected.contains(index),
            onChanged: (checked) {
              setState(() {
                if (checked ?? false) {
                  _selected.add(index);
                } else {
                  _selected.remove(index);
                }
              });
            },
            title: Text(candidate.name),
            subtitle: Text(
              '${candidate.frequency == BillFrequency.weekly ? 'Weekly' : 'Monthly'} · '
              'seen ${candidate.occurrenceCount} times · '
              'next due ~${DateFormat.yMMMd().format(candidate.suggestedNextDueDate)}',
            ),
            secondary: Text(
              Money.format(candidate.amountCents),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }),
      ],
    );
  }
}
