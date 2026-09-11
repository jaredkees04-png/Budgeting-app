import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../core/utils/date_period.dart';

class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  /// Null until the single settings row exists. In practice that's only a
  /// brief window right after first launch (before the schema-creation
  /// seed insert lands) — callers should treat null as "still starting up"
  /// rather than an error, instead of assuming the row is always present.
  Stream<AppSettingsTableData?> watchSettings() {
    return (_db.select(_db.appSettingsTable)..where((s) => s.id.equals(0)))
        .watchSingleOrNull();
  }

  Future<void> updatePeriod(PeriodType period) {
    return (_db.update(_db.appSettingsTable)..where((s) => s.id.equals(0)))
        .write(AppSettingsTableCompanion(selectedPeriod: Value(period.index)));
  }

  Future<void> updateTargets({
    required int needsPct,
    required int wantsPct,
    required int savingsPct,
  }) {
    return (_db.update(_db.appSettingsTable)..where((s) => s.id.equals(0)))
        .write(
      AppSettingsTableCompanion(
        needsTargetPct: Value(needsPct),
        wantsTargetPct: Value(wantsPct),
        savingsTargetPct: Value(savingsPct),
      ),
    );
  }
}
