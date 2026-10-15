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
  String _period = AppConstants.periodMonthly;
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
                    :final totalOtherCost,
                    :final totalCost,
                    :final monthlyBreakdown,
                  ) =>
                    vehicleAnalytics.isEmpty
                        ? const EmptyState(
                            icon: Icons.bar_chart_outlined,
                            title: 'No Data Yet',
                            subtitle:
                                'Add vehicles, then log fuel, maintenance or expenses.',
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _AnalyticsOverview(
                                totalFuel: totalFuelCost,
                                totalMaintenance: totalMaintenanceCost,
                                totalOther: totalOtherCost,
                                totalCost: totalCost,
                              ),
                              const SizedBox(height: 20),
                              _MonthlyTrendChart(data: monthlyBreakdown),
                              const SizedBox(height: 20),
                              if (totalCost > 0)
                                _ExpenseBreakdownPie(
                                  fuelCost: totalFuelCost,
                                  maintenanceCost: totalMaintenanceCost,
                                  otherCost: totalOtherCost,
                                ),
                              if (totalCost > 0) const SizedBox(height: 20),
                              if (vehicleAnalytics.length > 1 && totalCost > 0)
                                _CostByVehicleChart(data: vehicleAnalytics),
                              if (vehicleAnalytics.length > 1 && totalCost > 0)
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
    required this.totalOther,
    required this.totalCost,
  });
  final double totalFuel;
  final double totalMaintenance;
  final double totalOther;
  final double totalCost;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

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
                'Total cost',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                Formatters.formatCurrency(totalCost),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fuel + maintenance + other expenses in this period.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                ),
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
        StatCard(
          label: 'Other expenses',
          subtitle: 'Insurance, tax, parking, tolls…',
          value: Formatters.formatCurrency(totalOther),
          icon: Icons.receipt_long_outlined,
          color: colors.partsColor,
        ),
      ],
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
        monthBreakdownRow.otherCost,
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
            'Monthly cost by type',
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
                        toY: monthlyBreakdown.otherCost,
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
              _Legend(color: colors.partsColor, label: 'Other'),
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

class _CostByVehicleChart extends StatelessWidget {
  const _CostByVehicleChart({required this.data});
  final List<VehicleAnalytics> data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    var maxCost = 0.0;
    for (final v in data) {
      if (v.totalCost > maxCost) maxCost = v.totalCost;
    }
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
          Text('Cost by vehicle',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Fuel, maintenance and other expenses per vehicle',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCost * 1.2,
                barGroups: [
                  for (var i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].totalCost,
                          width: 18,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                          rodStackItems: [
                            BarChartRodStackItem(
                                0, data[i].fuelCost, colors.fuelColor),
                            BarChartRodStackItem(
                                data[i].fuelCost,
                                data[i].fuelCost + data[i].maintenanceCost,
                                colors.maintenanceColor),
                            BarChartRodStackItem(
                                data[i].fuelCost + data[i].maintenanceCost,
                                data[i].totalCost,
                                colors.partsColor),
                          ],
                        ),
                      ],
                    ),
                ],
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
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final name = data[i].vehicleName;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            name.length > 8 ? '${name.substring(0, 8)}…' : name,
                            style: TextStyle(
                                fontSize: 9, color: colors.textSecondary),
                          ),
                        );
                      },
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
            children: [
              _Legend(color: colors.fuelColor, label: 'Fuel'),
              _Legend(color: colors.maintenanceColor, label: 'Maintenance'),
              _Legend(color: colors.partsColor, label: 'Other'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseBreakdownPie extends StatelessWidget {
  const _ExpenseBreakdownPie(
      {required this.fuelCost,
      required this.maintenanceCost,
      required this.otherCost});
  final double fuelCost;
  final double maintenanceCost;
  final double otherCost;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final total = fuelCost + maintenanceCost + otherCost;
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
                    if (otherCost > 0)
                      PieChartSectionData(
                        value: otherCost,
                        color: colors.partsColor,
                        title:
                            '${(otherCost / total * 100).toStringAsFixed(0)}%',
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
                    const SizedBox(height: 12),
                    _PieLegendItem(
                        color: colors.partsColor,
                        label: 'Other expenses',
                        value: Formatters.formatCurrency(otherCost)),
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
          if (data.totalCost > 0) ...[
            _CostSplitBar(
                fuelCost: data.fuelCost,
                maintenanceCost: data.maintenanceCost,
                otherCost: data.otherCost),
            const SizedBox(height: 12),
          ],
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
            label: 'Other expenses',
            value: Formatters.formatCurrency(data.otherCost),
            valueColor: colors.partsColor,
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
              value: Formatters.formatCostPerDistance(data.costPerKm!),
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

class _CostSplitBar extends StatelessWidget {
  const _CostSplitBar({
    required this.fuelCost,
    required this.maintenanceCost,
    required this.otherCost,
  });
  final double fuelCost;
  final double maintenanceCost;
  final double otherCost;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fuelFlex = (fuelCost * 1000).round();
    final maintFlex = (maintenanceCost * 1000).round();
    final otherFlex = (otherCost * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (fuelFlex > 0)
              Expanded(
                  flex: fuelFlex, child: ColoredBox(color: colors.fuelColor)),
            if (maintFlex > 0)
              Expanded(
                  flex: maintFlex,
                  child: ColoredBox(color: colors.maintenanceColor)),
            if (otherFlex > 0)
              Expanded(
                  flex: otherFlex, child: ColoredBox(color: colors.partsColor)),
          ],
        ),
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
