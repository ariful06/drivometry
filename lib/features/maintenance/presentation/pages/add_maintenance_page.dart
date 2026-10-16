// lib/features/maintenance/presentation/pages/add_maintenance_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/maintenance_parts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../notifications/domain/notification_service.dart';
import '../../domain/entities/maintenance_entry.dart';
import '../../domain/usecases/maintenance_usecases.dart';
import '../cubits/add_maintenance_cubit.dart';

class AddMaintenancePage extends StatefulWidget {
  const AddMaintenancePage({required this.vehicle, super.key});
  final Vehicle vehicle;

  @override
  State<AddMaintenancePage> createState() => _AddMaintenancePageState();
}

class _AddMaintenancePageState extends State<AddMaintenancePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _nextOdometerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _odometerCtrl.text = widget.vehicle.currentOdometer.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    _odometerCtrl.dispose();
    _nextOdometerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddMaintenanceCubit(vehicle: widget.vehicle),
      child: BlocBuilder<AddMaintenanceCubit, AddMaintenanceState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Log Maintenance')),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _RepairTypeRow(
                    selected: state.type,
                    onChanged: (v) =>
                        context.read<AddMaintenanceCubit>().setType(v),
                  ),
                  const SizedBox(height: 16),
                  _PartsChipsSection(
                    partsByCategory: state.type == 'repair'
                        ? filterPartsForRepair(state.partsByCategory)
                        : state.partsByCategory,
                    selectedParts: state.selectedParts,
                    partLifespansKm: state.partLifespansKm,
                    onPartTap: (part) => _onPartChipTap(context, part),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Additional notes (optional)',
                      hintText: 'Any other details...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.type == 'repair')
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Cost *',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _odometerCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Odometer *',
                              prefixIcon: Icon(Icons.speed_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Parts change: per-part costs list and total summary.
                    _PerPartCostsSection(
                      selectedParts: state.selectedParts,
                      partCosts: state.partCosts,
                      onCostChanged: (part, value) => context
                          .read<AddMaintenanceCubit>()
                          .setPartCost(part, value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _odometerCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Odometer *',
                        prefixIcon: Icon(Icons.speed_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DatePickerTile(
                    label: 'Service Date',
                    date: state.serviceDate,
                    onTap: () => _pickDate(context, forNext: false),
                  ),
                  const SizedBox(height: 12),
                  _DatePickerTile(
                    label: 'Next Service Date (Optional)',
                    date: state.nextServiceDate,
                    onTap: () => _pickDate(context, forNext: true),
                    isOptional: true,
                    onClear: state.nextServiceDate != null
                        ? () => context
                            .read<AddMaintenanceCubit>()
                            .setNextServiceDate(null)
                        : null,
                  ),
                  if (state.partLifespansKm.isEmpty) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nextOdometerCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Next Service Odometer (Optional)',
                        prefixIcon: Icon(Icons.speed_outlined),
                        hintText: 'e.g. 20000',
                      ),
                    ),
                  ],
                  if (state.partLifespansKm.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Next service odometer will be calculated from current odometer + part lifespan(s).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .extension<AppColors>()
                                ?.textSecondary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.isSaving ? null : () => _submit(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state.isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Maintenance'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onPartChipTap(BuildContext context, String part) async {
    final cubit = context.read<AddMaintenanceCubit>();
    final state = cubit.state;
    if (state.selectedParts.contains(part)) {
      cubit.togglePart(part);
      return;
    }
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => _LifespanDialog(partName: part),
    );
    if (!context.mounted) return;
    if (result == null) return;
    if (result > 0) cubit.setPartLifespanKm(part, result);
    cubit.togglePart(part);
  }

  Future<void> _pickDate(BuildContext context, {required bool forNext}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: forNext ? DateTime.now() : DateTime(2000),
      lastDate: forNext ? DateTime(2100) : DateTime.now(),
    );
    if (picked != null && mounted) {
      final cubit = context.read<AddMaintenanceCubit>();
      if (forNext) {
        cubit.setNextServiceDate(picked);
      } else {
        cubit.setServiceDate(picked);
      }
    }
  }

  Future<void> _submit(BuildContext context) async {
    final state = context.read<AddMaintenanceCubit>().state;
    if (state.selectedParts.isEmpty && _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one item or add notes.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    context.read<AddMaintenanceCubit>().setSaving(true);

    try {
      int? notificationId;
      final nextDate = state.nextServiceDate;
      if (nextDate != null) {
        final reminderDate = nextDate.subtract(const Duration(days: 1));
        if (reminderDate.isAfter(DateTime.now())) {
          notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          await sl<NotificationService>().scheduleMaintenanceReminder(
            id: notificationId,
            title: 'Upcoming Service: ${_titleCtrl.text.trim()}',
            body: 'Service due tomorrow for ${widget.vehicle.name}!',
            scheduledDate: reminderDate,
          );
        }
      }

      // Build description from selected chips + optional notes.
      final partsList = state.selectedParts.toList()..sort();
      String description = '';
      if (partsList.isNotEmpty) {
        description = partsList.join('\n');
      }
      if (_descCtrl.text.trim().isNotEmpty) {
        if (description.isNotEmpty) {
          description += '\n';
        }
        description += _descCtrl.text.trim();
      }

      final currentOdo = double.parse(_odometerCtrl.text.trim()).round();
      int? nextServiceOdometer;
      if (state.partLifespansKm.isNotEmpty && state.selectedParts.isNotEmpty) {
        final minLifespan = state.partLifespansKm.values.reduce(
          (minimumKmSoFar, lifespanKmForPart) =>
              lifespanKmForPart < minimumKmSoFar
                  ? lifespanKmForPart
                  : minimumKmSoFar,
        );
        nextServiceOdometer = currentOdo + minLifespan;
      } else if (_nextOdometerCtrl.text.trim().isNotEmpty) {
        nextServiceOdometer = int.tryParse(_nextOdometerCtrl.text.trim());
      }

      final entry = MaintenanceEntry(
        id: const Uuid().v4(),
        vehicleId: widget.vehicle.id,
        type: state.type,
        title: _titleCtrl.text.trim().isEmpty
            ? (state.type == 'repair' ? 'Repair' : 'Parts change')
            : _titleCtrl.text.trim(),
        description: description,
        cost: state.type == 'repair'
            ? double.parse(_costCtrl.text.trim())
            : context.read<AddMaintenanceCubit>().partsTotalCost,
        odometer: double.parse(_odometerCtrl.text.trim()),
        serviceDate: state.serviceDate,
        nextServiceDate: state.nextServiceDate,
        nextServiceOdometer: nextServiceOdometer,
        notes: null,
        notificationId: notificationId,
      );

      await sl<AddMaintenance>()(entry);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        context.read<AddMaintenanceCubit>().setSaving(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _RepairTypeRow extends StatelessWidget {
  const _RepairTypeRow({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Expanded(
          child: _RepairTypeOption(
            label: 'Repair',
            icon: Icons.build_outlined,
            isSelected: selected == 'repair',
            primary: primary,
            background: colors.cardBackground,
            onTap: () => onChanged('repair'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RepairTypeOption(
            label: 'Parts change',
            icon: Icons.settings_outlined,
            isSelected: selected == 'parts',
            primary: primary,
            background: colors.cardBackground,
            onTap: () => onChanged('parts'),
          ),
        ),
      ],
    );
  }
}

class _RepairTypeOption extends StatelessWidget {
  const _RepairTypeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.primary,
    required this.background,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color primary;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary : background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primary : primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : primary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartsChipsSection extends StatelessWidget {
  const _PartsChipsSection({
    required this.partsByCategory,
    required this.selectedParts,
    required this.partLifespansKm,
    required this.onPartTap,
  });
  final PartsByCategory partsByCategory;
  final Set<String> selectedParts;
  final Map<String, int> partLifespansKm;
  final ValueChanged<String> onPartTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select parts (tap to add; set lifespan in km for next service)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...partsByCategory.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    entry.key,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value
                      .map((part) => _PartChip(
                            label: part,
                            selected: selectedParts.contains(part),
                            lifespanKm: partLifespansKm[part],
                            onTap: () => onPartTap(part),
                          ))
                      .toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PartChip extends StatelessWidget {
  const _PartChip({
    required this.label,
    required this.selected,
    this.lifespanKm,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final int? lifespanKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).extension<AppColors>()!;
    final fillColor = colors.maintenanceColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? fillColor : fillColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? fillColor : fillColor.withValues(alpha: 0.35),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : colors.textSecondary,
                ),
              ),
              if (selected && lifespanKm != null) ...[
                const SizedBox(width: 6),
                Text(
                  '· ${lifespanKm!} km',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LifespanDialog extends StatefulWidget {
  const _LifespanDialog({required this.partName});
  final String partName;

  @override
  State<_LifespanDialog> createState() => _LifespanDialogState();
}

class _LifespanDialogState extends State<_LifespanDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Part lifespan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.partName}\nWhen should this part be serviced again?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Lifespan (km, optional)',
              hintText: 'e.g. 5000',
              suffixText: 'km',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            _ctrl.text.trim().isEmpty ? 'Skip' : 'Add part',
          ),
        ),
      ],
    );
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      Navigator.pop(context, 0);
      return;
    }
    final km = int.tryParse(text);
    if (km == null || km <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid lifespan in km')),
      );
      return;
    }
    Navigator.pop(context, km);
  }
}

class _PerPartCostsSection extends StatelessWidget {
  const _PerPartCostsSection({
    required this.selectedParts,
    required this.partCosts,
    required this.onCostChanged,
  });

  final Set<String> selectedParts;
  final Map<String, double> partCosts;
  final void Function(String part, double? value) onCostChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).extension<AppColors>()!;
    if (selectedParts.isEmpty) {
      return Text(
        'Select parts above to add individual costs.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        ),
      );
    }
    final parts = selectedParts.toList()..sort();
    final total = partCosts.values.fold<double>(0, (s, v) => s + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Per‑part costs',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...parts.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    p,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    key: ValueKey('cost_$p'),
                    initialValue: partCosts[p] != null
                        ? partCosts[p]!.toStringAsFixed(0)
                        : '',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cost',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value.trim());
                      onCostChanged(p, parsed);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Total: ${total.toStringAsFixed(0)}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.maintenanceColor,
          ),
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.isOptional = false,
    this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isOptional;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Text(
          date != null
              ? DateFormat('dd MMM yyyy').format(date!)
              : isOptional
                  ? 'Tap to set...'
                  : DateFormat('dd MMM yyyy').format(DateTime.now()),
          style: date == null
              ? TextStyle(color: Theme.of(context).hintColor)
              : null,
        ),
      ),
    );
  }
}
