import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../../maintenance/domain/entities/maintenance_entry.dart';
import '../../../maintenance/domain/usecases/maintenance_usecases.dart';
import '../cubits/notifications_cubit.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        sl<RunMaintenanceReminderChecks>()();
        return NotificationsCubit(
          getUpcoming: sl(),
          getAllVehicles: sl(),
          updateMaintenance: sl(),
          notificationService: sl(),
        )..loadUpcoming(daysAhead: 60);
      },
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
            onPressed: () =>
                context.read<NotificationsCubit>().loadUpcoming(daysAhead: 60),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return switch (state) {
            NotificationsInitial() => const SizedBox.shrink(),
            NotificationsLoading() =>
              const Center(child: CircularProgressIndicator()),
            NotificationsError(:final message) =>
              Center(child: Text('Error: $message')),
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
          Icon(Icons.notifications_none_outlined,
              size: 72,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No upcoming services',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Scheduled maintenance reminders\nwill appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5))),
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

    final withDate =
        entries.where((entry) => entry.nextServiceDate != null).toList();
    final byOdometer = entries
        .where(
          (entry) =>
              entry.nextServiceDate == null &&
              entry.nextServiceOdometer != null,
        )
        .toList();

    final overdue = withDate.where((entry) {
      final nextDueDay = DateTime(
        entry.nextServiceDate!.year,
        entry.nextServiceDate!.month,
        entry.nextServiceDate!.day,
      );
      return nextDueDay.isBefore(startOfToday);
    }).toList();
    final thisWeek = withDate.where((entry) {
      final nextDueDay = DateTime(
        entry.nextServiceDate!.year,
        entry.nextServiceDate!.month,
        entry.nextServiceDate!.day,
      );
      return !nextDueDay.isBefore(startOfToday) &&
          nextDueDay.isBefore(startOfNextWeek);
    }).toList();
    final later = withDate.where((entry) {
      final nextDueDay = DateTime(
        entry.nextServiceDate!.year,
        entry.nextServiceDate!.month,
        entry.nextServiceDate!.day,
      );
      return !nextDueDay.isBefore(startOfNextWeek);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overdue.isNotEmpty) ...[
          _SectionHeader(
              label: 'Overdue',
              count: overdue.length,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          ...overdue.map(
            (entry) => _NotificationCard(entry: entry, isOverdue: true),
          ),
          const SizedBox(height: 20),
        ],
        if (thisWeek.isNotEmpty) ...[
          _SectionHeader(
              label: 'This Week', count: thisWeek.length, color: Colors.orange),
          const SizedBox(height: 8),
          ...thisWeek.map(
            (entry) => _NotificationCard(entry: entry),
          ),
          const SizedBox(height: 20),
        ],
        if (later.isNotEmpty) ...[
          _SectionHeader(
              label: 'Upcoming',
              count: later.length,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          ...later.map(
            (entry) => _NotificationCard(entry: entry),
          ),
          const SizedBox(height: 20),
        ],
        if (byOdometer.isNotEmpty) ...[
          _SectionHeader(
            label: 'By odometer',
            count: byOdometer.length,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(height: 8),
          ...byOdometer.map(
            (entry) => _NotificationCard(entry: entry),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: 1.1, color: color)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
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
    final nextDate = entry.nextServiceDate;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final String dueLabel;
    final Color dueColor;
    if (nextDate != null) {
      final nextDateOnly =
          DateTime(nextDate.year, nextDate.month, nextDate.day);
      final diff = nextDateOnly.difference(startOfToday).inDays;
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
    } else {
      dueLabel = 'Track by odometer';
      dueColor = Theme.of(context).colorScheme.tertiary;
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: dueColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(
                  entry.type == 'parts'
                      ? Icons.settings_outlined
                      : Icons.build_outlined,
                  color: dueColor,
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(entry.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  if (nextDate != null)
                    Row(children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: dueColor),
                      const SizedBox(width: 4),
                      Text(
                          '${DateFormat("dd MMM yyyy").format(nextDate)}  •  $dueLabel',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: dueColor)),
                    ])
                  else
                    Text(dueLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: dueColor)),
                  if (entry.nextServiceOdometer != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.speed_outlined,
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                          'At ${NumberFormat("#,###").format(entry.nextServiceOdometer)} km',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5))),
                    ]),
                  ],
                ],
              ),
            ),
            Tooltip(
              message: 'Mark serviced — removes from reminders',
              child: Checkbox(
                value: entry.reminderAcknowledged,
                onChanged: (v) async {
                  if (v != true) return;
                  try {
                    await context
                        .read<NotificationsCubit>()
                        .markReminderDone(entry);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not update reminder')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
