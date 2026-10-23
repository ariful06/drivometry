import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/usecases/vehicle_usecases.dart';
import '../../domain/entities/fuel_entry.dart';
import '../../domain/services/fuel_consumption_calculator.dart';
import '../../domain/usecases/fuel_usecases.dart';
import 'add_fuel_entry_page.dart';

/// Passed via GoRouter `extra` when opening [FuelEntryDetailPage].
class FuelEntryDetailArgs {
  const FuelEntryDetailArgs({
    required this.entry,
    this.previousEntry,
    this.consumption,
  });

  final FuelEntry entry;

  /// Chronologically older refill; used for distance since previous fill.
  final FuelEntry? previousEntry;

  /// Full-tank period this fill closes, if any.
  final FuelConsumptionSegment? consumption;
}

/// Fuel log with receipt when available; can be edited or deleted.
class FuelEntryDetailPage extends StatefulWidget {
  const FuelEntryDetailPage({required this.args, super.key});

  final FuelEntryDetailArgs args;

  @override
  State<FuelEntryDetailPage> createState() => _FuelEntryDetailPageState();
}

class _FuelEntryDetailPageState extends State<FuelEntryDetailPage> {
  late Future<Vehicle?> _vehicleFuture;
  late Future<bool> _receiptFuture;

  /// Starts as [FuelEntryDetailPage.args]; reloaded after an edit.
  late FuelEntryDetailArgs args = widget.args;

  FuelEntry get _e => args.entry;

  double? get _periodDistanceKm {
    final prev = args.previousEntry;
    if (prev == null) return null;
    final distanceDeltaKm = _e.odometer - prev.odometer;
    return distanceDeltaKm > 0 ? distanceDeltaKm : null;
  }

  @override
  void initState() {
    super.initState();
    _vehicleFuture = sl<GetVehicleById>()(_e.vehicleId);
    _receiptFuture = _checkReceipt();
  }

  Future<bool> _checkReceipt() {
    final receiptImagePath = _e.receiptImagePath;
    return (receiptImagePath == null || receiptImagePath.isEmpty)
        ? Future.value(false)
        : Future.value(File(receiptImagePath).existsSync());
  }

  Future<void> _edit() async {
    final vehicle = await _vehicleFuture;
    if (vehicle == null || !mounted) return;
    final edited = await context.push<FuelEntry>(
      '/vehicles/${_e.vehicleId}/fuel/${_e.id}/edit',
      extra: FuelEntryEditArgs(vehicle: vehicle, entry: _e),
    );
    if (edited != null && mounted) await _reload();
  }

