import '../../data/database/tables/categories_table.dart' show BillFrequency;
import '../models/bank_transaction.dart';

/// A recurring charge spotted in an imported bank statement, not yet
/// added as a bill — the review screen shows these and lets the user
/// pick which ones to actually create.
class RecurringBillCandidate {
  final String name;

  /// A positive magnitude, like a category's billAmountCents elsewhere
  /// in the app — bills store an amount, not a signed delta.
  final int amountCents;
  final BillFrequency frequency;
  final DateTime lastOccurrence;
  final DateTime suggestedNextDueDate;
  final int occurrenceCount;

  const RecurringBillCandidate({
    required this.name,
    required this.amountCents,
    required this.frequency,
    required this.lastOccurrence,
    required this.suggestedNextDueDate,
    required this.occurrenceCount,
  });
}

/// Groups a bank statement's charges by merchant and flags the ones that
/// repeat on a roughly weekly or monthly cadence for roughly the same
/// amount — the pattern a subscription or bill leaves behind. This is a
/// heuristic over a handful of months of statement data, not a promise:
/// it's why the review screen asks before adding anything.
class RecurringBillDetector {
  static const _weeklyIntervalRange = (min: 6, max: 8);
  static const _monthlyIntervalRange = (min: 27, max: 33);
  static const _maxIntervalDeviationDays = 4;

  List<RecurringBillCandidate> detect(List<BankTransaction> transactions) {
    // Only charges (money out) can be recurring bills — a recurring
    // deposit is income, not something this feature is about.
    final expenses = transactions.where((t) => t.amountCents < 0).toList();

    final groups = <String, List<BankTransaction>>{};
    for (final tx in expenses) {
      groups.putIfAbsent(_normalize(tx.description), () => []).add(tx);
    }

    final candidates = <RecurringBillCandidate>[];
    for (final txs in groups.values) {
      final candidate = _detectGroup(txs);
      if (candidate != null) candidates.add(candidate);
    }

    candidates.sort((a, b) => b.occurrenceCount.compareTo(a.occurrenceCount));
    return candidates;
  }

  RecurringBillCandidate? _detectGroup(List<BankTransaction> group) {
    if (group.length < 2) return null;
    final txs = [...group]..sort((a, b) => a.date.compareTo(b.date));

    final amounts = txs.map((t) => t.amountCents.abs()).toList();
    final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
    final amountIsConsistent = amounts.every(
      (a) => (a - avgAmount).abs() <= avgAmount * 0.05 + 50,
    );
    if (!amountIsConsistent) return null;

    final intervals = [
      for (var i = 1; i < txs.length; i++)
        txs[i].date.difference(txs[i - 1].date).inDays,
    ];
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    final BillFrequency frequency;
    if (avgInterval >= _weeklyIntervalRange.min &&
        avgInterval <= _weeklyIntervalRange.max) {
      frequency = BillFrequency.weekly;
    } else if (avgInterval >= _monthlyIntervalRange.min &&
        avgInterval <= _monthlyIntervalRange.max) {
      frequency = BillFrequency.monthly;
    } else {
      return null;
    }

    final intervalIsConsistent = intervals.every(
      (i) => (i - avgInterval).abs() <= _maxIntervalDeviationDays,
    );
    if (!intervalIsConsistent) return null;

    final last = txs.last;
    final nextDue = frequency == BillFrequency.weekly
        ? last.date.add(const Duration(days: 7))
        : DateTime(last.date.year, last.date.month + 1, last.date.day);

    return RecurringBillCandidate(
      name: _displayName(last.description),
      amountCents: amounts.last,
      frequency: frequency,
      lastOccurrence: last.date,
      suggestedNextDueDate: nextDue,
      occurrenceCount: txs.length,
    );
  }

  /// Groups by this, not the raw description: bank descriptions often
  /// embed a transaction id, store number, or date that makes otherwise
  /// identical charges from the same merchant look like distinct
  /// descriptions if compared literally.
  String _normalize(String description) {
    var key = description.toUpperCase();
    key = key.replaceAll(RegExp(r'\d+'), '');
    key = key.replaceAll(RegExp(r'[^A-Z\s]'), ' ');
    key = key.replaceAll(RegExp(r'\s+'), ' ').trim();
    return key;
  }

  /// A cleaned-up, title-cased version of the original description (not
  /// the aggressively-stripped normalization key) for a name a user
  /// would actually recognize as their category name. Drops individual
  /// words containing a long digit run — a transaction/reference number
  /// bank descriptions often tack on — while leaving the merchant name
  /// itself (which rarely has 4+ digits in a row) intact.
  String _displayName(String rawDescription) {
    final words = rawDescription.trim().split(RegExp(r'\s+'));
    final meaningfulWords = words.where((w) => !RegExp(r'\d{4,}').hasMatch(w)).toList();
    var cleaned = (meaningfulWords.isEmpty ? words : meaningfulWords).join(' ');
    if (cleaned.length > 40) cleaned = cleaned.substring(0, 40).trim();
    return cleaned
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
