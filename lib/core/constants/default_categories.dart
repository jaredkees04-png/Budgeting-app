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
///
/// "Bills" used to be a single catch-all category, but everyone's bills
/// are different — so the starter set only covers the two nearly
/// universal ones (housing, utilities); everything else is a one-tap
/// suggestion in [kSuggestedBillCategories] instead of being forced on
/// everyone.
const List<DefaultCategorySeed> kDefaultCategories = [
  DefaultCategorySeed(
    name: 'Income',
    icon: 'payments',
    color: '#2E7D32',
    budgetGroup: BudgetGroup.income,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Rent/Mortgage',
    icon: 'home',
    color: '#C62828',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 1,
  ),
  DefaultCategorySeed(
    name: 'Utilities',
    icon: 'bolt',
    color: '#EF6C00',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 2,
  ),
  DefaultCategorySeed(
    name: 'Groceries',
    icon: 'shopping_cart',
    color: '#1565C0',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 3,
  ),
  DefaultCategorySeed(
    name: 'Personal/Fun',
    icon: 'celebration',
    color: '#8E24AA',
    budgetGroup: BudgetGroup.wants,
    sortOrder: 4,
  ),
];

/// One-tap suggestions offered when adding a new category, covering
/// common bills that not everyone has (so they're opt-in rather than
/// pre-seeded for every user). Picking one pre-fills the new-category
/// form; the user can still rename, recolor, or reclassify before saving.
const List<DefaultCategorySeed> kSuggestedBillCategories = [
  DefaultCategorySeed(
    name: 'Phone/Internet',
    icon: 'wifi',
    color: '#00838F',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Insurance',
    icon: 'shield',
    color: '#455A64',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Car Payment',
    icon: 'directions_car',
    color: '#6D4C41',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Loan Payment',
    icon: 'account_balance',
    color: '#37474F',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Health/Medical',
    icon: 'local_hospital',
    color: '#C62828',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Childcare',
    icon: 'child_care',
    color: '#8D6E63',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Subscriptions',
    icon: 'repeat',
    color: '#8E24AA',
    budgetGroup: BudgetGroup.wants,
    sortOrder: 0,
  ),
];

/// One-tap suggestions for everyday spending beyond bills — so people
/// aren't stuck either using the 5 starter categories or typing every
/// category from scratch.
const List<DefaultCategorySeed> kSuggestedEverydayCategories = [
  DefaultCategorySeed(
    name: 'Dining Out',
    icon: 'restaurant',
    color: '#EF6C00',
    budgetGroup: BudgetGroup.wants,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Entertainment',
    icon: 'movie',
    color: '#8E24AA',
    budgetGroup: BudgetGroup.wants,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Shopping',
    icon: 'shopping_bag',
    color: '#C2185B',
    budgetGroup: BudgetGroup.wants,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Clothing',
    icon: 'checkroom',
    color: '#3949AB',
    budgetGroup: BudgetGroup.wants,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Travel',
    icon: 'flight',
    color: '#1565C0',
    budgetGroup: BudgetGroup.wants,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Fitness/Gym',
    icon: 'fitness_center',
    color: '#00838F',
    budgetGroup: BudgetGroup.wants,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Gifts/Donations',
    icon: 'card_giftcard',
    color: '#C62828',
    budgetGroup: BudgetGroup.wants,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Pets',
    icon: 'pets',
    color: '#6D4C41',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Education',
    icon: 'school',
    color: '#37474F',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Home Maintenance',
    icon: 'build',
    color: '#455A64',
    budgetGroup: BudgetGroup.needs,
    sortOrder: 0,
  ),
  DefaultCategorySeed(
    name: 'Savings/Investments',
    icon: 'savings',
    color: '#2E7D32',
    budgetGroup: BudgetGroup.savings,
    sortOrder: 0,
  ),
];

/// Default 50/30/20 guideline percentages. Stored (and user-adjustable)
/// in app_settings rather than hardcoded, since these are a rule of
/// thumb, not a fixed rule.
const int kDefaultNeedsTargetPct = 50;
const int kDefaultWantsTargetPct = 30;
const int kDefaultSavingsTargetPct = 20;
