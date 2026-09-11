import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'connection/connection.dart' as connection;
import 'daos/category_dao.dart';
import 'daos/recurring_bill_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/app_settings_table.dart';
import 'tables/categories_table.dart';
import 'tables/recurring_bills_table.dart';
import 'tables/transactions_table.dart';
import '../../core/constants/default_categories.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions, RecurringBills, AppSettingsTable],
  daos: [CategoryDao, TransactionDao, RecurringBillDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? connection.openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _seedDefaults();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Checked rather than unconditional: on the wasm/OPFS backend,
          // the schema-version marker write can lose a race with the tab
          // closing right after a migration runs, so the next load may
          // see schemaVersion still at 1 and try to redo a migration
          // that already landed — addColumn would then throw "duplicate
          // column name" and hard-crash the app on every future launch.
          final existingColumns = await customSelect(
            "SELECT name FROM pragma_table_info('app_settings_table')",
          ).map((row) => row.read<String>('name')).get();
          if (!existingColumns.contains('theme_mode')) {
            await m.addColumn(appSettingsTable, appSettingsTable.themeMode);
          }
          if (!existingColumns.contains('accent_color')) {
            await m.addColumn(appSettingsTable, appSettingsTable.accentColor);
          }
        }
      },
    );
  }

  Future<void> _seedDefaults() async {
    const uuid = Uuid();
    for (final seed in kDefaultCategories) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: seed.name,
          icon: seed.icon,
          color: seed.color,
          budgetGroup: seed.budgetGroup,
          isDefault: const Value(true),
          sortOrder: Value(seed.sortOrder),
        ),
      );
    }
    // id is explicit rather than relying on withDefault(Constant(0)): a
    // column declared INTEGER PRIMARY KEY is a rowid alias, and SQLite
    // auto-assigns the next rowid when it's omitted from an INSERT
    // (which drift does for an absent Value), silently ignoring the
    // column's DEFAULT. See SettingsRepository's doc comment — the
    // repository no longer depends on this row's id being 0, but it's
    // still worth seeding correctly rather than leaving it to chance.
    await into(
      appSettingsTable,
    ).insert(const AppSettingsTableCompanion(id: Value(0)));
  }
}
