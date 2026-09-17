/// One row parsed out of an imported bank statement CSV. Amounts follow
/// the same convention as the app's own transactions: negative means
/// money out (a charge), positive means money in.
class BankTransaction {
  final DateTime date;
  final String description;
  final int amountCents;

  const BankTransaction({
    required this.date,
    required this.description,
    required this.amountCents,
  });
}
