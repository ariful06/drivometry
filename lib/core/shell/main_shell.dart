// lib/core/shell/main_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentLocation});
  final String currentLocation;

  /// Order: Dashboard, Rental, Analytics, Reminder
  int get _selectedIndex {
    if (currentLocation.startsWith('/rentals')) return 1;
    if (currentLocation.startsWith('/analytics')) return 2;
    if (currentLocation.startsWith('/notifications')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        if (index == 0) {
          context.go('/vehicles');
        } else if (index == 1) {
          context.go('/rentals');
        } else if (index == 2) {
          context.go('/analytics');
        } else if (index == 3) {
          context.go('/notifications');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.car_rental_outlined),
          selectedIcon: Icon(Icons.car_rental),
          label: 'Rental',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'Reminder',
        ),
      ],
    );
  }
}
