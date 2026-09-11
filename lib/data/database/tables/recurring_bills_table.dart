import 'package:drift/drift.dart';
import 'categories_table.dart';

enum BillFrequency { weekly, monthly, custom }

/// Schema only for now — no due-date reminders or dedicated UI yet.
/// Added early so the future feature doesn't need a migration.
class RecurringBills extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get amountCents => integer()();
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.restrict)();
  IntColumn get frequency =>
      intEnum<BillFrequency>().withDefault(const Constant(1))();
  DateTimeColumn get nextDueDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
