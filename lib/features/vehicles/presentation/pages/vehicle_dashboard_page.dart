import 'package:flutter/material.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/vehicle_usecases.dart';
import 'vehicle_dashboard_tabs_page.dart';

/// Wrapper that resolves [Vehicle] by id when not passed as [extra] (e.g. from startup).
class VehicleDashboardPage extends StatelessWidget {
  const VehicleDashboardPage({
    required this.vehicleId,
    super.key,
    this.vehicle,
  });
  final String vehicleId;
  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    if (vehicle != null) {
      return VehicleDashboardTabsPage(vehicle: vehicle!);
    }
    return FutureBuilder<Vehicle?>(
      future: sl<GetVehicleById>()(vehicleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final v = snapshot.data;
        if (v == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Vehicle not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }
        return VehicleDashboardTabsPage(vehicle: v);
      },
    );
  }
}
