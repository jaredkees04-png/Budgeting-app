import 'package:drift/drift.dart';
import 'categories_table.dart';

/// How a transaction was entered. Manual entry is fully supported and
/// equally first-class; `scanned` is only ever set by the Phase 2
/// receipt-capture flow; `recurring` is set when a recurring bill is
/// marked paid. New values append at the end since the int index is what
/// persists to disk.
enum TransactionSource { manual, scanned, recurring }

class Transactions extends Table {
  TextColumn get id => text()();
  IntColumn get amountCents => integer()();
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  IntColumn get source =>
      intEnum<TransactionSource>().withDefault(const Constant(0))();
  TextColumn get receiptImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
