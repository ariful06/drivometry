// lib/features/fuel/presentation/widgets/fuel_entry_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/fuel_entry.dart';
import '../cubits/fuel_cubit.dart';
import '../pages/fuel_entry_detail_page.dart';

class FuelEntryTile extends StatelessWidget {
  const FuelEntryTile({
    required this.entry, super.key,
    this.previousEntry,
  });
  final FuelEntry entry;
  /// Chronologically previous refill (older). When non-null, tile shows mileage = (current distance driven) / (previous refill liters).
  final FuelEntry? previousEntry;

  /// Distance driven since previous refill. Null for the first (oldest) entry.
  double? get _distanceDriven {
    if (previousEntry == null) return null;
    final distanceSincePreviousKm =
        entry.odometer - previousEntry!.odometer;
    return distanceSincePreviousKm > 0 ? distanceSincePreviousKm : null;
  }

  /// Mileage for this tile: (current distance driven) / (previous refill liters). Null for the first (oldest) entry.
  double? get _tileMileage {
    final dist = _distanceDriven;
    if (dist == null || previousEntry == null || previousEntry!.liters <= 0) return null;
    return dist / previousEntry!.liters;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete fuel entry?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        context.read<FuelCubit>().deleteFuelEntry(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuel entry deleted')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.4),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.push(
                '/vehicles/${entry.vehicleId}/fuel/${entry.id}',
                extra: FuelEntryDetailArgs(
                  entry: entry,
                  previousEntry: previousEntry,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        Formatters.formatDate(entry.date),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.formatCurrency(entry.totalCost),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.fuelColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricChip(
                          icon: Icons.water_drop_outlined,
                          value: Formatters.formatLiters(entry.liters),
                          label: 'Refill',
                          color: colors.fuelColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricChip(
                          icon: Icons.eco_outlined,
                          value: _tileMileage != null
                              ? Formatters.formatFuelEfficiency(_tileMileage!)
                              : '—',
                          label: 'Mileage',
                          color: colors.maintenanceColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricChip(
                          icon: Icons.straighten_outlined,
                          value: _distanceDriven != null
                              ? Formatters.formatDistance(_distanceDriven!)
                              : '—',
                          label: 'Distance',
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Odometer ${Formatters.formatDistance(entry.odometer)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.extension<AppColors>()!.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
