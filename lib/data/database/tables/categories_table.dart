import 'package:drift/drift.dart';

/// Which bucket of the 50/30/20 rule of thumb a category counts toward.
/// `income` categories are excluded from the needs/wants/savings split
/// and instead used as the denominator (total income) for it.
enum BudgetGroup { income, needs, wants, savings }

/// How often a recurring bill category repeats. `custom` is reserved for
/// an arbitrary interval (e.g. every 10 days) that isn't built yet — no
/// column stores its interval length, so it isn't offered as a choice.
enum BillFrequency { weekly, monthly, custom }

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

  /// A category doubles as a recurring bill (e.g. Rent, Netflix) when
  /// this is true — any category can opt in, including custom ones the
  /// user creates. [billFrequency], [billAmountCents] and [nextDueDate]
  /// are only meaningful while this is set.
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  IntColumn get billFrequency => intEnum<BillFrequency>().nullable()();
  IntColumn get billAmountCents => integer().nullable()();
  DateTimeColumn get nextDueDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
