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

  /// Flutter's ThemeMode.index: 0 = system, 1 = light, 2 = dark.
  IntColumn get themeMode => integer().withDefault(const Constant(0))();

  /// ARGB color value used as the Material 3 seed color for the whole
  /// app's theme. Defaults to the app's original green.
  IntColumn get accentColor =>
      integer().withDefault(const Constant(0xFF2E7D32))();

  /// Whether a PIN is required to open the app. There's no server and no
  /// user accounts — this is a local device lock, not authentication —
  /// so [lockPinHash] is only ever compared against, never sent anywhere.
  BoolColumn get isLockEnabled => boolean().withDefault(const Constant(false))();

  /// SHA-256 hex digest of the PIN, salted with [lockPinSalt]. Null when
  /// [isLockEnabled] is false.
  TextColumn get lockPinHash => text().nullable()();
  TextColumn get lockPinSalt => text().nullable()();

  /// Index into `kBackgroundOptions`. 0 is "Default" — Material's own
  /// accent-tinted surface colors, unchanged from before this setting
  /// existed — so a fresh install and anyone who never opens Settings
  /// looks exactly as before.
  IntColumn get backgroundOptionIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
