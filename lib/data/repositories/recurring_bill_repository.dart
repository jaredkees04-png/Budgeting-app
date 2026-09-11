import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/daos/recurring_bill_dao.dart';
import '../database/tables/recurring_bills_table.dart';
import '../database/tables/transactions_table.dart';
import 'transaction_repository.dart';

class RecurringBillRepository {
  final AppDatabase _db;
  final TransactionRepository _transactionRepository;
  final _uuid = const Uuid();

  RecurringBillRepository(this._db, this._transactionRepository);

  Stream<List<RecurringBillWithCategory>> watchActiveBills() =>
      _db.recurringBillDao.watchActiveBills();

  Future<void> createBill({
    required String name,
    required int amountCents,
    required String categoryId,
    required BillFrequency frequency,
    required DateTime nextDueDate,
  }) {
    return _db.recurringBillDao.insertBill(
      RecurringBillsCompanion.insert(
        id: _uuid.v4(),
        name: name,
        amountCents: amountCents,
        categoryId: categoryId,
        frequency: Value(frequency),
        nextDueDate: nextDueDate,
      ),
    );
  }

  Future<void> updateBill(
    RecurringBill existing, {
    required String name,
    required int amountCents,
    required String categoryId,
    required BillFrequency frequency,
    required DateTime nextDueDate,
  }) {
    final updated = existing.copyWith(
      name: name,
      amountCents: amountCents,
      categoryId: categoryId,
      frequency: frequency,
      nextDueDate: nextDueDate,
    );
    return _db.recurringBillDao.updateBill(updated.toCompanion(false));
  }

  Future<void> deleteBill(String id) => _db.recurringBillDao.deleteBill(id);

  /// Logs a transaction for the bill's amount/category today, then rolls
  /// [RecurringBill.nextDueDate] forward by one cycle from its *previous*
  /// due date (not today) so paying a few days early or late doesn't drift
  /// the bill off its regular schedule.
  Future<void> markPaid(RecurringBill bill) async {
    await _transactionRepository.addTransaction(
      amountCents: bill.amountCents,
      categoryId: bill.categoryId,
      date: DateTime.now(),
      note: bill.name,
      source: TransactionSource.recurring,
    );
    await _db.recurringBillDao.updateBill(
      bill
          .copyWith(nextDueDate: _nextOccurrence(bill.nextDueDate, bill.frequency))
          .toCompanion(false),
    );
  }

  DateTime _nextOccurrence(DateTime from, BillFrequency frequency) {
    switch (frequency) {
      case BillFrequency.weekly:
        return from.add(const Duration(days: 7));
      case BillFrequency.monthly:
      case BillFrequency.custom:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }
}
