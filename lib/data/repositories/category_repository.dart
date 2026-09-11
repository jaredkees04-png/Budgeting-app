import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/tables/categories_table.dart' show BudgetGroup, BillFrequency;
import '../database/tables/transactions_table.dart' show TransactionSource;
import 'transaction_repository.dart';

class CategoryRepository {
  final AppDatabase _db;
  final TransactionRepository _transactionRepository;
  final _uuid = const Uuid();

  CategoryRepository(this._db, this._transactionRepository);

  Stream<List<Category>> watchActiveCategories() =>
      _db.categoryDao.watchActiveCategories();

  Future<Category?> getById(String id) => _db.categoryDao.getById(id);

  Future<String> createCategory({
    required String name,
    required String icon,
    required String color,
    required BudgetGroup budgetGroup,
    bool isRecurring = false,
    BillFrequency? billFrequency,
    int? billAmountCents,
    DateTime? nextDueDate,
  }) async {
    final id = _uuid.v4();
    await _db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        id: id,
        name: name,
        icon: icon,
        color: color,
        budgetGroup: budgetGroup,
        isRecurring: Value(isRecurring),
        billFrequency: Value(billFrequency),
        billAmountCents: Value(billAmountCents),
        nextDueDate: Value(nextDueDate),
      ),
    );
    return id;
  }

  /// Replaces every editable field of [category] outright — the edit
  /// dialog always submits the full form state, so e.g. `isRecurring:
  /// false` here means "turn off recurring," not "leave unchanged."
  Future<void> updateCategory(
    Category category, {
    required String name,
    required String icon,
    required String color,
    required BudgetGroup budgetGroup,
    required bool isRecurring,
    BillFrequency? billFrequency,
    int? billAmountCents,
    DateTime? nextDueDate,
  }) {
    final updated = category.copyWith(
      name: name,
      icon: icon,
      color: color,
      budgetGroup: budgetGroup,
      isRecurring: isRecurring,
      billFrequency: Value(billFrequency),
      billAmountCents: Value(billAmountCents),
      nextDueDate: Value(nextDueDate),
    );
    return _db.categoryDao.updateCategory(updated.toCompanion(false));
  }

  /// Categories are archived, never hard-deleted, so historical
  /// transactions keep a valid category reference.
  Future<void> archiveCategory(String id) => _db.categoryDao.archiveCategory(id);

  /// Logs a transaction for a recurring category's bill amount today,
  /// then rolls [Category.nextDueDate] forward by one cycle from its
  /// *previous* due date (not today) so paying a few days early or late
  /// doesn't drift the bill off its regular schedule.
  Future<void> markBillPaid(Category category) async {
    final amountCents = category.billAmountCents;
    final dueDate = category.nextDueDate;
    final frequency = category.billFrequency;
    if (amountCents == null || dueDate == null || frequency == null) return;

    await _transactionRepository.addTransaction(
      amountCents: amountCents,
      categoryId: category.id,
      date: DateTime.now(),
      note: category.name,
      source: TransactionSource.recurring,
    );
    await _db.categoryDao.updateCategory(
      category
          .copyWith(nextDueDate: Value(_nextOccurrence(dueDate, frequency)))
          .toCompanion(false),
    );
  }

  DateTime _nextOccurrence(DateTime from, BillFrequency frequency) {
    switch (frequency) {
      case BillFrequency.weekly:
        return from.add(const Duration(days: 7));
      case BillFrequency.monthly:
      case BillFrequency.custom:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }
}
