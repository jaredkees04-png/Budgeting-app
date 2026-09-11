import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'connection/connection.dart' as connection;
import 'daos/category_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/app_settings_table.dart';
import 'tables/categories_table.dart';
import 'tables/transactions_table.dart';
import '../../core/constants/default_categories.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions, AppSettingsTable],
  daos: [CategoryDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? connection.openConnection());

  @override
  int get schemaVersion => 3;

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
        if (from < 3) {
          // Recurring bills used to be their own table pointing at a
          // category. They're now just fields on the category itself
          // (any category, including custom ones, can opt into being a
          // recurring bill) — simpler for a 1:1 relationship that never
          // needed its own identity. Existing bills are folded onto
          // their category before the old table is dropped, so nobody
          // who'd already set one up loses it.
          final categoryColumns = await customSelect(
            "SELECT name FROM pragma_table_info('categories')",
          ).map((row) => row.read<String>('name')).get();
          if (!categoryColumns.contains('is_recurring')) {
            await m.addColumn(categories, categories.isRecurring);
          }
          if (!categoryColumns.contains('bill_frequency')) {
            await m.addColumn(categories, categories.billFrequency);
          }
          if (!categoryColumns.contains('bill_amount_cents')) {
            await m.addColumn(categories, categories.billAmountCents);
          }
          if (!categoryColumns.contains('next_due_date')) {
            await m.addColumn(categories, categories.nextDueDate);
          }

          final oldBillsTable = await customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'recurring_bills'",
          ).getSingleOrNull();
          if (oldBillsTable != null) {
            final oldBills = await customSelect(
              'SELECT category_id, frequency, amount_cents, next_due_date '
              'FROM recurring_bills WHERE is_active = 1',
            ).get();
            for (final row in oldBills) {
              await (update(categories)..where(
                    (c) => c.id.equals(row.read<String>('category_id')),
                  ))
                  .write(
                    CategoriesCompanion(
                      isRecurring: const Value(true),
                      billFrequency: Value(
                        BillFrequency.values[row.read<int>('frequency')],
                      ),
                      billAmountCents: Value(row.read<int>('amount_cents')),
                      nextDueDate: Value(row.read<DateTime>('next_due_date')),
                    ),
                  );
            }
            await customStatement('DROP TABLE recurring_bills');
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
