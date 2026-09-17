import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../models/bank_transaction.dart';

/// Parses a bank-exported CSV statement into [BankTransaction]s.
///
/// Every bank formats its export differently, so this doesn't target one
/// specific bank — it looks for common header names (case-insensitively)
/// and tries a handful of common date formats, skipping any row it can't
/// make sense of rather than failing the whole import over one bad line.
/// [ParsedStatement.skippedRowCount] tells the caller how much was
/// dropped, so the UI can be honest about it rather than silently losing
/// rows.
class BankStatementParser {
  static const _dateHeaders = [
    'date',
    'transaction date',
    'posted date',
    'trans date',
  ];
  static const _descriptionHeaders = [
    'description',
    'payee',
    'memo',
    'name',
    'merchant',
    'transaction description',
  ];
  static const _amountHeaders = ['amount', 'transaction amount'];
  static const _debitHeaders = ['debit', 'withdrawal', 'withdrawals'];
  static const _creditHeaders = ['credit', 'deposit', 'deposits'];

  static final _dateFormats = [
    DateFormat('M/d/yyyy'),
    DateFormat('MM/dd/yyyy'),
    DateFormat('yyyy-MM-dd'),
    DateFormat('M/d/yy'),
    DateFormat('MM/dd/yy'),
  ];

  ParsedStatement parse(String csvContent) {
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvContent.trim());

    if (rows.length < 2) {
      throw const FormatException(
        'That file doesn\'t look like a statement — no data rows found.',
      );
    }

    final header = rows.first.map((cell) => cell.toString().trim().toLowerCase()).toList();
    final dateIndex = _findColumn(header, _dateHeaders);
    final descriptionIndex = _findColumn(header, _descriptionHeaders);
    final amountIndex = _findColumn(header, _amountHeaders);
    final debitIndex = _findColumn(header, _debitHeaders);
    final creditIndex = _findColumn(header, _creditHeaders);

    if (dateIndex == null || descriptionIndex == null) {
      throw const FormatException(
        'Couldn\'t find date and description columns in that file — this '
        'bank\'s export format isn\'t recognized.',
      );
    }
    if (amountIndex == null && (debitIndex == null || creditIndex == null)) {
      throw const FormatException(
        'Couldn\'t find an amount column (or separate debit/credit '
        'columns) in that file.',
      );
    }

    final transactions = <BankTransaction>[];
    var skipped = 0;

    for (final row in rows.skip(1)) {
      if (row.length <= dateIndex ||
          row.length <= descriptionIndex ||
          (amountIndex != null && row.length <= amountIndex)) {
        skipped++;
        continue;
      }

      final date = _parseDate(row[dateIndex].toString().trim());
      final description = row[descriptionIndex].toString().trim();
      final amountCents = amountIndex != null
          ? _parseAmount(row[amountIndex].toString())
          : _amountFromDebitCredit(
              debitIndex! < row.length ? row[debitIndex].toString() : '',
              creditIndex! < row.length ? row[creditIndex].toString() : '',
            );

      if (date == null || description.isEmpty || amountCents == null) {
        skipped++;
        continue;
      }

      transactions.add(
        BankTransaction(date: date, description: description, amountCents: amountCents),
      );
    }

    return ParsedStatement(transactions: transactions, skippedRowCount: skipped);
  }

  int? _findColumn(List<String> header, List<String> candidates) {
    for (final candidate in candidates) {
      final index = header.indexOf(candidate);
      if (index != -1) return index;
    }
    return null;
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    for (final format in _dateFormats) {
      try {
        return format.parseStrict(raw);
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  /// Parses "$1,234.56", "-15.99", "(15.99)" (accounting notation for a
  /// negative), and "+15.99" into cents. Returns null for anything that
  /// isn't a recognizable amount.
  int? _parseAmount(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;

    var negative = false;
    if (value.startsWith('(') && value.endsWith(')')) {
      negative = true;
      value = value.substring(1, value.length - 1);
    }

    value = value.replaceAll(RegExp(r'[\$,\s]'), '');
    if (value.isEmpty) return null;

    final parsed = double.tryParse(value);
    if (parsed == null) return null;

    final cents = (parsed * 100).round();
    return negative ? -cents.abs() : cents;
  }

  int? _amountFromDebitCredit(String debitRaw, String creditRaw) {
    final debit = _parseAmount(debitRaw);
    final credit = _parseAmount(creditRaw);
    if (debit != null && debit != 0) return -debit.abs();
    if (credit != null && credit != 0) return credit.abs();
    return null;
  }
}

class ParsedStatement {
  final List<BankTransaction> transactions;
  final int skippedRowCount;

  const ParsedStatement({
    required this.transactions,
    required this.skippedRowCount,
  });
}
