import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../cubits/rental_cubit.dart';
import '../widgets/rental_entry_tile.dart';

class RentalsPage extends StatelessWidget {
  const RentalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RentalCubit>()..watchAll(),
      child: const _RentalsView(),
    );
  }
}

class _RentalsView extends StatelessWidget {
  const _RentalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental')),
      body: BlocBuilder<RentalCubit, RentalState>(
        builder: (context, state) {
          return switch (state) {
            RentalInitial() => const SizedBox.shrink(),
            RentalLoading() => const LoadingOverlay(),
            RentalError(:final message) => Center(child: Text('Error: $message')),
            RentalLoaded(:final entries, :final totalFare, :final totalDue) => entries.isEmpty
                ? const EmptyState(
                    icon: Icons.car_rental_outlined,
                    title: 'No rental records yet',
                    subtitle: 'Tap + to create your first booking.',
                  )
                : _RentalList(
                    entries: entries,
                    totalFare: totalFare,
                    totalDue: totalDue,
                  ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/rentals/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RentalList extends StatelessWidget {
  const _RentalList({
    required this.entries,
    required this.totalFare,
    required this.totalDue,
  });

  final List entries;
  final double totalFare;
  final double totalDue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final paidCount =
        entries.where((rental) => rental.paymentStatus == 'Paid').length;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _summaryChip(
                  context,
                  title: 'Total Fare',
                  value: Formatters.formatCurrency(totalFare),
                  color: colors.fuelColor,
                ),
                _summaryChip(
                  context,
                  title: 'Total Due',
                  value: Formatters.formatCurrency(totalDue),
                  color: totalDue <= 0 ? colors.success : colors.warning,
                ),
                _summaryChip(
                  context,
                  title: 'Paid',
                  value: '$paidCount / ${entries.length}',
                  color: colors.success,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RentalEntryTile(entry: entries[i]),
              ),
              childCount: entries.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _summaryChip(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
