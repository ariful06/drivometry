import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../../../maintenance/domain/repositories/maintenance_repository.dart';
import '../../../maintenance/domain/usecases/maintenance_usecases.dart';
import '../../domain/entities/vehicle.dart';
import '../cubits/vehicle_cubit.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/vehicle_dashboard_metrics.dart';

class VehiclesPage extends StatelessWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        sl<RunMaintenanceReminderChecks>()();
        return sl<VehicleCubit>()..startWatching();
      },
      child: const _VehiclesView(),
    );
  }
}

class _VehiclesView extends StatelessWidget {
  const _VehiclesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeCubit>().state == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<VehicleCubit, VehicleState>(
        builder: (context, state) {
          return switch (state) {
            VehicleInitial() => const LoadingOverlay(),
            VehicleLoading() => const LoadingOverlay(),
            VehicleError(:final message) =>
              Center(child: Text('Error: $message')),
            VehicleLoaded(:final vehicles) => vehicles.isEmpty
                ? const EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: 'No Vehicles Yet',
                    subtitle:
                        'Add your first vehicle to start tracking expenses.',
                  )
                : _VehicleDashboardScroll(vehicles: vehicles),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vehicles/add'),
        tooltip: 'Add Vehicle',
        child: const Icon(Icons.add),
      ),
    );
  }
}

bool _vehiclesListSameMetricsKey(
  List<Vehicle> previousVehicleList,
  List<Vehicle> nextVehicleList,
) {
  if (previousVehicleList.length != nextVehicleList.length) return false;
  for (var index = 0; index < previousVehicleList.length; index++) {
    if (previousVehicleList[index].id != nextVehicleList[index].id ||
        previousVehicleList[index].currentOdometer !=
            nextVehicleList[index].currentOdometer) {
      return false;
    }
  }
  return true;
}

class _VehicleDashboardScroll extends StatefulWidget {
  const _VehicleDashboardScroll({required this.vehicles});
  final List<Vehicle> vehicles;

  @override
  State<_VehicleDashboardScroll> createState() =>
      _VehicleDashboardScrollState();
}

class _VehicleDashboardScrollState extends State<_VehicleDashboardScroll> {
  int _metricsGeneration = 0;
  StreamSubscription<void>? _maintenanceSub;

  @override
  void initState() {
    super.initState();
    _maintenanceSub =
        sl<MaintenanceRepository>().watchMaintenanceChanges().listen((_) {
      if (mounted) setState(() => _metricsGeneration++);
    });
  }

  @override
  void dispose() {
    _maintenanceSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _VehicleDashboardScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_vehiclesListSameMetricsKey(oldWidget.vehicles, widget.vehicles)) {
      setState(() => _metricsGeneration++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VehicleDashboardMetrics>>(
      key: ValueKey(_metricsGeneration),
      future: VehicleDashboardMetrics.loadAll(widget.vehicles),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final metricsList = snapshot.data!;
        final vehicles = widget.vehicles;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'My Vehicles',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => VehicleDashboardListTile(
                    vehicle: vehicles[i],
                    metrics: metricsList[i],
                  ),
                  childCount: vehicles.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
