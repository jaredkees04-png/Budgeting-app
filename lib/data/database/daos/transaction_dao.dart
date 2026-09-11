import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions_table.dart';
import '../tables/categories_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// All transactions in [start, end) with their category, newest first.
  Stream<List<TransactionWithCategory>> watchTransactionsInRange(
    DateTime start,
    DateTime end,
  ) {
    final query = select(transactions).join([
      innerJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
    ])
      ..where(
        transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerThanValue(end),
      )
      ..orderBy([OrderingTerm.desc(transactions.date)]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => TransactionWithCategory(
                  transaction: row.readTable(transactions),
                  category: row.readTable(categories),
                ),
              )
              .toList(),
        );
  }

  Future<void> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  Future<void> updateTransaction(TransactionsCompanion entry) {
    return update(transactions).replace(entry);
  }

  Future<void> deleteTransaction(String id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}

class TransactionWithCategory {
  final Transaction transaction;
  final Category category;

  const TransactionWithCategory({
    required this.transaction,
    required this.category,
  });
}
