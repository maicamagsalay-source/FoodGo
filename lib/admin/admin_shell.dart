import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_screens.dart';
import '../providers.dart';
import 'dashboard_page.dart';
import 'foods_page.dart';
import 'orders_page.dart';
import 'customers_page.dart';
import 'payments_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  static const _titles = ['Dashboard', 'Foods', 'Orders', 'Customers', 'Payments'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Extra safety: customers can never see admin pages. (The database also blocks them with RLS.)
    if (!auth.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock, size: 64),
            const Text('Admins only'),
            TextButton(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) goToLanding(context);
              },
              child: const Text('Back to login'),
            ),
          ]),
        ),
      );
    }

    // Pages are rebuilt when you switch tabs so data is always fresh.
    final pages = [
      const DashboardPage(),
      const FoodsPage(),
      const AdminOrdersPage(),
      const CustomersPage(),
      const PaymentsPage(),
    ];
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    const destinations = [
      NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
      NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Foods'),
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
      NavigationDestination(icon: Icon(Icons.people_outline), label: 'Customers'),
      NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Payments'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Lamón Admin • ${_titles[_index]}'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) goToLanding(context);
            },
          ),
        ],
      ),
      body: Row(children: [
        if (isWide)
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: destinations
                .map((destination) => NavigationRailDestination(
                      icon: destination.icon,
                      label: Text(destination.label),
                    ))
                .toList(),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24 : 0,
              vertical: isWide ? 16 : 0,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: pages[_index],
              ),
            ),
          ),
        ),
      ]),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: destinations,
            ),
    );
  }
}
