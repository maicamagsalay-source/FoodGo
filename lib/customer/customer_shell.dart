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
    final isWide = MediaQuery.sizeOf(context).width >= 850;
    // Pages are built fresh when you switch tabs, so lists always reload.
    final pages = [
      HomeScreen(onSearchTap: () => setState(() => _index = 1)),
      const SearchScreen(),
      CartScreen(onBrowse: () => setState(() => _index = 0)),
      const OrdersScreen(),
      const ProfileScreen(),
    ];
    const destinations = [
      NavigationDestination(
          icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
      NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: 'Cart',
      ),
      NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders'),
      NavigationDestination(
          icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
    ];

    if (isWide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: 220,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 12, 16),
                      child: Row(
                        children: [
                          Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Lamón',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: NavigationRail(
                        backgroundColor: Colors.white,
                        extended: true,
                        minExtendedWidth: 210,
                        selectedIndex: _index,
                        onDestinationSelected: (i) => setState(() => _index = i),
                        groupAlignment: -0.9,
                        destinations: destinations
                            .map((destination) => NavigationRailDestination(
                                  icon: destination.icon,
                                  selectedIcon: destination.selectedIcon,
                                  label: Text(destination.label),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: pages[_index],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations
            .asMap()
            .entries
            .map((entry) => entry.key == 2
                ? NavigationDestination(
                    icon: Badge(
                      label: Text('$cartCount'),
                      isLabelVisible: cartCount > 0,
                      child: entry.value.icon,
                    ),
                    selectedIcon: Badge(
                      label: Text('$cartCount'),
                      isLabelVisible: cartCount > 0,
                      child: entry.value.selectedIcon,
                    ),
                    label: entry.value.label,
                  )
                : entry.value)
            .toList(),
      ),
    );
  }
}
