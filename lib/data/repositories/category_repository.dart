import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/tables/categories_table.dart' show BudgetGroup;

class CategoryRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CategoryRepository(this._db);

  Stream<List<Category>> watchActiveCategories() =>
      _db.categoryDao.watchActiveCategories();

  Future<Category?> getById(String id) => _db.categoryDao.getById(id);

  Future<String> createCategory({
    required String name,
    required String icon,
    required String color,
    required BudgetGroup budgetGroup,
  }) async {
    final id = _uuid.v4();
    await _db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        id: id,
        name: name,
        icon: icon,
        color: color,
        budgetGroup: budgetGroup,
      ),
    );
    return id;
  }

  Future<void> renameCategory(Category category, String newName) {
    return _db.categoryDao.updateCategory(
      category.copyWith(name: newName).toCompanion(false),
    );
  }

  Future<void> reclassifyCategory(Category category, BudgetGroup group) {
    return _db.categoryDao.updateCategory(
      category.copyWith(budgetGroup: group).toCompanion(false),
    );
  }

  /// Categories are archived, never hard-deleted, so historical
  /// transactions keep a valid category reference.
  Future<void> archiveCategory(String id) => _db.categoryDao.archiveCategory(id);
}
