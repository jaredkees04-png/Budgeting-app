// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_bill_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurringBillDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $RecurringBillsTable get recurringBills => attachedDatabase.recurringBills;
  RecurringBillDaoManager get managers => RecurringBillDaoManager(this);
}

class RecurringBillDaoManager {
  final _$RecurringBillDaoMixin _db;
  RecurringBillDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$RecurringBillsTableTableManager get recurringBills =>
      $$RecurringBillsTableTableManager(
        _db.attachedDatabase,
        _db.recurringBills,
      );
}
