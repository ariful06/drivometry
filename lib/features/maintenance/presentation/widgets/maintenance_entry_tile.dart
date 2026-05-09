// lib/features/maintenance/presentation/widgets/maintenance_entry_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/maintenance_entry.dart';
import '../cubits/maintenance_cubit.dart';

class MaintenanceEntryTile extends StatelessWidget {
  const MaintenanceEntryTile({
    required this.entry,
    this.currentVehicleOdometer,
    super.key,
  });
  final MaintenanceEntry entry;
  /// When set, used to show overdue state for nextServiceOdometer.
  final double? currentVehicleOdometer;

  /// Split description into list items (by newline or comma).
  static List<String> _descriptionItems(String description) {
    if (description.trim().isEmpty) return [];
    return description
        .split(RegExp(r'[\n,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    final isParts = entry.type == 'parts';
    final entryColor = isParts ? colors.partsColor : colors.maintenanceColor;
    final items = _descriptionItems(entry.description);
    final hasNextDate = entry.nextServiceDate != null;
    String titleText;
    if (entry.nextServiceDate != null) {
      final dateStr = Formatters.formatDate(entry.nextServiceDate!);
      titleText =
          isParts ? 'Next part change: $dateStr' : 'Next repair: $dateStr';
    } else if (entry.nextServiceOdometer != null) {
      titleText =
          'Next at ${Formatters.formatDistance(entry.nextServiceOdometer!.toDouble())}';
    } else {
      titleText = entry.title;
    }

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete maintenance entry?'),
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
        context.read<MaintenanceCubit>().deleteMaintenance(
              entry.id,
              notificationId: entry.notificationId,
              odometerReminderScheduled: entry.odometerReminderScheduled,
              dateProximityReminderScheduled:
                  entry.dateProximityReminderScheduled,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted')),
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
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: entryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isParts ? Icons.settings_outlined : Icons.build_outlined,
                          color: entryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatDate(entry.serviceDate),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(entry.cost),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: entryColor,
                        ),
                      ),
                    ],
                  ),
                  if (hasNextDate) ...[
                    const SizedBox(height: 12),
                    _NextRepairChip(
                      nextDate: entry.nextServiceDate!,
                      colors: colors,
                    ),
                  ],
                  if (entry.nextServiceOdometer != null && !hasNextDate) ...[
                    const SizedBox(height: 12),
                    _NextOdometerChip(
                      nextOdometer: entry.nextServiceOdometer!,
                      currentOdometer: currentVehicleOdometer,
                      colors: colors,
                    ),
                  ],
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ExpandableChecklist(
                      label: 'Parts / work done',
                      itemCount: items.length,
                      colors: colors,
                      entryColor: entryColor,
                      theme: theme,
                      children: items
                          .map(
                            (item) => CheckboxListTile(
                              value: true,
                              onChanged: null,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                item,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              activeColor: colors.maintenanceColor,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ] else if (entry.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      entry.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
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

class _ExpandableChecklist extends StatefulWidget {
  const _ExpandableChecklist({
    required this.label,
    required this.itemCount,
    required this.colors,
    required this.entryColor,
    required this.theme,
    required this.children,
  });
  final String label;
  final int itemCount;
  final AppColors colors;
  final Color entryColor;
  final ThemeData theme;
  final List<Widget> children;

  @override
  State<_ExpandableChecklist> createState() => _ExpandableChecklistState();
}

class _ExpandableChecklistState extends State<_ExpandableChecklist> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: widget.theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${widget.itemCount})',
                  style: widget.theme.textTheme.labelMedium?.copyWith(
                    color: widget.colors.textSecondary,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: widget.colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 4),
          ...widget.children,
        ],
      ],
    );
  }
}

class _NextOdometerChip extends StatelessWidget {
  const _NextOdometerChip({
    required this.nextOdometer,
    this.currentOdometer,
    required this.colors,
  });
  final int nextOdometer;
  final double? currentOdometer;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = currentOdometer != null &&
        currentOdometer! >= nextOdometer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isOverdue
            ? colors.warning.withOpacity(0.15)
            : colors.maintenanceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? colors.warning.withOpacity(0.4)
              : colors.maintenanceColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.speed_rounded,
            size: 18,
            color: isOverdue ? colors.warning : colors.maintenanceColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOverdue
                      ? 'Service due (odometer reached)'
                      : 'Next service at',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.formatDistance(nextOdometer.toDouble()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOverdue
                        ? colors.warning
                        : colors.maintenanceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextRepairChip extends StatelessWidget {
  const _NextRepairChip({
    required this.nextDate,
    required this.colors,
  });
  final DateTime nextDate;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startOfToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final dateOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);
    final isOverdue = dateOnly.isBefore(startOfToday);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isOverdue
            ? colors.warning.withOpacity(0.15)
            : colors.maintenanceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? colors.warning.withOpacity(0.4)
              : colors.maintenanceColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.event_outlined,
            size: 18,
            color: isOverdue ? colors.warning : colors.maintenanceColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOverdue ? 'Next service overdue' : 'Next service due',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.formatDate(nextDate)} · ${Formatters.relativeDays(nextDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOverdue ? colors.warning : colors.maintenanceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

