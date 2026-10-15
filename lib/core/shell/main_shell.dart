// lib/core/shell/main_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(
        currentLocation: GoRouterState.of(context).uri.path,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentLocation});
  final String currentLocation;

  static const _items = <_NavItem>[
    _NavItem(
        '/vehicles', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    if (AppConstants.rentalsEnabled)
      _NavItem(
          '/rentals', 'Rental', Icons.car_rental_outlined, Icons.car_rental),
    _NavItem(
        '/analytics', 'Analytics', Icons.bar_chart_outlined, Icons.bar_chart),
    _NavItem('/notifications', 'Reminder', Icons.notifications_outlined,
        Icons.notifications),
  ];

  int get _selectedIndex {
    final index =
        _items.indexWhere((item) => currentLocation.startsWith(item.path));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => context.go(_items[index].path),
      destinations: [
        for (final item in _items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
      ],
    );
  }
}
