import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:budgeting_app/data/database/app_database.dart';
import 'package:budgeting_app/data/database/tables/categories_table.dart';

void main() {
  test(
    'upgrading from the old separate recurring_bills table folds an '
    'existing bill onto its category, then drops the old table',
    () async {
      final dir = await Directory.systemTemp.createTemp('recurring_migration');
      addTearDown(() => dir.delete(recursive: true));
      final path = p.join(dir.path, 'test.sqlite');

      // Recreate exactly what schema v2 (the version this app shipped
      // with before bills were merged into categories) left on disk: a
      // categories table plus a standalone recurring_bills table
      // pointing at one of its rows.
      final raw = sqlite3.sqlite3.open(path);
      raw.execute('''
        CREATE TABLE categories (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          budget_group INTEGER NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        );
      ''');
      raw.execute('''
        CREATE TABLE recurring_bills (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          amount_cents INTEGER NOT NULL,
          category_id TEXT NOT NULL REFERENCES categories(id),
          frequency INTEGER NOT NULL DEFAULT 1,
          next_due_date INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL
        );
      ''');
      // A real v2 install also has app_settings_table (created at v1,
      // with the theme/accent columns already added by the v1-to-v2
      // migration) — needed here too, since opening AppDatabase below
      // triggers every migration step up to the current schema version,
      // not just the recurring-bills one this test is about.
      raw.execute('''
        CREATE TABLE app_settings_table (
          id INTEGER NOT NULL PRIMARY KEY,
          selected_period INTEGER NOT NULL DEFAULT 1,
          needs_target_pct INTEGER NOT NULL DEFAULT 50,
          wants_target_pct INTEGER NOT NULL DEFAULT 30,
          savings_target_pct INTEGER NOT NULL DEFAULT 20,
          theme_mode INTEGER NOT NULL DEFAULT 0,
          accent_color INTEGER NOT NULL DEFAULT 3022368
        );
      ''');
      raw.execute("INSERT INTO app_settings_table (id) VALUES (0)");
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final due = DateTime(2026, 10, 1).millisecondsSinceEpoch ~/ 1000;
      raw.execute(
        "INSERT INTO categories VALUES "
        "('cat-rent', 'Rent', 'home', '#C62828', 1, 0, 0, 0, $now)",
      );
      raw.execute(
        "INSERT INTO recurring_bills VALUES "
        "('bill-1', 'Rent', 120000, 'cat-rent', 1, $due, 1, $now)",
      );
      raw.execute('PRAGMA user_version = 2');
      raw.close();

      // Opening the app's real AppDatabase against that same file triggers
      // the from-2-to-3 upgrade path.
      final db = AppDatabase(NativeDatabase(File(path)));
      addTearDown(db.close);

      final category = await (db.select(
        db.categories,
      )..where((c) => c.id.equals('cat-rent'))).getSingle();
      expect(category.isRecurring, isTrue);
      expect(category.billFrequency, BillFrequency.monthly);
      expect(category.billAmountCents, 120000);
      expect(category.nextDueDate, DateTime(2026, 10, 1));

      final oldTable = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'recurring_bills'",
          )
          .getSingleOrNull();
      expect(
        oldTable,
        isNull,
        reason: 'the old standalone table should be dropped once migrated',
      );
    },
  );
}
