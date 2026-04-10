import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../../../maintenance/domain/usecases/maintenance_usecases.dart';
import '../cubits/vehicle_cubit.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/vehicle_dashboard_metrics.dart';

class VehiclesPage extends StatelessWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        sl<CheckOdometerDueReminders>()();
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
        ],
      ),
      body: BlocBuilder<VehicleCubit, VehicleState>(
        builder: (context, state) {
          return switch (state) {
            VehicleInitial() => const LoadingOverlay(),
            VehicleLoading() => const LoadingOverlay(),
            VehicleError(:final message) => Center(child: Text('Error: $message')),
            VehicleLoaded(:final vehicles) => vehicles.isEmpty
                ? EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: 'No Vehicles Yet',
                    subtitle:
                        'Add your first vehicle to start tracking expenses.',
                    action: ElevatedButton.icon(
                      onPressed: () => context.push('/vehicles/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Vehicle'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(180, 48),
                      ),
                    ),
                  )
                : FutureBuilder<List<VehicleDashboardMetrics>>(
                    key: ValueKey(
                      vehicles.map((v) => '${v.id}_${v.currentOdometer}').join(','),
                    ),
                    future: VehicleDashboardMetrics.loadAll(vehicles),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final metricsList = snapshot.data!;
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
                  ),
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
