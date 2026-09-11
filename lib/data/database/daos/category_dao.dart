import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<Category>> watchActiveCategories() {
    return (select(categories)
          ..where((c) => c.isArchived.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  Future<Category?> getById(String id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  Future<void> updateCategory(CategoriesCompanion entry) {
    return update(categories).replace(entry);
  }

  Future<void> archiveCategory(String id) {
    return (update(categories)..where((c) => c.id.equals(id)))
        .write(const CategoriesCompanion(isArchived: Value(true)));
  }

  Future<int> countCategories() async {
    final rows = await select(categories).get();
    return rows.length;
  }
}
