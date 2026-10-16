import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/vehicle_usecases.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/entities/vehicle.dart';

/// Wrapper that resolves [Vehicle] by id when not passed as [extra].
class VehicleDetailsRoutePage extends StatelessWidget {
  const VehicleDetailsRoutePage({
    required this.vehicleId,
    super.key,
    this.vehicle,
  });
  final String vehicleId;
  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    if (vehicle != null) {
      return VehicleDetailsPage(vehicle: vehicle!);
    }
    return FutureBuilder<Vehicle?>(
      future: sl<GetVehicleById>()(vehicleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final v = snapshot.data;
        if (v == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Vehicle not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }
        return VehicleDetailsPage(vehicle: v);
      },
    );
  }
}

/// Standalone vehicle details screen (info + documents).
/// Edit button opens the edit vehicle page; returning with updated vehicle refreshes this screen.
class VehicleDetailsPage extends StatefulWidget {
  const VehicleDetailsPage({required this.vehicle, super.key});
  final Vehicle vehicle;

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  late Vehicle _vehicle;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  @override
  void didUpdateWidget(covariant VehicleDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vehicle.id != oldWidget.vehicle.id) {
      _vehicle = widget.vehicle;
    }
  }

  Future<void> _openEdit() async {
    final updated = await context.push<Vehicle?>(
      '/vehicles/${_vehicle.id}/edit',
      extra: _vehicle,
    );
    if (updated != null && mounted) {
      setState(() => _vehicle = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final vehicle = _vehicle;
    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _VehicleDetailsHeader(vehicle: vehicle),
          const SizedBox(height: 24),
          _DetailRow(label: 'Type', value: vehicle.type),
          _DetailRow(label: 'Make', value: vehicle.make),
          _DetailRow(label: 'Model', value: vehicle.model),
          _DetailRow(label: 'Year', value: '${vehicle.year}'),
          _DetailRow(label: 'License plate', value: vehicle.licensePlate),
          _DetailRow(
            label: 'Odometer',
            value: Formatters.formatDistance(vehicle.currentOdometer),
          ),
          if (vehicle.tankCapacityLiters != null)
            _DetailRow(
              label: 'Tank capacity',
              value:
                  '${Formatters.formatNumber(vehicle.tankCapacityLiters!)} L',
            ),
          if (vehicle.color != null && vehicle.color!.isNotEmpty)
            _DetailRow(label: 'Color', value: vehicle.color!),
          if (vehicle.notes != null && vehicle.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vehicle.notes!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (vehicle.registrationImagePath != null ||
              vehicle.taxTokenImagePath != null) ...[
            const SizedBox(height: 24),
            Text(
              'Documents',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (vehicle.registrationImagePath != null)
              _DocumentImageCard(
                label: 'Registration',
                path: vehicle.registrationImagePath!,
              ),
            if (vehicle.registrationImagePath != null &&
                vehicle.taxTokenImagePath != null)
              const SizedBox(height: 12),
            if (vehicle.taxTokenImagePath != null)
              _DocumentImageCard(
                label: 'Tax token',
                path: vehicle.taxTokenImagePath!,
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Edit'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleDetailsHeader extends StatelessWidget {
  const _VehicleDetailsHeader({required this.vehicle});
  final Vehicle vehicle;

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '${vehicle.year} • ${vehicle.licensePlate}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentImageCard extends StatelessWidget {
  const _DocumentImageCard({required this.label, required this.path});
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    final colors = Theme.of(context).extension<AppColors>()!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
            ),
          ),
          if (file.existsSync())
            GestureDetector(
              onTap: () => _showFullScreenImage(context, path),
              child: Image.file(
                file,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String path) {
    final file = File(path);
    if (!file.existsSync()) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(label),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(file, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
