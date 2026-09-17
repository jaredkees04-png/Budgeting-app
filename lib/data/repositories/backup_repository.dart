import 'dart:convert';

import '../database/app_database.dart';

/// Exports everything the app stores (categories/bills, transactions, and
/// settings) to a single portable JSON document, and restores from one.
///
/// Uses drift's generated `toJson`/`fromJson` on each data class rather
/// than hand-rolling field lists, so adding a column to a table doesn't
/// require remembering to update this file too.
class BackupRepository {
  final AppDatabase _db;

  BackupRepository(this._db);

  static const _formatVersion = 1;

  Future<String> exportToJson() async {
    final categories = await _db.select(_db.categories).get();
    final transactions = await _db.select(_db.transactions).get();
    final settings = await _db.select(_db.appSettingsTable).getSingleOrNull();

    final data = {
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'settings': settings?.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Replaces every category, transaction, and (if present in the backup)
  /// the app's settings with what's in [jsonString]. This is a full
  /// replace, not a merge — anything logged since the backup was made is
  /// gone afterward, which is why the UI confirms before calling this.
  Future<void> importFromJson(String jsonString) async {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

    final categories = (decoded['categories'] as List)
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
    final transactions = (decoded['transactions'] as List)
        .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
        .toList();
    final settingsJson = decoded['settings'] as Map<String, dynamic>?;
    final settings = settingsJson == null
        ? null
        : AppSettingsTableData.fromJson(settingsJson);

    await _db.transaction(() async {
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.categories).go();
      for (final category in categories) {
        await _db.into(_db.categories).insert(category.toCompanion(true));
      }
      for (final transaction in transactions) {
        await _db.into(_db.transactions).insert(transaction.toCompanion(true));
      }
      // Only touched when the backup actually has a settings section —
      // the table must never end up with zero rows, since nothing else
      // re-seeds it after first launch.
      if (settings != null) {
        await _db.delete(_db.appSettingsTable).go();
        await _db.into(_db.appSettingsTable).insert(settings.toCompanion(true));
      }
    });
  }
}
