import 'package:drift/drift.dart';

/// Which bucket of the 50/30/20 rule of thumb a category counts toward.
/// `income` categories are excluded from the needs/wants/savings split
/// and instead used as the denominator (total income) for it.
enum BudgetGroup { income, needs, wants, savings }

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  IntColumn get budgetGroup => intEnum<BudgetGroup>()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
