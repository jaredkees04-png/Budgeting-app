import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../core/utils/date_period.dart';
import '../../domain/services/app_lock_service.dart';

/// This table only ever holds one row. Earlier versions of this class
/// filtered every query by `id.equals(0)`, relying on the id column's
/// `withDefault(Constant(0))`. That default is silently ignored by
/// SQLite: a column declared `INTEGER PRIMARY KEY` is a rowid alias, and
/// omitting it from an INSERT (as drift does for an absent Value) makes
/// SQLite auto-assign the next rowid — 1, not the declared default — no
/// matter what the column's DEFAULT says. Every `id.equals(0)` query was
/// therefore matching zero rows from the very first seed insert, which
/// silently broke the 50/30/20 card and any settings written here.
/// Operating on "the only row" instead of a specific id sidesteps the
/// quirk entirely and self-heals existing installs with a stray id=1
/// row, no corrective migration needed.
class SettingsRepository {
  final AppDatabase _db;
  final AppLockService _lockService;

  SettingsRepository(this._db, [AppLockService? lockService])
    : _lockService = lockService ?? AppLockService();

  /// Null until the single settings row exists. In practice that's only a
  /// brief window right after first launch (before the schema-creation
  /// seed insert lands) — callers should treat null as "still starting up"
  /// rather than an error, instead of assuming the row is always present.
  Stream<AppSettingsTableData?> watchSettings() {
    return _db.select(_db.appSettingsTable).watchSingleOrNull();
  }

  Future<void> updatePeriod(PeriodType period) {
    return _db
        .update(_db.appSettingsTable)
        .write(AppSettingsTableCompanion(selectedPeriod: Value(period.index)));
  }

  Future<void> updateTargets({
    required int needsPct,
    required int wantsPct,
    required int savingsPct,
  }) {
    return _db.update(_db.appSettingsTable).write(
      AppSettingsTableCompanion(
        needsTargetPct: Value(needsPct),
        wantsTargetPct: Value(wantsPct),
        savingsTargetPct: Value(savingsPct),
      ),
    );
  }

  /// [themeModeIndex] is Flutter's ThemeMode.index (0 system, 1 light,
  /// 2 dark) — kept as a plain int here so this data-layer class doesn't
  /// need to depend on Flutter; the provider layer maps to/from the enum.
  Future<void> updateThemeMode(int themeModeIndex) {
    return _db
        .update(_db.appSettingsTable)
        .write(AppSettingsTableCompanion(themeMode: Value(themeModeIndex)));
  }

  /// [argbValue] is a Color's 32-bit ARGB integer value.
  Future<void> updateAccentColor(int argbValue) {
    return _db
        .update(_db.appSettingsTable)
        .write(AppSettingsTableCompanion(accentColor: Value(argbValue)));
  }

  /// [index] is an index into `kBackgroundOptions`.
  Future<void> updateBackgroundOption(int index) {
    return _db.update(_db.appSettingsTable).write(
      AppSettingsTableCompanion(backgroundOptionIndex: Value(index)),
    );
  }

  /// Turns app-lock on with [pin], replacing any previous PIN.
  Future<void> enableLock(String pin) {
    final salt = _lockService.generateSalt();
    final hash = _lockService.hashPin(pin, salt);
    return _db.update(_db.appSettingsTable).write(
      AppSettingsTableCompanion(
        isLockEnabled: const Value(true),
        lockPinHash: Value(hash),
        lockPinSalt: Value(salt),
      ),
    );
  }

  Future<void> disableLock() {
    return _db.update(_db.appSettingsTable).write(
      const AppSettingsTableCompanion(
        isLockEnabled: Value(false),
        lockPinHash: Value(null),
        lockPinSalt: Value(null),
      ),
    );
  }

  /// False both when the PIN is wrong and when no lock is set up at all,
  /// so a caller can't accidentally treat "nothing to check against" as
  /// a pass.
  Future<bool> verifyPin(String pin) async {
    final settings = await _db.select(_db.appSettingsTable).getSingle();
    final hash = settings.lockPinHash;
    final salt = settings.lockPinSalt;
    if (hash == null || salt == null) return false;
    return _lockService.verifyPin(pin: pin, salt: salt, expectedHash: hash);
  }
}