  /// Re-reads the fill, its neighbour and consumption after an edit.
  Future<void> _reload() async {
    final vehicleFuture = sl<GetVehicleById>()(_e.vehicleId);
    final entries = await sl<GetFuelEntriesByVehicle>()(_e.vehicleId);
    final vehicle = await vehicleFuture;
    final ordered = FuelConsumptionCalculator.sortChronologically(entries);
    final index = ordered.indexWhere((entry) => entry.id == _e.id);
    if (index < 0 || !mounted) return;
    final entry = ordered[index];
    setState(() {
      args = FuelEntryDetailArgs(
        entry: entry,
        previousEntry: index > 0 ? ordered[index - 1] : null,
        consumption: FuelConsumptionCalculator.segmentsByEntryId(
          entries,
          tankCapacityLiters: vehicle?.tankCapacityLiters,
        )[entry.id],
      );
      _vehicleFuture = Future.value(vehicle);
      _receiptFuture = _checkReceipt();
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete fuel entry?'),
        content: const Text(
          'Consumption and the vehicle odometer will be recalculated. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sl<RemoveFuelEntry>()(_e);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Fuel entry deleted')),
      );
      context.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete: $error')),
      );
    }
  }

  void _openReceiptFullscreen(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Could not load image',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel log'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<Vehicle?>(
        future: _vehicleFuture,
        builder: (context, vehicleSnap) {
          final vehicleLabel = vehicleSnap.data == null
              ? _e.vehicleId
              : '${vehicleSnap.data!.name} (${vehicleSnap.data!.licensePlate})';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _HeaderCard(
                colors: colors,
                theme: theme,
                date: _e.date,
                totalCost: _e.totalCost,
                vehicleLabel: vehicleLabel,
              ),
              const SizedBox(height: 24),
              _SectionTitle(theme: theme, label: 'Fill-up'),
              _DetailRow(
                label: 'Liters',
                value: Formatters.formatLiters(_e.liters),
              ),
              _DetailRow(
                label: 'Price / L',
                value: Formatters.formatCurrency(_e.costPerLiter),
              ),
              _DetailRow(
                label: 'Total',
                value: Formatters.formatCurrency(_e.totalCost),
                valueColor: colors.fuelColor,
              ),
              _DetailRow(
                label: 'Full tank',
                value: _e.isFullTank ? 'Yes' : 'No (partial)',
              ),
              if (_e.fuelLevelPercent != null)
                _DetailRow(
                  label: 'Fuel level after fill',
                  value: '${_e.fuelLevelPercent!.toStringAsFixed(0)} %',
                ),
              if (_e.missedPreviousFill)
                const _DetailRow(
                  label: 'Missed previous fill',
                  value: 'Yes',
                ),
              if (_e.tripDistance != null && _e.tripDistance! > 0)
                _DetailRow(
                  label: 'Trip (logged)',
                  value: Formatters.formatDistance(_e.tripDistance!),
                ),
              const SizedBox(height: 16),
              _SectionTitle(theme: theme, label: 'Odometer & driving'),
              _DetailRow(
                label: 'Odometer',
                value: Formatters.formatDistance(_e.odometer),
              ),
              if (_e.distanceDriven != null && _e.distanceDriven! > 0)
                _DetailRow(
                  label: 'Distance (logged)',
                  value: Formatters.formatDistance(_e.distanceDriven!),
                ),
              if (_periodDistanceKm != null)
                _DetailRow(
                  label: 'Since previous fill',
                  value: Formatters.formatDistance(_periodDistanceKm!),
                ),
              if (args.consumption case final segment?) ...[
                _DetailRow(
                  label: segment.isEstimated
                      ? 'Consumption (estimated)'
                      : 'Consumption',
                  value: Formatters.formatFuelEfficiency(segment.kmPerLiter),
                  valueColor: colors.maintenanceColor,
                ),
                _DetailRow(
                  label: 'Per 100 km',
                  value: '${segment.litersPer100Km.toStringAsFixed(1)} L',
                ),
                _DetailRow(
                  label: segment.isEstimated
                      ? 'Since previous fill'
                      : 'Since last full tank',
                  value: '${Formatters.formatDistance(segment.distanceKm)} · '
                      '${Formatters.formatLiters(segment.liters)}'
                      '${segment.includesPartialFills ? ' (${segment.fillCount} fills)' : ''}',
                ),
              ] else
                _DetailRow(
                  label: 'Consumption',
                  value: _e.isFullTank
                      ? 'Needs a previous full tank'
                      : 'Counted at next full tank',
                ),
              const SizedBox(height: 16),
              _SectionTitle(theme: theme, label: 'Receipt'),
              FutureBuilder<bool>(
                future: _receiptFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  if (snap.data != true || _e.receiptImagePath == null) {
                    return Text(
                      'No receipt attached',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    );
                  }
                  final path = _e.receiptImagePath!;
                  return _ReceiptCard(
                    colors: colors,
                    path: path,
                    onTap: () => _openReceiptFullscreen(context, path),
                  );
                },
              ),
              if (_e.notes != null && _e.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionTitle(theme: theme, label: 'Notes'),
                Text(
                  _e.notes!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.colors,
    required this.theme,
    required this.date,
    required this.totalCost,
    required this.vehicleLabel,
  });

  final AppColors colors;
  final ThemeData theme;
  final DateTime date;
  final double totalCost;
  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colors.fuelColor.withValues(alpha: 0.22),
                  colors.fuelColor.withValues(alpha: 0.08),
                ]
              : [
                  colors.fuelColor.withValues(alpha: 0.16),
                  colors.fuelColor.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.fuelColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.formatDate(date),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(totalCost),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.fuelColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 18,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vehicleLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.colors,
    required this.path,
    required this.onTap,
  });

  final AppColors colors;
  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.fuelColor.withValues(alpha: 0.25),
            ),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: colors.fuelColor.withValues(alpha: 0.08),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.zoom_in_map_rounded,
                      size: 20,
                      color: colors.fuelColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap to zoom and pan',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.fuelColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            width: 132,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
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
