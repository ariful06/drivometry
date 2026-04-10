import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/usecases/vehicle_usecases.dart';
import '../../domain/entities/rental_entry.dart';

/// Full read-only view of a rental booking; use AppBar Edit to adjust end KM / payment.
class RentalEntryDetailPage extends StatelessWidget {
  const RentalEntryDetailPage({required this.entry, super.key});

  final RentalEntry entry;

  String get _tripLabel {
    if (entry.tripType == 'Trip' && entry.tripLeg.isNotEmpty) {
      return '${entry.tripType} · ${entry.tripLeg}';
    }
    return entry.tripType;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final dueColor = entry.dueAmount <= 0 ? colors.success : colors.warning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental details'),
        actions: [
          IconButton(
            tooltip: 'Edit rental',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              context.push('/rentals/${entry.id}/edit', extra: entry);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: sl<GetVehicleById>()(entry.vehicleId),
        builder: (context, snapshot) {
          final vehicleLabel = snapshot.data == null
              ? entry.vehicleId
              : '${snapshot.data!.name} (${snapshot.data!.licensePlate})';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                entry.customerName,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                entry.phone,
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              _SectionTitle(theme: theme, label: 'Booking'),
              _DetailRow(label: 'Booking ID', value: Formatters.formatBookingId(entry.bookingId)),
              _DetailRow(
                label: 'Booking date',
                value: Formatters.formatDate(entry.bookingDate),
              ),
              _DetailRow(label: 'Vehicle', value: vehicleLabel),
              const SizedBox(height: 16),
              _SectionTitle(theme: theme, label: 'Trip'),
              _DetailRow(label: 'Type', value: _tripLabel),
              _DetailRow(label: 'From', value: entry.fromLocation),
              _DetailRow(label: 'To', value: entry.toLocation),
              _DetailRow(
                label: 'Start',
                value: Formatters.formatDateTime(entry.startDateTime),
              ),
              _DetailRow(
                label: 'End',
                value: Formatters.formatDateTime(entry.endDateTime),
              ),
              const SizedBox(height: 16),
              _SectionTitle(theme: theme, label: 'Odometer'),
              _DetailRow(
                label: 'Start KM',
                value: Formatters.formatDistance(entry.startKm),
              ),
              _DetailRow(
                label: 'End KM',
                value: Formatters.formatDistance(entry.endKm),
              ),
              _DetailRow(
                label: 'Total KM',
                value: Formatters.formatDistance(entry.totalKm),
              ),
              const SizedBox(height: 16),
              _SectionTitle(theme: theme, label: 'Financials'),
              _DetailRow(
                label: 'Rent / fare',
                value: Formatters.formatCurrency(entry.rentFareAmount),
              ),
              _DetailRow(
                label: 'Advance',
                value: Formatters.formatCurrency(entry.advanceReceived),
              ),
              _DetailRow(
                label: 'Due',
                value: Formatters.formatCurrency(entry.dueAmount),
                valueColor: dueColor,
              ),
              _DetailRow(label: 'Payment', value: entry.paymentStatus),
              _DetailRow(
                label: 'Fuel provided by',
                value: entry.fuelProvidedBy,
              ),
              _DetailRow(
                label: 'Fuel cost',
                value: Formatters.formatCurrency(entry.fuelCost),
              ),
              if (entry.customerPaidFuelBill)
                const _DetailRow(
                  label: 'Customer fuel',
                  value: 'Reduces billable amount',
                ),
              const SizedBox(height: 16),
              _SectionTitle(theme: theme, label: 'Driver'),
              _DetailRow(label: 'Mode', value: entry.driverMode),
              if (entry.driverMode == 'Driver' && (entry.driverName ?? '').trim().isNotEmpty)
                _DetailRow(label: 'Name', value: entry.driverName!.trim()),
              if (entry.driverMode == 'Driver' && (entry.driverPhone ?? '').trim().isNotEmpty)
                _DetailRow(label: 'Phone', value: entry.driverPhone!.trim()),
              if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionTitle(theme: theme, label: 'Notes'),
                Text(
                  entry.notes!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.theme, required this.label});

  final ThemeData theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
