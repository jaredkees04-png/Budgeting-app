import 'package:intl/intl.dart';

/// All money in this app is stored and passed around as integer cents
/// to avoid floating point rounding errors in totals and percentages.
class Money {
  static final NumberFormat _currencyFormat = NumberFormat.simpleCurrency();

  /// Parses user input (e.g. "12.50", "12", "$12.50") into cents.
  /// Returns null if the input isn't a valid non-negative amount.
  static int? parseToCents(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }

  /// Formats cents as a localized currency string, e.g. 1250 -> "$12.50".
  static String format(int cents) {
    return _currencyFormat.format(cents / 100);
  }

  /// Formats cents without the currency symbol, e.g. 1250 -> "12.50".
  static String formatPlain(int cents) {
    return (cents / 100).toStringAsFixed(2);
  }
}
