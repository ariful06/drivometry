import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../../../fuel/presentation/cubits/fuel_cubit.dart';
import '../../../fuel/domain/entities/fuel_entry.dart';
import '../../../fuel/domain/services/fuel_consumption_calculator.dart';
import '../../../fuel/presentation/widgets/fuel_entry_tile.dart';
import '../../../maintenance/presentation/cubits/maintenance_cubit.dart';
import '../../../maintenance/presentation/widgets/maintenance_entry_tile.dart';
import '../../domain/entities/vehicle.dart';
import '../cubits/vehicle_cubit.dart';

class VehicleDetailPage extends StatelessWidget {
  const VehicleDetailPage({required this.vehicle, super.key});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<FuelCubit>()..watchForVehicle(vehicle.id)),
        BlocProvider(create: (_) => sl<MaintenanceCubit>()..watchForVehicle(vehicle.id)),
      ],
      child: _VehicleDetailView(vehicle: vehicle),
    );
  }
}

class _VehicleDetailView extends StatefulWidget {
  const _VehicleDetailView({required this.vehicle});
  final Vehicle vehicle;

  @override
  State<_VehicleDetailView> createState() => _VehicleDetailViewState();
}

class _VehicleDetailViewState extends State<_VehicleDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Fuel Log'),
            Tab(text: 'Maintenance'),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
        ),
      ),
      body: Column(
        children: [
          Container(
            color: theme.appBarTheme.backgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: _VehicleHeaderCard(vehicle: widget.vehicle),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FuelTab(vehicle: widget.vehicle),
                _MaintenanceTab(vehicle: widget.vehicle),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                if (_tabController.index == 0) {
                  context.push(
                    '/vehicles/${widget.vehicle.id}/fuel/add',
                    extra: widget.vehicle,
                  );
                } else {
                  context.push(
                    '/vehicles/${widget.vehicle.id}/maintenance/add',
                    extra: widget.vehicle,
                  );
                }
              },
              icon: Icon(
                _tabController.index == 0
                    ? Icons.local_gas_station_outlined
                    : Icons.build_outlined,
                size: 20,
              ),
              label: Text(
                _tabController.index == 0 ? 'Log Fuel' : 'Log Service',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text(
          'This will delete "${widget.vehicle.name}" and all its records. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              sl<VehicleCubit>().deleteVehicle(widget.vehicle.id);
              Navigator.pop(context);
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _VehicleHeaderCard extends StatelessWidget {
  const _VehicleHeaderCard({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: VehicleTypeIcon(
              vehicleType: vehicle.type,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.make} ${vehicle.model}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${vehicle.year} • ${vehicle.licensePlate}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatDistance(vehicle.currentOdometer),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                'Odometer',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FuelTab extends StatelessWidget {
  const _FuelTab({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FuelCubit, FuelState>(
      builder: (context, state) {
        return switch (state) {
          FuelInitial() => const SizedBox.shrink(),
          FuelLoading() => const LoadingOverlay(),
          FuelError(:final message) => Center(child: Text('Error: $message')),
          FuelLoaded(:final entries, :final totalCost) => entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: EmptyState(
                    icon: Icons.local_gas_station_outlined,
                    title: 'No fuel entries yet',
                    subtitle: 'Tap Log Fuel below to add your first fill-up.',
                  ),
                )
              : _FuelList(
                  entries: entries,
                  totalCost: totalCost,
                  tankCapacityLiters: vehicle.tankCapacityLiters,
                ),
        };
      },
    );
  }
}

class _FuelList extends StatelessWidget {
  const _FuelList({
    required this.entries,
    required this.totalCost,
    this.tankCapacityLiters,
  });
  final List entries;
  final double totalCost;
  final double? tankCapacityLiters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final segments = FuelConsumptionCalculator.segments(
      entries.cast<FuelEntry>(),
      tankCapacityLiters: tankCapacityLiters,
    );
    final consumptionByEntryId = FuelConsumptionCalculator.byEndEntryId(segments);
    final latestConsumption = segments.isEmpty ? null : segments.last;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (latestConsumption != null) ...[
                  _FuelHeroInsight(
                    mileagePerLiter: latestConsumption.kmPerLiter,
                    distanceDriven: latestConsumption.distanceKm,
                    fuelRefill: latestConsumption.liters,
                    colors: colors,
                  ),
                  const SizedBox(height: 20),
                ],
                _FuelStatsBar(
                  totalCost: totalCost,
                  entryCount: entries.length,
                  colors: colors,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Fill history',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FuelEntryTile(
                  entry: entries[i],
                  previousEntry: i + 1 < entries.length ? entries[i + 1] : null,
                  consumption: consumptionByEntryId[entries[i].id],
                ),
              ),
              childCount: entries.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

/// Hero insight: one big number (latest km/L) so users get the key metric at a glance.
class _FuelHeroInsight extends StatelessWidget {
  const _FuelHeroInsight({
    required this.mileagePerLiter,
    required this.distanceDriven,
    required this.fuelRefill,
    required this.colors,
  });
  final double mileagePerLiter;
  final double distanceDriven;
  final double fuelRefill;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colors.maintenanceColor.withOpacity(0.18),
                  colors.maintenanceColor.withOpacity(0.08),
                ]
              : [
                  colors.maintenanceColor.withOpacity(0.12),
                  colors.maintenanceColor.withOpacity(0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.maintenanceColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last full-tank consumption',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Formatters.formatFuelEfficiency(mileagePerLiter).split(' ').first,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.maintenanceColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'km/L',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.maintenanceColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${Formatters.formatDistance(distanceDriven)} driven · ${Formatters.formatLiters(fuelRefill)} since previous full tank',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact stats: total spent + log count in one row.
class _FuelStatsBar extends StatelessWidget {
  const _FuelStatsBar({
    required this.totalCost,
    required this.entryCount,
    required this.colors,
  });
  final double totalCost;
  final int entryCount;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatPill(
            label: 'Total spent',
            value: Formatters.formatCurrency(totalCost),
            color: colors.fuelColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatPill(
            label: 'Logs',
            value: '$entryCount',
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceTab extends StatelessWidget {
  const _MaintenanceTab({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaintenanceCubit, MaintenanceState>(
      builder: (context, state) {
        return switch (state) {
          MaintenanceInitial() => const SizedBox.shrink(),
          MaintenanceLoading() => const LoadingOverlay(),
          MaintenanceError(:final message) => Center(child: Text('Error: $message')),
          MaintenanceLoaded(:final entries) => entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: EmptyState(
                    icon: Icons.build_outlined,
                    title: 'No service records yet',
                    subtitle: 'Tap Log Service below to add a repair or parts replacement.',
                  ),
                )
              : _MaintenanceList(
                  entries: entries,
                  currentVehicleOdometer: vehicle.currentOdometer,
                ),
        };
      },
    );
  }
}

class _MaintenanceList extends StatelessWidget {
  const _MaintenanceList({
    required this.entries,
    this.currentVehicleOdometer,
  });
  final List entries;
  final double? currentVehicleOdometer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final totalCost = entries.fold<double>(
      0,
      (runningMaintenanceSum, maintenanceEntry) =>
          runningMaintenanceSum + maintenanceEntry.cost,
    );
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    DateTime? closest;
    for (final maintenanceEntry in entries) {
      final upcomingServiceDate =
          maintenanceEntry.nextServiceDate;
      if (upcomingServiceDate == null) continue;
      final dateOnly = DateTime(
        upcomingServiceDate.year,
        upcomingServiceDate.month,
        upcomingServiceDate.day,
      );
      if (dateOnly.isBefore(startOfToday)) continue;
      if (closest == null || dateOnly.isBefore(closest)) {
        closest = dateOnly;
      }
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: 'Total spent',
                        value: Formatters.formatCurrency(totalCost),
                        color: colors.maintenanceColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatPill(
                        label: 'Next due',
                        value: closest != null
                            ? Formatters.formatDate(closest)
                            : '--',
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Service history',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MaintenanceEntryTile(
                  entry: entries[i],
                  currentVehicleOdometer: currentVehicleOdometer,
                ),
              ),
              childCount: entries.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}