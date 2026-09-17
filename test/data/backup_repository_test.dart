import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/data/database/app_database.dart';
import 'package:budgeting_app/data/repositories/backup_repository.dart';
import 'package:budgeting_app/data/repositories/category_repository.dart';
import 'package:budgeting_app/data/repositories/settings_repository.dart';
import 'package:budgeting_app/data/repositories/transaction_repository.dart';
import 'package:budgeting_app/data/database/tables/categories_table.dart';

void main() {
  late AppDatabase db;
  late BackupRepository backupRepo;
  late CategoryRepository categoryRepo;
  late TransactionRepository transactionRepo;
  late SettingsRepository settingsRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final transactionRepository = TransactionRepository(db);
    backupRepo = BackupRepository(db);
    categoryRepo = CategoryRepository(db, transactionRepository);
    transactionRepo = transactionRepository;
    settingsRepo = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test(
    'exporting then importing restores categories, bills, transactions, '
    'and settings exactly as they were',
    () async {
      // Seed some real data: a plain category, a recurring bill, a couple
      // of transactions, and a non-default setting.
      final rentId = await categoryRepo.createCategory(
        name: 'Rent',
        icon: 'home',
        color: '#C62828',
        budgetGroup: BudgetGroup.needs,
        isRecurring: true,
        billFrequency: BillFrequency.monthly,
        billAmountCents: 120000,
        nextDueDate: DateTime(2026, 10, 1),
      );
      final funId = await categoryRepo.createCategory(
        name: 'Fun',
        icon: 'celebration',
        color: '#8E24AA',
        budgetGroup: BudgetGroup.wants,
      );
      await transactionRepo.addTransaction(
        amountCents: 500000,
        categoryId: rentId,
        date: DateTime(2026, 9, 1),
        note: 'September rent',
      );
      await transactionRepo.addTransaction(
        amountCents: 2500,
        categoryId: funId,
        date: DateTime(2026, 9, 2),
      );
      await settingsRepo.updateAccentColor(0xFF3949AB);
      await settingsRepo.updateTargets(needsPct: 55, wantsPct: 25, savingsPct: 20);

      final exported = await backupRepo.exportToJson();

      // Mutate the live data so we can tell import actually restored the
      // snapshot rather than the test just passing by coincidence.
      await categoryRepo.createCategory(
        name: 'Should disappear after import',
        icon: 'category',
        color: '#000000',
        budgetGroup: BudgetGroup.wants,
      );
      await settingsRepo.updateAccentColor(0xFFFF0000);

      await backupRepo.importFromJson(exported);

      // The db seeds 5 default categories (Income, Rent/Mortgage, etc.) on
      // creation, alongside the two created for this test.
      final categories = await db.select(db.categories).get();
      expect(categories, hasLength(7));
      expect(categories.map((c) => c.name), containsAll(['Rent', 'Fun']));
      expect(
        categories.any((c) => c.name == 'Should disappear after import'),
        isFalse,
      );

      final rent = categories.firstWhere((c) => c.name == 'Rent');
      expect(rent.isRecurring, isTrue);
      expect(rent.billFrequency, BillFrequency.monthly);
      expect(rent.billAmountCents, 120000);
      expect(rent.nextDueDate, DateTime(2026, 10, 1));

      final transactions = await db.select(db.transactions).get();
      expect(transactions, hasLength(2));
      expect(
        transactions.map((t) => t.amountCents),
        containsAll([500000, 2500]),
      );

      final settings = await db.select(db.appSettingsTable).getSingle();
      expect(settings.accentColor, 0xFF3949AB);
      expect(settings.needsTargetPct, 55);
      expect(settings.wantsTargetPct, 25);
    },
  );

  test('importing a backup with no settings section leaves settings alone', () async {
    await categoryRepo.createCategory(
      name: 'Rent',
      icon: 'home',
      color: '#C62828',
      budgetGroup: BudgetGroup.needs,
    );
    await settingsRepo.updateAccentColor(0xFF3949AB);

    const backupWithoutSettings = '''
    {
      "formatVersion": 1,
      "categories": [],
      "transactions": [],
      "settings": null
    }
    ''';

    await backupRepo.importFromJson(backupWithoutSettings);

    final settings = await db.select(db.appSettingsTable).getSingle();
    expect(
      settings.accentColor,
      0xFF3949AB,
      reason: 'a missing settings section should not wipe the single '
          'settings row the app depends on always existing',
    );
    expect(await db.select(db.categories).get(), isEmpty);
  });
}
