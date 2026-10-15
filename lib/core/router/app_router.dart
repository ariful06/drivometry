// lib/core/router/app_router.dart

import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/fuel/presentation/pages/add_fuel_entry_page.dart';
import '../../features/fuel/presentation/pages/fuel_entry_detail_page.dart';
import '../../features/maintenance/presentation/pages/add_maintenance_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/rentals/domain/entities/rental_entry.dart';
import '../../features/rentals/presentation/pages/add_rental_entry_page.dart';
import '../../features/rentals/presentation/pages/rental_entry_detail_page.dart';
import '../../features/rentals/presentation/pages/rentals_page.dart';
import '../../features/vehicles/domain/entities/vehicle.dart';
import '../../features/vehicles/presentation/pages/add_vehicle_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_dashboard_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_details_page.dart';
import '../../features/vehicles/presentation/pages/vehicles_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../shell/main_shell.dart';

class AppRouter {
  static GoRouter createRouter({String initialLocation = '/vehicles'}) =>
      GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingPage(),
          ),
          ShellRoute(
            builder: (context, state, child) => MainShell(child: child),
            routes: [
              GoRoute(
                path: '/vehicles',
                builder: (context, state) => const VehiclesPage(),
              ),
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsPage(),
              ),
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsPage(),
              ),
              GoRoute(
                path: '/rentals',
                builder: (context, state) => const RentalsPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/vehicles/add',
            builder: (context, state) => const AddVehiclePage(),
          ),
          GoRoute(
            path: '/vehicles/:id/edit',
            builder: (context, state) {
              final vehicle = state.extra as Vehicle;
              return AddVehiclePage(vehicle: vehicle);
            },
          ),
          GoRoute(
            path: '/vehicles/:id/details',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final vehicle = state.extra is Vehicle ? state.extra as Vehicle : null;
              return VehicleDetailsRoutePage(vehicleId: id, vehicle: vehicle);
            },
          ),
          GoRoute(
            path: '/vehicles/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final vehicle = state.extra is Vehicle ? state.extra as Vehicle : null;
              return VehicleDashboardPage(vehicleId: id, vehicle: vehicle);
            },
          ),
      GoRoute(
        path: '/vehicles/:id/fuel/add',
        builder: (context, state) {
          final vehicle = state.extra as Vehicle;
          return AddFuelEntryPage(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: '/vehicles/:vehicleId/fuel/:entryId',
        builder: (context, state) {
          final args = state.extra as FuelEntryDetailArgs;
          return FuelEntryDetailPage(args: args);
        },
      ),
      GoRoute(
        path: '/vehicles/:id/maintenance/add',
        builder: (context, state) {
          final vehicle = state.extra as Vehicle;
          return AddMaintenancePage(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: '/rentals/add',
        builder: (context, state) => const AddRentalEntryPage(),
      ),
      GoRoute(
        path: '/rentals/:id/edit',
        builder: (context, state) {
          final entry = state.extra as RentalEntry;
          return AddRentalEntryPage(initialEntry: entry);
        },
      ),
      GoRoute(
        path: '/rentals/:id',
        builder: (context, state) {
          final entry = state.extra as RentalEntry;
          return RentalEntryDetailPage(entry: entry);
        },
      ),
        ],
      );

  static final router = createRouter();
}