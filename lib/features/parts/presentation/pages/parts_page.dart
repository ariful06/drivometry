import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/part_replacement.dart';
import '../../domain/services/parts_lifecycle_service.dart';
import '../cubits/parts_cubit.dart';
import 'add_part_page.dart';

class PartsPage extends StatelessWidget {
  const PartsPage({required this.vehicle, super.key});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PartsCubit>(param1: vehicle.id)..load(),
      child: _PartsView(vehicle: vehicle),
    );
  }
}

class _PartsView extends StatelessWidget {
  const _PartsView({required this.vehicle});
  final Vehicle vehicle;

  Future<void> _openForm(BuildContext context, {PartReplacement? old}) async {
    final part = await context.push<PartReplacement>(
      '/vehicles/${vehicle.id}/parts/add',
      extra: AddPartArgs(vehicle: vehicle, replacing: old),
    );
    if (part == null || !context.mounted) return;
    final cubit = context.read<PartsCubit>();
    if (old == null) {
      await cubit.add(part);
    } else {
      await cubit.replace(old, part);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${vehicle.name} · Parts')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add part',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<PartsCubit, PartsState>(
        builder: (context, state) => switch (state) {
          PartsLoading() => const LoadingOverlay(),
          PartsError(:final message) => Center(child: Text('Error: $message')),
          PartsLoaded(:final parts) when parts.isEmpty => const EmptyState(
              icon: Icons.settings_suggest_outlined,
              title: 'No parts tracked yet',
              subtitle:
                  'Add tyres, brake pads, battery… and get told when they are due.',
            ),
          PartsLoaded() => _PartsList(
              state: state,
              vehicle: vehicle,
              onReplace: (part) => _openForm(context, old: part),
            ),
        },
      ),
    );
  }
}

class _PartsList extends StatelessWidget {
  const _PartsList({
    required this.state,
    required this.vehicle,
    required this.onReplace,
  });
  final PartsLoaded state;
  final Vehicle vehicle;
  final ValueChanged<PartReplacement> onReplace;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final lifecycle = sl<PartsLifecycleService>();
    final now = DateTime.now();
    final entries = [
      for (final part in state.active)
        (part, lifecycle.evaluate(part, vehicle.currentOdometer, now)),
    ]..sort((a, b) => b.$2.health.index.compareTo(a.$2.health.index));
    final needAttention =
        entries.where((e) => e.$2.health != PartHealth.ok).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Need attention',
                value: '$needAttention',
                icon: Icons.warning_amber_outlined,
                color: needAttention > 0 ? colors.warning : colors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: 'Spent on parts',
                value: Formatters.formatCurrency(state.totalSpent),
                icon: Icons.payments_outlined,
                color: colors.partsColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Active parts'),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Everything has been replaced. Add the new parts.'),
          ),
        for (final (part, status) in entries)
          _ActivePartCard(
            part: part,
            status: status,
            underWarranty: lifecycle.isUnderWarranty(part, now),
            onReplace: () => onReplace(part),
            onDelete: () => context.read<PartsCubit>().delete(part.id),
          ),
        if (state.history.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader(title: 'Replacement history'),
          for (final part in state.history) _HistoryTile(part: part),
        ],
      ],
    );
  }
}

class _ActivePartCard extends StatelessWidget {
  const _ActivePartCard({
    required this.part,
    required this.status,
    required this.underWarranty,
    required this.onReplace,
    required this.onDelete,
  });
  final PartReplacement part;
  final PartStatus status;
  final bool underWarranty;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  String get _remaining {
    final bits = <String>[];
    final km = status.remainingKm;
    if (km != null) {
      bits.add(km <= 0
          ? '${Formatters.formatDistance(-km)} overdue'
          : '${Formatters.formatDistance(km)} left');
    }
    final days = status.remainingDays;
    if (days != null) {
      bits.add(days <= 0 ? '${-days} days overdue' : '$days days left');
    }
    return bits.isEmpty ? 'No lifespan set' : bits.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final (label, color) = switch (status.health) {
      PartHealth.ok => ('OK', colors.success),
      PartHealth.dueSoon => ('Due soon', colors.warning),
      PartHealth.overdue => ('Overdue', Colors.red),
      PartHealth.replaced => ('Replaced', colors.textSecondary),
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(part.partName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(label,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (part.category != null)
            Text(part.category!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 10),
          if (status.usedFraction != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: status.usedFraction!.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          const SizedBox(height: 6),
          Text(_remaining, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            [
              if (part.installedAt != null)
                'Installed ${Formatters.formatDate(part.installedAt!)}',
              'at ${Formatters.formatDistance(part.installOdometer)}',
              if (part.cost != null) Formatters.formatCurrency(part.cost!),
              if (underWarranty) 'Under warranty',
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
              FilledButton.icon(
                onPressed: onReplace,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Replace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.part});
  final PartReplacement part;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(part.partName),
      subtitle: Text([
        if (part.installedAt != null)
          'Installed ${Formatters.formatDate(part.installedAt!)}',
        'replaced ${Formatters.formatDate(part.replacedAt!)}',
        if (part.cost != null) Formatters.formatCurrency(part.cost!),
      ].join(' · ')),
    );
  }
}
