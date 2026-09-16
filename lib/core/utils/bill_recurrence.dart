import '../../data/database/app_database.dart';
import '../../data/database/tables/categories_table.dart' show BillFrequency;

/// Whether a recurring bill category falls due on [day], projected from
/// its stored due date rather than read off it directly: a monthly bill
/// recurs on the same day-of-month every month (clamped to the last day
/// of shorter months), a weekly bill on the same weekday every week.
/// This works for any month — past, current, or future — not just
/// whichever one [Category.nextDueDate] currently happens to point at,
/// which is what makes a calendar view of "which days does this bill
/// fall on" possible without walking the recurrence one cycle at a time.
bool billDueOn(Category category, DateTime day) {
  if (!category.isRecurring) return false;
  final due = category.nextDueDate;
  final frequency = category.billFrequency;
  if (due == null || frequency == null) return false;

  switch (frequency) {
    case BillFrequency.weekly:
      return day.weekday == due.weekday;
    case BillFrequency.monthly:
    case BillFrequency.custom:
      final lastDayOfMonth = DateTime(day.year, day.month + 1, 0).day;
      final effectiveDay = due.day > lastDayOfMonth ? lastDayOfMonth : due.day;
      return day.day == effectiveDay;
  }
}
