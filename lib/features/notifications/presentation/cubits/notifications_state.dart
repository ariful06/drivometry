part of 'notifications_cubit.dart';

sealed class NotificationsState {
  const NotificationsState();
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.upcoming);
  final List<MaintenanceEntry> upcoming;
}

class NotificationsError extends NotificationsState {
  const NotificationsError(this.message);
  final String message;
}
