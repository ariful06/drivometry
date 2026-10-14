import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../cubits/analytics_cubit.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnalyticsCubit>()
        ..loadAnalytics(period: AppConstants.periodMonthly),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatefulWidget {
  const _AnalyticsView();

  @override
  State<_AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<_AnalyticsView> {
  String _period = AppConstants.periodWeekly;
  final _periods = [
    AppConstants.periodWeekly,
    AppConstants.periodMonthly,
    AppConstants.periodYearly,
    AppConstants.periodLifetime,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _PeriodSelector(
              periods: _periods,
              selected: _period,
              onChanged: (period) {
                setState(() => _period = period);
                context.read<AnalyticsCubit>().loadAnalytics(period: period);
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
              builder: (context, state) {
                return switch (state) {
                  AnalyticsInitial() => const SizedBox.shrink(),
                  AnalyticsLoading() => const LoadingOverlay(),
                  AnalyticsError(:final message) =>
                    Center(child: Text('Error: $message')),
                  AnalyticsLoaded(
                    :final vehicleAnalytics,
                    :final totalFuelCost,
                    :final totalMaintenanceCost,
                    :final totalCost,
                    :final totalRentalBillable,
                    :final totalRentalDue,
                    :final monthlyBreakdown,
                  ) =>
                    vehicleAnalytics.isEmpty
                        ? const EmptyState(
                            icon: Icons.bar_chart_outlined,
                            title: 'No Data Yet',
                            subtitle:
                                'Add vehicles, then log fuel, maintenance, or rentals.',
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _AnalyticsOverview(
                                totalFuel: totalFuelCost,
                                totalMaintenance: totalMaintenanceCost,
                                totalSpend: totalCost,
                                totalRentalBillable: totalRentalBillable,
                                totalRentalDue: totalRentalDue,
                              ),
                              const SizedBox(height: 20),
                              _MonthlyTrendChart(data: monthlyBreakdown),
                              const SizedBox(height: 20),
                              if (totalCost > 0)
                                _ExpenseBreakdownPie(
                                  fuelCost: totalFuelCost,
                                  maintenanceCost: totalMaintenanceCost,
                                ),
                              if (totalCost > 0) const SizedBox(height: 20),
                              if (totalRentalBillable > 0 || totalRentalDue > 0)
                                _RentalSnapshotCard(
                                  rentalBillable: totalRentalBillable,
                                  rentalDue: totalRentalDue,
                                  operatingSpend: totalCost,
                                ),
                              const SizedBox(height: 20),
                              const SectionHeader(
                                  title: 'Per Vehicle Breakdown'),
                              ...vehicleAnalytics
                                  .map((v) => _VehicleAnalyticsCard(data: v)),
                              const SizedBox(height: 24),
                            ],
                          ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsOverview extends StatelessWidget {
  const _AnalyticsOverview({
    required this.totalFuel,
    required this.totalMaintenance,
    required this.totalSpend,
    required this.totalRentalBillable,
    required this.totalRentalDue,
  });
  final double totalFuel;
  final double totalMaintenance;
  final double totalSpend;
  final double totalRentalBillable;
  final double totalRentalDue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final net = totalRentalBillable - totalSpend;
    final netPositive = net >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.fuelColor.withValues(alpha: 0.92),
                colors.partsColor.withValues(alpha: 0.88),
                colors.maintenanceColor.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.fuelColor.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operating snapshot',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                Formatters.formatCurrency(net),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                netPositive
                    ? 'Rental billings ahead of fuel + maintenance in this period.'
                    : 'Spend is higher than rental billings in this period.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeroMiniStat(
                      label: 'Rental (billable)',
                      value: Formatters.formatCurrency(totalRentalBillable),
                    ),
                  ),
                  Expanded(
                    child: _HeroMiniStat(
                      label: 'Operating spend',
                      value: Formatters.formatCurrency(totalSpend),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Fuel',
                value: Formatters.formatCurrency(totalFuel),
                icon: Icons.local_gas_station_outlined,
                color: colors.fuelColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: 'Maintenance',
                value: Formatters.formatCurrency(totalMaintenance),
                icon: Icons.build_outlined,
                color: colors.maintenanceColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Rental income',
                subtitle: 'After customer fuel credits',
                value: Formatters.formatCurrency(totalRentalBillable),
                icon: Icons.car_rental_outlined,
                color: colors.partsColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: 'Rental due',
                subtitle: 'Outstanding in period',
                value: Formatters.formatCurrency(totalRentalDue),
                icon: Icons.payments_outlined,
                color: totalRentalDue > 0 ? colors.warning : colors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.data});
  final List<MonthlyBreakdown> data;

  double _maxY() {
    if (data.isEmpty) return 100;
    var maximumMonthlyStackHeight = 0.0;
    for (final monthBreakdownRow in data) {
      maximumMonthlyStackHeight = [
        maximumMonthlyStackHeight,
        monthBreakdownRow.fuelCost,
        monthBreakdownRow.maintenanceCost,
        monthBreakdownRow.rentalBillable,
      ].reduce(
        (greater, candidate) => candidate > greater ? candidate : greater,
      );
    }
    return maximumMonthlyStackHeight * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Six-month trend',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Fuel & maintenance (costs) vs rental billable (income)',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxY(),
                barGroups: data.asMap().entries.map((indexedBreakdownRow) {
                  final monthSlotIndex = indexedBreakdownRow.key;
                  final monthlyBreakdown = indexedBreakdownRow.value;
                  return BarChartGroupData(
                    x: monthSlotIndex,
                    groupVertically: false,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: monthlyBreakdown.fuelCost,
                        color: colors.fuelColor,
                        width: 7,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: monthlyBreakdown.maintenanceCost,
                        color: colors.maintenanceColor,
                        width: 7,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: monthlyBreakdown.rentalBillable,
                        color: colors.partsColor,
                        width: 7,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (axisValue, _) =>
                          axisValue.toInt() < data.length
                              ? Text(
                                  DateFormat('MMM').format(
                                    data[axisValue.toInt()].month,
                                  ),
                                  style: TextStyle(
                                      fontSize: 9, color: colors.textSecondary),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: colors.divider.withValues(alpha: 0.5),
                      strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _Legend(color: colors.fuelColor, label: 'Fuel'),
              _Legend(color: colors.maintenanceColor, label: 'Maintenance'),
              _Legend(color: colors.partsColor, label: 'Rental'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RentalSnapshotCard extends StatelessWidget {
  const _RentalSnapshotCard({
    required this.rentalBillable,
    required this.rentalDue,
    required this.operatingSpend,
  });
  final double rentalBillable;
  final double rentalDue;
  final double operatingSpend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final snapshotMaxGaugeValue = [
      rentalBillable,
      operatingSpend,
      1.0,
    ].reduce(
      (greater, candidate) => candidate > greater ? candidate : greater,
    );
    final rentalFrac = (rentalBillable / snapshotMaxGaugeValue).clamp(0.0, 1.0);
    final spendFrac = (operatingSpend / snapshotMaxGaugeValue).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.partsColor.withValues(alpha: 0.12),
            colors.cardBackground,
          ],
        ),
        border: Border.all(color: colors.partsColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: colors.partsColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Rental pulse',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Billable vs operating spend (same scale)',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          _PulseBar(
              label: 'Rental billable',
              value: rentalFrac,
              color: colors.partsColor,
              amount: rentalBillable),
          const SizedBox(height: 10),
          _PulseBar(
            label: 'Fuel + maintenance',
            value: spendFrac,
            color: colors.maintenanceColor,
            amount: operatingSpend,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  rentalDue > 0
                      ? Icons.schedule_outlined
                      : Icons.check_circle_outline,
                  size: 20,
                  color: rentalDue > 0 ? colors.warning : colors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rentalDue > 0
                        ? 'Collect ${Formatters.formatCurrency(rentalDue)} from open rental balances in this period.'
                        : 'No outstanding rental balance in this period.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseBar extends StatelessWidget {
  const _PulseBar({
    required this.label,
    required this.value,
    required this.color,
    required this.amount,
  });
  final String label;
  final double value;
  final Color color;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.labelMedium)),
            Text(
              Formatters.formatCurrency(amount),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ExpenseBreakdownPie extends StatelessWidget {
  const _ExpenseBreakdownPie(
      {required this.fuelCost, required this.maintenanceCost});
  final double fuelCost;
  final double maintenanceCost;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final total = fuelCost + maintenanceCost;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cost Breakdown',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: fuelCost,
                      color: colors.fuelColor,
                      title: '${(fuelCost / total * 100).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                      radius: 55,
                    ),
                    PieChartSectionData(
                      value: maintenanceCost,
                      color: colors.maintenanceColor,
                      title:
                          '${(maintenanceCost / total * 100).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                      radius: 55,
                    ),
                  ],
                  centerSpaceRadius: 20,
                )),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PieLegendItem(
                        color: colors.fuelColor,
                        label: 'Fuel',
                        value: Formatters.formatCurrency(fuelCost)),
                    const SizedBox(height: 12),
                    _PieLegendItem(
                        color: colors.maintenanceColor,
                        label: 'Maintenance',
                        value: Formatters.formatCurrency(maintenanceCost)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieLegendItem extends StatelessWidget {
  const _PieLegendItem(
      {required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.textSecondary)),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleAnalyticsCard extends StatelessWidget {
  const _VehicleAnalyticsCard({required this.data});
  final VehicleAnalytics data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.vehicleName,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          InfoRow(
            label: 'Fuel cost',
            value: Formatters.formatCurrency(data.fuelCost),
            valueColor: colors.fuelColor,
          ),
          InfoRow(
            label: 'Maintenance cost',
            value: Formatters.formatCurrency(data.maintenanceCost),
            valueColor: colors.maintenanceColor,
          ),
          InfoRow(
            label: 'Rental (billable)',
            value: Formatters.formatCurrency(data.rentalBillable),
            valueColor: colors.partsColor,
          ),
          InfoRow(
            label: 'Rental due',
            value: Formatters.formatCurrency(data.rentalDue),
            valueColor: data.rentalDue > 0 ? colors.warning : colors.success,
          ),
          if (data.rentalTripCount > 0)
            InfoRow(
              label: 'Rental trips',
              value:
                  '${data.rentalTripCount} · ${Formatters.formatDistance(data.rentalTripKm)}',
            ),
          InfoRow(
            label: 'Total cost',
            value: Formatters.formatCurrency(data.totalCost),
          ),
          if (data.averageEfficiency != null)
            InfoRow(
              label: 'Avg efficiency',
              value: Formatters.formatFuelEfficiency(data.averageEfficiency!),
              valueColor: colors.success,
            ),
          if (data.costPerKm != null)
            InfoRow(
              label: 'Cost per km',
              value: '৳ ${data.costPerKm!.toStringAsFixed(2)}/km',
            ),
          InfoRow(
            label: 'Total distance',
            value: Formatters.formatDistance(data.totalDistanceKm),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periods,
    required this.selected,
    required this.onChanged,
  });

  final List<String> periods;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((p) {
          final isSelected = p == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : colors.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : colors.divider.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      p,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
