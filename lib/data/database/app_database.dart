import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budgeting_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
