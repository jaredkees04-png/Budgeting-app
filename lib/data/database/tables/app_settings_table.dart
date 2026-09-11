import 'package:drift/drift.dart';

/// Single-row table (id is always 0) holding app-wide preferences,
/// including the user-adjustable 50/30/20 guideline percentages.
class AppSettingsTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  IntColumn get selectedPeriod => integer().withDefault(const Constant(1))();
  IntColumn get needsTargetPct => integer().withDefault(const Constant(50))();
  IntColumn get wantsTargetPct => integer().withDefault(const Constant(30))();
  IntColumn get savingsTargetPct =>
      integer().withDefault(const Constant(20))();

  @override
  Set<Column> get primaryKey => {id};
}
