import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'connection/connection.dart' as connection;
import 'daos/category_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/app_settings_table.dart';
import 'tables/categories_table.dart';
import 'tables/recurring_bills_table.dart';
import 'tables/transactions_table.dart';
import '../../core/constants/default_categories.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions, RecurringBills, AppSettingsTable],
  daos: [CategoryDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? connection.openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _seedDefaults();
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
    await into(appSettingsTable).insert(const AppSettingsTableCompanion());
  }
}
