import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/repositories/vehicle_repository.dart';

part 'startup_state.dart';

class StartupCubit extends Cubit<StartupState> {
  StartupCubit(this._vehicleRepository) : super(const StartupInitial());

  final VehicleRepository _vehicleRepository;

  Future<void> load() async {
    emit(const StartupLoading());
    try {
      final vehicles = await _vehicleRepository.getVehicles();
      emit(StartupReady(vehicles));
    } catch (_) {
      emit(const StartupReady([]));
    }
  }
}
