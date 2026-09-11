/// Common budgeting guideline percentages (of income) for a handful of
/// well-known category names. These are the widely-cited rules of thumb
/// people mean by e.g. "groceries should be ~10-15% of income" — there's
/// no such external guideline for a user's custom categories, so this
/// only applies to categories whose name matches one of these (renamed
/// default categories still match by default name unless the user
/// renames them too).
const Map<String, double> kCommonCategoryGuidelinesPct = {
  'groceries': 15.0,
  'rent/mortgage': 28.0,
};
