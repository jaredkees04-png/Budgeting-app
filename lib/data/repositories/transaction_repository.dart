import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/daos/transaction_dao.dart';
import '../database/tables/transactions_table.dart';

class TransactionRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  TransactionRepository(this._db);

  Stream<List<TransactionWithCategory>> watchTransactionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return _db.transactionDao.watchTransactionsInRange(start, end);
  }

  Future<void> addTransaction({
    required int amountCents,
    required String categoryId,
    required DateTime date,
    String? note,
    TransactionSource source = TransactionSource.manual,
    String? receiptImagePath,
  }) {
    return _db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        id: _uuid.v4(),
        amountCents: amountCents,
        categoryId: categoryId,
        date: date,
        note: Value(note),
        source: Value(source),
        receiptImagePath: Value(receiptImagePath),
      ),
    );
  }

  Future<void> updateTransaction(Transaction existing, {
    int? amountCents,
    String? categoryId,
    DateTime? date,
    String? note,
  }) {
    final updated = existing.copyWith(
      amountCents: amountCents ?? existing.amountCents,
      categoryId: categoryId ?? existing.categoryId,
      date: date ?? existing.date,
      note: Value(note ?? existing.note),
      updatedAt: DateTime.now(),
    );
    return _db.transactionDao.updateTransaction(updated.toCompanion(false));
  }

  Future<void> deleteTransaction(String id) =>
      _db.transactionDao.deleteTransaction(id);
}
