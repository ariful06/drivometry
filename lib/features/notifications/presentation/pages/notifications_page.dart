import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../../maintenance/domain/entities/maintenance_entry.dart';
import '../cubits/notifications_cubit.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(getUpcoming: sl())..loadUpcoming(daysAhead: 60),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => context.read<NotificationsCubit>().loadUpcoming(daysAhead: 60),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return switch (state) {
            NotificationsInitial() => const SizedBox.shrink(),
            NotificationsLoading() => const Center(child: CircularProgressIndicator()),
            NotificationsError(:final message) => Center(child: Text('Error: $message')),
            NotificationsLoaded(:final upcoming) => upcoming.isEmpty
                ? _EmptyState()
                : _UpcomingList(entries: upcoming),
          };
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_outlined, size: 72,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No upcoming services',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Scheduled maintenance reminders\nwill appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.entries});
  final List<MaintenanceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfNextWeek = startOfToday.add(const Duration(days: 7));

    final overdue = entries.where((e) {
      if (e.nextServiceDate == null) return false;
      final d = DateTime(e.nextServiceDate!.year, e.nextServiceDate!.month, e.nextServiceDate!.day);
      return d.isBefore(startOfToday);
    }).toList();
    final thisWeek = entries.where((e) {
      if (e.nextServiceDate == null) return false;
      final d = DateTime(e.nextServiceDate!.year, e.nextServiceDate!.month, e.nextServiceDate!.day);
      return !d.isBefore(startOfToday) && d.isBefore(startOfNextWeek);
    }).toList();
    final later = entries.where((e) {
      if (e.nextServiceDate == null) return false;
      final d = DateTime(e.nextServiceDate!.year, e.nextServiceDate!.month, e.nextServiceDate!.day);
      return !d.isBefore(startOfNextWeek);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overdue.isNotEmpty) ...[
          _SectionHeader(label: 'Overdue', count: overdue.length, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          ...overdue.map((e) => _NotificationCard(entry: e, isOverdue: true)),
          const SizedBox(height: 20),
        ],
        if (thisWeek.isNotEmpty) ...[
          _SectionHeader(label: 'This Week', count: thisWeek.length, color: Colors.orange),
          const SizedBox(height: 8),
          ...thisWeek.map((e) => _NotificationCard(entry: e)),
          const SizedBox(height: 20),
        ],
        if (later.isNotEmpty) ...[
          _SectionHeader(label: 'Upcoming', count: later.length, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          ...later.map((e) => _NotificationCard(entry: e)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: 1.1, color: color)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.entry, this.isOverdue = false});
  final MaintenanceEntry entry;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final nextDate = entry.nextServiceDate!;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final nextDateOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);
    final diff = nextDateOnly.difference(startOfToday).inDays;

    final String dueLabel;
    final Color dueColor;
    if (isOverdue) {
      final daysOverdue = startOfToday.difference(nextDateOnly).inDays;
      dueLabel = 'Overdue by $daysOverdue day${daysOverdue == 1 ? "" : "s"}';
      dueColor = Theme.of(context).colorScheme.error;
    } else if (diff == 0) {
      dueLabel = 'Due today';
      dueColor = Colors.orange;
    } else if (diff == 1) {
      dueLabel = 'Due tomorrow';
      dueColor = Colors.orange;
    } else {
      dueLabel = 'Due in $diff days';
      dueColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: dueColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(entry.type == 'parts' ? Icons.settings_outlined : Icons.build_outlined, color: dueColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(entry.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: dueColor),
                    const SizedBox(width: 4),
                    Text('${DateFormat("dd MMM yyyy").format(nextDate)}  •  $dueLabel',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dueColor)),
                  ]),
                  if (entry.nextServiceOdometer != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.speed_outlined, size: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text('At ${NumberFormat("#,###").format(entry.nextServiceOdometer)} km',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}