import 'package:flutter/material.dart';

import '../features/categories/category_list_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/transaction_entry/transaction_entry_screen.dart';

/// Bottom-nav shell: Dashboard is the default landing screen since it's
/// what makes the app worth opening daily; Categories is one tab away.
/// Adding a transaction is always one tap away via the FAB, from either
/// tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    CategoryListScreen(),
  ];

  void _openTransactionEntry() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransactionEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addTransactionFab',
        onPressed: _openTransactionEntry,
        child: const Icon(Icons.add),
      ),
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
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
    );
  }
}
