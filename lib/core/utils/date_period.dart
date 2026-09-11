/// The dashboard period the user is currently viewing.
enum PeriodType { week, month }

/// A concrete [start, end] date range (inclusive start, exclusive end)
/// resolved from a [PeriodType] and an anchor date.
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && day.isBefore(end);
  }

  static DateRange forPeriod(PeriodType type, DateTime anchor) {
    switch (type) {
      case PeriodType.week:
        return _weekOf(anchor);
      case PeriodType.month:
        return _monthOf(anchor);
    }
  }

  /// Week starts on Monday.
  static DateRange _weekOf(DateTime anchor) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    final start = day.subtract(Duration(days: day.weekday - DateTime.monday));
    final end = start.add(const Duration(days: 7));
    return DateRange(start, end);
  }

  static DateRange _monthOf(DateTime anchor) {
    final start = DateTime(anchor.year, anchor.month, 1);
    final end = DateTime(anchor.year, anchor.month + 1, 1);
    return DateRange(start, end);
  }
}
