import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/rental_entry.dart';
import '../cubits/rental_cubit.dart';

class RentalEntryTile extends StatelessWidget {
  const RentalEntryTile({required this.entry, super.key});
  final RentalEntry entry;

  String get _tripLabel {
    if (entry.tripType == 'Trip' && entry.tripLeg.isNotEmpty) {
      return '${entry.tripType} · ${entry.tripLeg}';
    }
    return entry.tripType;
  }

  String get _driverLine {
    if (entry.driverMode == 'Driver' && (entry.driverName ?? '').trim().isNotEmpty) {
      return 'Driver: ${entry.driverName!.trim()}';
    }
    if (entry.driverMode == 'Self') return 'Driver: Self';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final dueColor = entry.dueAmount <= 0 ? colors.success : colors.warning;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete rental entry?'),
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
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        context.read<RentalCubit>().deleteRental(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rental entry deleted')),
        );
      },
      child: Material(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/rentals/${entry.id}', extra: entry),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.customerName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.phone,
                              style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tripLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(entry.rentFareAmount),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.fuelColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${Formatters.formatDate(entry.bookingDate)} · ${entry.fromLocation} → ${entry.toLocation}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(
                        context,
                        label: 'Booking',
                        value: Formatters.formatBookingId(entry.bookingId),
                        color: colors.textSecondary,
                      ),
                      _chip(
                        context,
                        label: 'KM',
                        value: Formatters.formatDistance(entry.totalKm),
                        color: colors.maintenanceColor,
                      ),
                      _chip(
                        context,
                        label: 'Due',
                        value: Formatters.formatCurrency(entry.dueAmount),
                        color: dueColor,
                      ),
                      _chip(
                        context,
                        label: 'Status',
                        value: entry.paymentStatus,
                        color: entry.paymentStatus == 'Paid'
                            ? colors.success
                            : entry.paymentStatus == 'Due'
                                ? colors.warning
                                : colors.maintenanceColor,
                      ),
                      if (entry.fuelCost > 0)
                        _chip(
                          context,
                          label: 'Fuel',
                          value: Formatters.formatCurrency(entry.fuelCost),
                          color: colors.fuelColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_driverLine.isNotEmpty ? '$_driverLine · ' : ''}'
                    'Fuel: ${entry.fuelProvidedBy}'
                    '${entry.customerPaidFuelBill || entry.fuelProvidedBy == 'Customer' ? ' · Reduces billable' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                  ),
                  if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
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

  Widget _chip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
