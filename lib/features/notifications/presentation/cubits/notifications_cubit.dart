import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../maintenance/domain/entities/maintenance_entry.dart';
import '../../../maintenance/domain/usecases/maintenance_usecases.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({required GetUpcomingMaintenance getUpcoming})
      : _getUpcoming = getUpcoming,
        super(const NotificationsInitial());

  final GetUpcomingMaintenance _getUpcoming;

  Future<void> loadUpcoming({int daysAhead = 30}) async {
    emit(const NotificationsLoading());
    try {
      final entries = await _getUpcoming(daysAhead: daysAhead);
      emit(NotificationsLoaded(entries));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }
}