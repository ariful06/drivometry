import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/odometer_validator.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/vehicle_usecases.dart';

/// Opens the quick odometer update sheet. Returns the updated vehicle, or
/// null when cancelled.
Future<Vehicle?> showUpdateOdometerSheet(
  BuildContext context,
  Vehicle vehicle,
) {
  return showModalBottomSheet<Vehicle>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => UpdateOdometerSheet(vehicle: vehicle),
  );
}

/// Sets the odometer without logging a fill-up, so km-based reminders stay
/// accurate between fills.
class UpdateOdometerSheet extends StatefulWidget {
  const UpdateOdometerSheet({required this.vehicle, super.key});

  final Vehicle vehicle;

  @override
  State<UpdateOdometerSheet> createState() => _UpdateOdometerSheetState();
}

class _UpdateOdometerSheetState extends State<UpdateOdometerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final odometer = double.parse(_controller.text.trim().replaceAll(',', '.'));
    final update = sl<UpdateVehicleOdometer>();
    setState(() => _isSaving = true);
    try {
      final check = await update.check(widget.vehicle, odometer);
      if (!mounted) return;
      if (check?.issue == OdometerIssue.error) {
        setState(() {
          _error = check!.message;
          _isSaving = false;
        });
        return;
      }
      if (check != null && !await _confirm(check.message)) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }
      final updated = await update(widget.vehicle, odometer);
      if (mounted) Navigator.pop(context, updated);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save: $error';
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _confirm(String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check odometer'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Edit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save anyway'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Update odometer',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Saved: ${Formatters.formatDistance(widget.vehicle.currentOdometer)}'
              ' · keeps distance-based reminders accurate between fills',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('update_odometer_field'),
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'Odometer (km)',
                hintText: widget.vehicle.currentOdometer.toStringAsFixed(0),
                prefixIcon: const Icon(Icons.speed_outlined),
                errorText: _error,
                errorMaxLines: 3,
              ),
              validator: (value) {
                final parsed = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (parsed == null) return 'Enter the dashboard reading';
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save odometer'),
            ),
          ],
        ),
      ),
    );
  }
}
