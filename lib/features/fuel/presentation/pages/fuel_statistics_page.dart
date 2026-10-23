import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/repositories/fuel_repository.dart';
import '../../domain/services/fuel_statistics.dart';

enum _StatsRange {
  last3Months('3 months'),
  last12Months('12 months'),
  lifetime('Lifetime');

  const _StatsRange(this.label);
  final String label;

  DateTime from(DateTime now) => switch (this) {
        _StatsRange.last3Months => DateTime(now.year, now.month - 2),
        _StatsRange.last12Months => DateTime(now.year, now.month - 11),
        _StatsRange.lifetime => DateTime(2000),
      };
}

class FuelStatisticsPage extends StatefulWidget {
  const FuelStatisticsPage({required this.vehicle, super.key});
  final Vehicle vehicle;

  @override
  State<FuelStatisticsPage> createState() => _FuelStatisticsPageState();
}

class _FuelStatisticsPageState extends State<FuelStatisticsPage> {
  _StatsRange _range = _StatsRange.last12Months;
  late final Future<FuelStatistics Function(_StatsRange)> _loader = _load();

  Future<FuelStatistics Function(_StatsRange)> _load() async {
    final entries =
        await sl<FuelRepository>().getFuelEntriesByVehicle(widget.vehicle.id);
    return (range) {
      final now = DateTime.now();
      return FuelStatistics.compute(
        entries,
        from: range.from(now),
        to: now,
        tankCapacityLiters: widget.vehicle.tankCapacityLiters,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.vehicle.name} · Fuel stats')),
      body: FutureBuilder(
        future: _loader,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) return const LoadingOverlay();
          final stats = snapshot.data!(_range);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final range in _StatsRange.values)
                    ChoiceChip(
                      label: Text(
                        range.label,
                        style: TextStyle(
                          color: range == _range
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selectedColor: Theme.of(context).colorScheme.primary,
                      checkmarkColor: Colors.white,
                      selected: range == _range,
                      onSelected: (_) => setState(() => _range = range),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (stats.isEmpty)
                const EmptyState(
                  icon: Icons.local_gas_station_outlined,
                  title: 'No fuel entries in this range',
                  subtitle: 'Log a fill-up or pick a longer range.',
                )
              else ...[
                _SummaryGrid(stats: stats),
                const SizedBox(height: 20),
                _MonthlySpendChart(data: stats.monthly),
                const SizedBox(height: 20),
                _EconomyTrendChart(stats: stats),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats});
  final FuelStatistics stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final settings = AppSettings.instance;
    // Price is stored per litre; show per displayed volume unit.
    final pricePerVolume = stats.averagePricePerLiter == null
        ? '—'
        : '${settings.currencySymbol} ${(stats.averagePricePerLiter! * (settings.volumeUnit == VolumeUnit.gallon ? AppSettings.litersPerGallon : 1)).toStringAsFixed(2)}/${settings.volumeLabel}';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Fuel spend',
                value: Formatters.formatCurrency(stats.totalCost),
                icon: Icons.payments_outlined,
                color: colors.fuelColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: 'Fuel bought',
                value: Formatters.formatLiters(stats.totalLiters),
                icon: Icons.local_gas_station_outlined,
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
                label: 'Avg price',
                value: pricePerVolume,
                icon: Icons.sell_outlined,
                color: colors.partsColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: 'Cost per distance',
                value: stats.fuelCostPerKm == null
                    ? '—'
                    : Formatters.formatCostPerDistance(stats.fuelCostPerKm!),
                icon: Icons.route_outlined,
                color: colors.success,
              ),
            ),
          ],
        ),
        if (stats.best != null && stats.worst != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Best economy',
                  subtitle: Formatters.formatDate(stats.best!.date),
                  value:
                      Formatters.formatFuelEfficiency(stats.best!.kmPerLiter),
                  icon: Icons.trending_up,
                  color: colors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  label: 'Worst economy',
                  subtitle: Formatters.formatDate(stats.worst!.date),
                  value:
                      Formatters.formatFuelEfficiency(stats.worst!.kmPerLiter),
                  icon: Icons.trending_down,
                  color: colors.warning,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

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
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MonthlySpendChart extends StatelessWidget {
  const _MonthlySpendChart({required this.data});
  final List<FuelMonthlySpend> data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    var maxCost = 0.0;
    for (final m in data) {
      if (m.cost > maxCost) maxCost = m.cost;
    }
    return _ChartCard(
      title: 'Monthly fuel spend',
      subtitle: 'Total paid for fuel each month',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxCost <= 0 ? 1 : maxCost * 1.2,
            barGroups: [
              for (var i = 0; i < data.length; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: data[i].cost,
                    color: colors.fuelColor,
                    width: 14,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ]),
            ],
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= data.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(DateFormat('MMM').format(data[i].month),
                        style: TextStyle(
                            fontSize: 9, color: colors.textSecondary));
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                  color: colors.divider.withValues(alpha: 0.5), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}

class _EconomyTrendChart extends StatelessWidget {
  const _EconomyTrendChart({required this.stats});
  final FuelStatistics stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final trend = stats.trend;
    if (trend.isEmpty) {
      return const _ChartCard(
        title: 'Economy trend',
        subtitle: 'Needs two full-tank fills to measure',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Not enough fills yet')),
        ),
      );
    }
    final values = [
      for (final p in trend)
        Formatters.distanceToDisplay(p.kmPerLiter) /
            Formatters.volumeToDisplay(1),
    ];
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final minY = values.reduce((a, b) => a < b ? a : b);
    return _ChartCard(
      title: 'Economy trend',
      subtitle: 'Per measured period; hollow dots are estimated',
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: (minY * 0.9).floorToDouble(),
            maxY: (maxY * 1.1).ceilToDouble(),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < values.length; i++)
                    FlSpot(i.toDouble(), values[i]),
                ],
                isCurved: false,
                color: colors.success,
                barWidth: 3,
                dotData: FlDotData(
                  getDotPainter: (spot, _, __, index) => FlDotCirclePainter(
                    radius: 4,
                    color: trend[index].isEstimated
                        ? Colors.transparent
                        : colors.success,
                    strokeWidth: 2,
                    strokeColor: colors.success,
                  ),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                      style:
                          TextStyle(fontSize: 9, color: colors.textSecondary)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval:
                      trend.length > 6 ? (trend.length / 5).ceilToDouble() : 1,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= trend.length || value != i) {
                      return const SizedBox.shrink();
                    }
                    return Text(DateFormat('d MMM').format(trend[i].date),
                        style: TextStyle(
                            fontSize: 9, color: colors.textSecondary));
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                  color: colors.divider.withValues(alpha: 0.5), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}
