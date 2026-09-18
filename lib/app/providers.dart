import 'package:flutter/material.dart' show Color, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/background_colors.dart';
import '../core/constants/theme_colors.dart';
import '../core/utils/date_period.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/transaction_dao.dart';
import '../data/repositories/backup_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../domain/models/spending_summary.dart';
import '../domain/services/app_lock_service.dart';
import '../domain/services/savings_recommendation_service.dart';
import '../domain/services/spending_breakdown_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(appDatabaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(transactionRepositoryProvider),
  );
});

final appLockServiceProvider = Provider<AppLockService>((ref) => AppLockService());

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(appLockServiceProvider),
  );
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(ref.watch(appDatabaseProvider));
});

final spendingBreakdownServiceProvider =
    Provider((ref) => SpendingBreakdownService());

final savingsRecommendationServiceProvider =
    Provider((ref) => SavingsRecommendationService());

/// The dashboard period the user has selected (week or month).
final selectedPeriodTypeProvider = StateProvider<PeriodType>((ref) {
  return PeriodType.month;
});

/// The anchor date for the currently viewed period; lets the user page
/// backward/forward through past weeks or months.
final selectedAnchorDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final selectedDateRangeProvider = Provider<DateRange>((ref) {
  final type = ref.watch(selectedPeriodTypeProvider);
  final anchor = ref.watch(selectedAnchorDateProvider);
  return DateRange.forPeriod(type, anchor);
});

final activeCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchActiveCategories();
});

final appSettingsProvider = StreamProvider((ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
});

/// Falls back to system/default while settings are still loading, so the
/// app never flashes an unstyled frame waiting on the database.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final index = ref.watch(appSettingsProvider).value?.themeMode;
  if (index == null || index < 0 || index >= ThemeMode.values.length) {
    return ThemeMode.system;
  }
  return ThemeMode.values[index];
});

final accentColorProvider = Provider<Color>((ref) {
  final value = ref.watch(appSettingsProvider).value?.accentColor;
  return value == null ? kThemeColorOptions.first.color : Color(value);
});

final backgroundOptionProvider = Provider<BackgroundOption>((ref) {
  final index = ref.watch(appSettingsProvider).value?.backgroundOptionIndex;
  if (index == null || index < 0 || index >= kBackgroundOptions.length) {
    return kBackgroundOptions.first;
  }
  return kBackgroundOptions[index];
});

final isLockEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).value?.isLockEnabled ?? false;
});

/// Whether the current app session has passed the lock screen. Session-
/// only by design (a plain in-memory StateProvider, not persisted) — a
/// fresh launch of the PWA should always ask for the PIN again when a
/// lock is set up, the same way a phone's own lock screen would.
final isUnlockedProvider = StateProvider<bool>((ref) => false);

final transactionsInPeriodProvider =
    StreamProvider<List<TransactionWithCategory>>((ref) {
  final range = ref.watch(selectedDateRangeProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactionsInRange(range.start, range.end);
});

/// All transactions, newest first — backs the history screen, which
/// isn't scoped to the dashboard's currently selected week/month.
final allTransactionsProvider = StreamProvider<List<TransactionWithCategory>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

final spendingSummaryProvider = Provider<AsyncValue<SpendingSummary>>((ref) {
  final transactions = ref.watch(transactionsInPeriodProvider);
  final service = ref.watch(spendingBreakdownServiceProvider);
  return transactions.whenData(service.summarize);
});

final savingsRecommendationProvider =
    Provider<AsyncValue<SavingsRecommendation>>((ref) {
  final transactionsAsync = ref.watch(transactionsInPeriodProvider);
  final settingsAsync = ref.watch(appSettingsProvider);
  final service = ref.watch(savingsRecommendationServiceProvider);

  if (transactionsAsync.isLoading || settingsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  final error = transactionsAsync.error ?? settingsAsync.error;
  if (error != null) {
    return AsyncValue.error(error, StackTrace.current);
  }

  final transactions = transactionsAsync.value ?? [];
  final settings = settingsAsync.value;
  if (settings == null) return const AsyncValue.loading();

  return AsyncValue.data(
    service.buildRecommendation(
      transactions: transactions,
      needsTargetPct: settings.needsTargetPct,
      wantsTargetPct: settings.wantsTargetPct,
      savingsTargetPct: settings.savingsTargetPct,
    ),
  );
});
