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
import '../../domain/usecases/vehicle_usecases.dart';
import '../cubits/vehicle_cubit.dart';

/// Tabbed dashboard (Fuel Log + Maintenance) for a vehicle.
/// The vehicle header tile is tappable and opens the vehicle details screen.
class VehicleDashboardTabsPage extends StatelessWidget {
  const VehicleDashboardTabsPage({required this.vehicle, super.key});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => sl<FuelCubit>()..watchForVehicle(vehicle.id)),
        BlocProvider(
            create: (_) => sl<MaintenanceCubit>()..watchForVehicle(vehicle.id)),
      ],
      child: _VehicleDashboardTabsView(vehicle: vehicle),
    );
  }
}

class _VehicleDashboardTabsView extends StatefulWidget {
  const _VehicleDashboardTabsView({required this.vehicle});
  final Vehicle vehicle;

  @override
  State<_VehicleDashboardTabsView> createState() =>
      _VehicleDashboardTabsViewState();
}

class _VehicleDashboardTabsViewState extends State<_VehicleDashboardTabsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Vehicle _currentVehicle;

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    // Refetch when state is first created (e.g. after pop if route was rebuilt with stale vehicle).
    WidgetsBinding.instance.addPostFrameCallback((_) => _refetchVehicle());
  }

  Future<void> _refetchVehicle() async {
    if (!mounted) return;
    final v = await sl<GetVehicleById>()(widget.vehicle.id);
    if (v != null && mounted) {
      setState(() => _currentVehicle = v);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentVehicle.name),
        actions: [
          IconButton(
            tooltip: 'Other expenses',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push(
              '/vehicles/${_currentVehicle.id}/expenses',
              extra: _currentVehicle,
            ),
          ),
          IconButton(
            tooltip: 'Fuel statistics',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.push(
              '/vehicles/${_currentVehicle.id}/fuel-stats',
              extra: _currentVehicle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _ModernTabBar(
              controller: _tabController,
              colors: colors,
              theme: theme,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: theme.appBarTheme.backgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: InkWell(
              onTap: () async {
                await context.push(
                  '/vehicles/${_currentVehicle.id}/details',
                  extra: _currentVehicle,
                );
                // Details can edit the vehicle (tank capacity, odometer…).
                if (mounted) await _refetchVehicle();
              },
              borderRadius: BorderRadius.circular(16),
              child: _VehicleHeaderCard(vehicle: _currentVehicle),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FuelTab(vehicle: _currentVehicle),
                _MaintenanceTab(vehicle: _currentVehicle),
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
              onPressed: () async {
                if (_tabController.index == 0) {
                  await context.push(
                    '/vehicles/${_currentVehicle.id}/fuel/add',
                    extra: _currentVehicle,
                  );
                } else {
                  await context.push(
                    '/vehicles/${_currentVehicle.id}/maintenance/add',
                    extra: _currentVehicle,
                  );
                }
                if (mounted) await _refetchVehicle();
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
          'This will delete "${_currentVehicle.name}" and all its records. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              sl<VehicleCubit>().deleteVehicle(_currentVehicle.id);
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

/// Modern pill-style tab bar with theme colors (fuel / maintenance).
class _ModernTabBar extends StatelessWidget {
  const _ModernTabBar({
    required this.controller,
    required this.colors,
    required this.theme,
  });

  final TabController controller;
  final AppColors colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.divider.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabSegment(
              selected: controller.index == 0,
              icon: Icons.local_gas_station_rounded,
              label: 'Fuel Log',
              color: colors.fuelColor,
              colors: colors,
              theme: theme,
              onTap: () {
                if (controller.index != 0) {
                  controller.animateTo(0);
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabSegment(
              selected: controller.index == 1,
              icon: Icons.build_rounded,
              label: 'Maintenance',
              color: colors.maintenanceColor,
              colors: colors,
              theme: theme,
              onTap: () {
                if (controller.index != 1) {
                  controller.animateTo(1);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  const _TabSegment({
    required this.selected,
    required this.icon,
    required this.label,
    required this.color,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final Color color;
  final AppColors colors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? Colors.white : colors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${vehicle.year} • ${vehicle.licensePlate}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.textSecondary),
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.textSecondary),
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
    final consumptionByEntryId =
        FuelConsumptionCalculator.byEndEntryId(segments);
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
                Formatters.formatFuelEfficiency(mileagePerLiter)
                    .split(' ')
                    .first,
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
          MaintenanceError(:final message) =>
            Center(child: Text('Error: $message')),
          MaintenanceLoaded(:final entries) => entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: EmptyState(
                    icon: Icons.build_outlined,
                    title: 'No service records yet',
                    subtitle:
                        'Tap Log Service below to add a repair or parts replacement.',
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
      final upcomingServiceDate = maintenanceEntry.nextServiceDate;
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
