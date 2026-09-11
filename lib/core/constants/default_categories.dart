import '../../data/database/tables/categories_table.dart';

class DefaultCategorySeed {
  final String name;
  final String icon;
  final String color;
  final BudgetGroup budgetGroup;
  final int sortOrder;

  const DefaultCategorySeed({
    required this.name,
    required this.icon,
    required this.color,
    required this.budgetGroup,
    required this.sortOrder,
  });
}

/// Seeded on first launch. Users can rename, recolor, reclassify, or
/// archive these later, but they always exist so income/spending has
/// somewhere to land immediately.
const List<DefaultCategorySeed> kDefaultCategories = [
  DefaultCategorySeed(
    name: 'Income',
    icon: 'payments',
    color: '#2E7D32',
    budgetGroup: BudgetGroup.income,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Bills',
    icon: 'receipt_long',
    color: '#C62828',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 1,
  ),
  DefaultCategorySeed(
    name: 'Groceries',
    icon: 'shopping_cart',
    color: '#1565C0',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 2,
  ),
  DefaultCategorySeed(
    name: 'Personal/Fun',
    icon: 'celebration',
    color: '#8E24AA',
    budgetGroup: BudgetGroup.wants,
    sortOrder: 3,
  ),
];

/// Default 50/30/20 guideline percentages. Stored (and user-adjustable)
/// in app_settings rather than hardcoded, since these are a rule of
/// thumb, not a fixed rule.
const int kDefaultNeedsTargetPct = 50;
const int kDefaultWantsTargetPct = 30;
const int kDefaultSavingsTargetPct = 20;
