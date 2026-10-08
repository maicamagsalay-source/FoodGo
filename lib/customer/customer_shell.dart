import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class CustomerShell extends StatefulWidget {
  final int initialIndex;
  const CustomerShell({super.key, this.initialIndex = 0});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().count;
    // Pages are built fresh when you switch tabs, so lists always reload.
    final pages = [
      HomeScreen(onSearchTap: () => setState(() => _index = 1)),
      const SearchScreen(),
      CartScreen(onBrowse: () => setState(() => _index = 0)),
      const OrdersScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
