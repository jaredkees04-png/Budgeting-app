import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/recurring_bills_table.dart';
import '../tables/categories_table.dart';

part 'recurring_bill_dao.g.dart';

@DriftAccessor(tables: [RecurringBills, Categories])
class RecurringBillDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringBillDaoMixin {
  RecurringBillDao(super.db);

  /// Active bills soonest-due first, so the list doubles as an at-a-glance
  /// "what's coming up" view.
  Stream<List<RecurringBillWithCategory>> watchActiveBills() {
    final query =
        select(recurringBills).join([
            innerJoin(
              categories,
              categories.id.equalsExp(recurringBills.categoryId),
            ),
          ])
          ..where(recurringBills.isActive.equals(true))
          ..orderBy([OrderingTerm.asc(recurringBills.nextDueDate)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => RecurringBillWithCategory(
              bill: row.readTable(recurringBills),
              category: row.readTable(categories),
            ),
          )
          .toList(),
    );
  }

  Future<void> insertBill(RecurringBillsCompanion entry) {
    return into(recurringBills).insert(entry);
  }

  Future<void> updateBill(RecurringBillsCompanion entry) {
    return update(recurringBills).replace(entry);
  }

  Future<void> deleteBill(String id) {
    return (delete(recurringBills)..where((b) => b.id.equals(id))).go();
  }
}

class RecurringBillWithCategory {
  final RecurringBill bill;
  final Category category;

  const RecurringBillWithCategory({required this.bill, required this.category});
}
