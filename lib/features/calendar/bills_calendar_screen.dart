import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/providers.dart';
import '../../core/utils/bill_recurrence.dart';
import '../../core/utils/category_visuals.dart';
import '../../core/utils/money.dart';
import '../../data/database/app_database.dart';
import '../../widgets/empty_state.dart';
import '../categories/category_edit_dialog.dart';

/// A month calendar of recurring bills, color-coded to match the
/// category colors used everywhere else (the dashboard's pie chart
/// included) — so a glance at a day's dots tells you which bills land
/// there without needing a legend.
///
/// Tapping a day selects it and lists its bills below; the "+" button
/// adds a new recurring bill due on whichever day is currently selected.
class BillsCalendarScreen extends ConsumerStatefulWidget {
  const BillsCalendarScreen({super.key});

  @override
  ConsumerState<BillsCalendarScreen> createState() =>
      _BillsCalendarScreenState();
}

class _BillsCalendarScreenState extends ConsumerState<BillsCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<Category> _billsOn(DateTime day, List<Category> recurringBills) {
    return recurringBills.where((c) => billDueOn(c, day)).toList();
  }

  Future<void> _addBill(BuildContext context, WidgetRef ref) async {
    final existingNames = (ref.read(activeCategoriesProvider).value ?? [])
        .map((c) => c.name.toLowerCase())
        .toSet();
    final result = await showCategoryEditDialog(
      context,
      existingNames: existingNames,
      initialDueDate: _selectedDay,
    );
    if (result == null) return;
    await ref.read(categoryRepositoryProvider).createCategory(
          name: result.name,
          icon: result.icon,
          color: result.color,
          budgetGroup: result.budgetGroup,
          isRecurring: result.isRecurring,
          billFrequency: result.billFrequency,
          billAmountCents: result.billAmountCents,
          nextDueDate: result.nextDueDate,
        );
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    await ref.read(categoryRepositoryProvider).markBillPaid(category);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked "${category.name}" as paid')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addBillFromCalendarFab',
        onPressed: () => _addBill(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (categories) {
          final recurringBills = categories.where((c) => c.isRecurring).toList();
          final selectedBills = _billsOn(_selectedDay, recurringBills);

          // A single scrolling ListView (rather than a fixed calendar plus
          // an Expanded list) so the day's bills are never squeezed out —
          // or, worse, laid out into an unhittable sliver of space — when
          // the month grid alone is taller than a small screen leaves room
          // for below the app bar and bottom nav.
          //
          // Bottom padding reserves space for the FAB: it floats at a
          // fixed screen position above the scroll content, so without
          // this a bill scrolled to the bottom of the list can end up
          // directly underneath it — its "mark as paid" button would be
          // covered by (and would actually activate) the FAB instead.
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              TableCalendar<Category>(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                eventLoader: (day) => _billsOn(day, recurringBills),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, bills) {
                    if (bills.isEmpty) return null;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: bills.take(4).map((bill) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: colorFromHex(bill.color),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(_selectedDay),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (isSameDay(_selectedDay, DateTime.now()))
                      const Text('Today'),
                  ],
                ),
              ),
              if (selectedBills.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No bills due this day',
                    message:
                        'Tap the + button to add a recurring bill for '
                        'this date.',
                  ),
                )
              else
                ...selectedBills.map((bill) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorFromHex(bill.color),
                      child: Icon(iconForKey(bill.icon), color: Colors.white),
                    ),
                    title: Text(bill.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Money.format(bill.billAmountCents!),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          tooltip: 'Mark as paid',
                          onPressed: () => _markPaid(context, ref, bill),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
