// lib/features/vehicles/presentation/widgets/vehicle_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/entities/vehicle.dart';
import 'vehicle_dashboard_metrics.dart';

/// Fintech-style vehicle summary: costs, income, profit, health bar, status badge.
class VehicleDashboardListTile extends StatelessWidget {
  const VehicleDashboardListTile({
    required this.vehicle,
    required this.metrics,
    super.key,
  });
  final Vehicle vehicle;
  final VehicleDashboardMetrics metrics;

  static const _accentBlue = Color(0xFF2563EB);
  static const _accentGreen = Color(0xFF16A34A);
  static const _accentRed = Color(0xFFDC2626);
  static const _accentAmber = Color(0xFFD97706);

  static double _maintenanceHealthFraction(
      VehicleDashboardMetrics m, Vehicle vehicle) {
    var h = 1.0 - (m.partWarningsCount * 0.18).clamp(0.0, 0.65);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fit = vehicle.fitnessExpiryDate;
    if (fit != null) {
      final fd = DateTime(fit.year, fit.month, fit.day);
      if (fd.isBefore(today)) {
        h -= 0.35;
      } else if (fd.difference(today).inDays <= 30) {
        h -= 0.1;
      }
    }
    return h.clamp(0.08, 1.0);
  }

  static ({String label, Color bg, Color fg}) _statusForHealth(double health) {
    if (health >= 0.75) {
      return (
        label: 'Optimal',
        bg: _accentGreen.withValues(alpha: 0.12),
        fg: _accentGreen,
      );
    }
    if (health >= 0.45) {
      return (
        label: 'Fair',
        bg: _accentBlue.withValues(alpha: 0.12),
        fg: _accentBlue,
      );
    }
    return (
      label: 'At risk',
      bg: _accentRed.withValues(alpha: 0.12),
      fg: _accentRed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final health = _maintenanceHealthFraction(metrics, vehicle);
    final status = _statusForHealth(health);
    final profit = metrics.rentalIncome - metrics.totalOperatingCost;
    final profitPositive = profit >= 0;

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.45)
        : const Color(0xFF1A2B4A).withValues(alpha: 0.07);
    final borderColor = isDark
        ? colors.divider.withValues(alpha: 0.55)
        : const Color(0xFFE8ECF2);

    final err = theme.colorScheme.error;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fitness = vehicle.fitnessExpiryDate;
    DateTime? fitnessDay;
    if (fitness != null) {
      fitnessDay = DateTime(fitness.year, fitness.month, fitness.day);
    }
    final fitnessExpired = fitnessDay != null && fitnessDay.isBefore(today);
    int? daysUntilFitness;
    if (fitnessDay != null && !fitnessExpired) {
      daysUntilFitness = fitnessDay.difference(today).inDays;
    }
    final fitnessSoon = daysUntilFitness != null &&
        daysUntilFitness >= 0 &&
        daysUntilFitness <= 30;

    final barFill = Color.lerp(_accentRed, _accentGreen, health)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/vehicles/${vehicle.id}', extra: vehicle),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: VehicleTypeIcon(
                            vehicleType: vehicle.type,
                            size: 26,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${vehicle.make} ${vehicle.model}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _StatusBadge(
                                  label: status.label,
                                  background: status.bg,
                                  foreground: status.fg,
                                ),
                                _OdometerChip(
                                  odometer: Formatters.formatDistance(
                                      vehicle.currentOdometer),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.chevron_right_rounded,
                            color: colors.textSecondary, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined,
                          size: 16, color: colors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Maintenance health',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(health * 100).round()}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: barFill,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          color: colors.divider
                              .withValues(alpha: isDark ? 0.35 : 0.55),
                        ),
                        LayoutBuilder(
                          builder: (context, c) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 8,
                                width: c.maxWidth * health,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: [
                                      barFill.withValues(alpha: 0.85),
                                      barFill,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _StatRow(
                    icon: Icons.local_gas_station_rounded,
                    iconColor: _accentBlue,
                    label: 'Fuel cost',
                    value: Formatters.formatCurrency(metrics.fuelCost),
                    valueColor: _accentBlue,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    icon: Icons.build_circle_outlined,
                    iconColor: _accentRed,
                    label: 'Maintenance',
                    value: Formatters.formatCurrency(metrics.maintenanceCost),
                    valueColor: _accentRed,
                  ),
                  if (vehicle.isRental) ...[
                    const SizedBox(height: 12),
                    _StatRow(
                      icon: Icons.payments_outlined,
                      iconColor: _accentGreen,
                      label: 'Rental income',
                      value: Formatters.formatCurrency(metrics.rentalIncome),
                      valueColor: _accentGreen,
                    ),
                    Divider(
                        height: 26,
                        color: colors.divider.withValues(alpha: 0.5)),
                    _StatRow(
                      icon: profitPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      iconColor: profitPositive ? _accentGreen : _accentRed,
                      label: 'Total profit',
                      value: Formatters.formatCurrency(profit),
                      valueColor: profitPositive ? _accentGreen : _accentRed,
                    ),
                  ],
                  if (metrics.closestServiceSummary != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event_available_outlined,
                            size: 16, color: _accentAmber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            metrics.closestServiceRemaining == null
                                ? 'Service: ${metrics.closestServiceSummary}'
                                : 'Service: ${metrics.closestServiceSummary} · ${metrics.closestServiceRemaining}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (metrics.hasUrgentServiceAttention) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => context.push(
                          '/vehicles/${vehicle.id}/maintenance/add',
                          extra: vehicle),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _accentAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _accentAmber.withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 18, color: _accentAmber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                metrics.serviceAttentionItemsLabel == null
                                    ? '${metrics.serviceAttentionCount} service item(s) due soon/overdue. Tap to add maintenance.'
                                    : '${metrics.serviceAttentionCount} service item(s): ${metrics.serviceAttentionItemsLabel}. Tap to add maintenance.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _accentAmber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: _accentAmber),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (fitness != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: fitnessExpired
                              ? err
                              : (fitnessSoon
                                  ? _accentAmber
                                  : colors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fitnessExpired
                                ? 'Fitness expired · ${Formatters.formatDate(fitness)}'
                                : 'Fitness · ${Formatters.formatDate(fitness)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  fitnessExpired ? err : colors.textSecondary,
                              fontWeight: fitnessExpired
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _OdometerChip extends StatelessWidget {
  const _OdometerChip({required this.odometer});

  final String odometer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.divider.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, size: 14, color: colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            odometer,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.2,
              ),
        ),
      ],
    );
  }
}
