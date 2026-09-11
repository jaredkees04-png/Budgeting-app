import 'package:flutter/material.dart';

import '../features/categories/category_list_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/history/history_screen.dart';

/// Bottom-nav shell: Dashboard is the default landing screen since it's
/// what makes the app worth opening daily; History and Bills are one
/// tab away.
///
/// "Bills" is [CategoryListScreen] — categories and recurring bills were
/// split into separate tabs/tables at first, then merged: a bill is just
/// a category (built-in or custom) with its recurring fields switched
/// on, since a bill and its category are always 1:1 anyway. One screen
/// manages both instead of two.
///
/// Each tab is its own Scaffold with its own floating action button
/// (Dashboard/History: add a transaction; Bills: add a category) rather
/// than one FAB living here. IndexedStack only paints/hit-tests the
/// active child, so this is what keeps the tabs' FABs from stacking on
/// top of each other in the same corner — a single FAB declared on this
/// outer Scaffold would sit above every tab's own FAB regardless of
/// which one is showing, making anything underneath unreachable.
///
/// IndexedStack keeps every tab mounted (not just the active one) so
/// their state survives switching tabs, but that means all their FABs
/// exist in the tree at once even though only the active tab's paints.
/// Hero's tag-matching walks the whole tree regardless of paint
/// visibility, so each tab's FAB needs its own unique heroTag — reusing
/// one across tabs throws "multiple heroes share the same tag" the
/// moment a route-push tries to animate it.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    HistoryScreen(),
    CategoryListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_repeat_outlined),
            selectedIcon: Icon(Icons.event_repeat),
            label: 'Bills',
          ),
        ],
      ),
    );
  }
}
