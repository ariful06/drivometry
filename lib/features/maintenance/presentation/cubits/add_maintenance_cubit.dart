import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/maintenance_parts.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

class AddMaintenanceState {
  const AddMaintenanceState({
    required this.type,
    required this.serviceDate,
    required this.nextServiceDate,
    required this.selectedParts,
    required this.partCosts,
    required this.partLifespansKm,
    required this.partsByCategory,
    required this.isSaving,
  });

  /// 'repair' or 'parts'
  final String type;
  final DateTime serviceDate;
  final DateTime? nextServiceDate;
  final Set<String> selectedParts;
  final Map<String, double> partCosts;
  /// Part name -> lifespan in km (for next service odometer).
  final Map<String, int> partLifespansKm;
  final PartsByCategory partsByCategory;
  final bool isSaving;

  AddMaintenanceState copyWith({
    String? type,
    DateTime? serviceDate,
    DateTime? nextServiceDate,
    bool nextServiceDateSet = false,
    Set<String>? selectedParts,
    Map<String, double>? partCosts,
    Map<String, int>? partLifespansKm,
    PartsByCategory? partsByCategory,
    bool? isSaving,
  }) {
    return AddMaintenanceState(
      type: type ?? this.type,
      serviceDate: serviceDate ?? this.serviceDate,
      nextServiceDate:
          nextServiceDateSet ? nextServiceDate : this.nextServiceDate,
      selectedParts: selectedParts ?? this.selectedParts,
      partCosts: partCosts ?? this.partCosts,
      partLifespansKm: partLifespansKm ?? this.partLifespansKm,
      partsByCategory: partsByCategory ?? this.partsByCategory,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class AddMaintenanceCubit extends Cubit<AddMaintenanceState> {
  AddMaintenanceCubit({required Vehicle vehicle})
      : super(
          AddMaintenanceState(
            type: 'repair',
            serviceDate: DateTime.now(),
            nextServiceDate: null,
            selectedParts: <String>{},
            partCosts: <String, double>{},
            partLifespansKm: <String, int>{},
            partsByCategory: _resolveDataset(vehicle),
            isSaving: false,
          ),
        );

  static PartsByCategory _resolveDataset(Vehicle vehicle) {
    if (vehicle.type == AppConstants.vehicleTypeBike) {
      return MotorcycleParts;
    }
    return CarParts;
  }

  void setType(String type) {
    // When switching to repair, keep parts dataset but clear selections/costs.
    if (type == state.type) return;
    if (type == 'repair') {
      emit(
        state.copyWith(
          type: type,
          selectedParts: <String>{},
          partCosts: <String, double>{},
          partLifespansKm: <String, int>{},
        ),
      );
    } else {
      emit(state.copyWith(type: type));
    }
  }

  void togglePart(String part) {
    final updatedSelected = Set<String>.from(state.selectedParts);
    final updatedCosts = Map<String, double>.from(state.partCosts);
    final updatedLifespans = Map<String, int>.from(state.partLifespansKm);
    if (updatedSelected.contains(part)) {
      updatedSelected.remove(part);
      updatedCosts.remove(part);
      updatedLifespans.remove(part);
    } else {
      updatedSelected.add(part);
    }
    emit(
      state.copyWith(
        selectedParts: updatedSelected,
        partCosts: updatedCosts,
        partLifespansKm: updatedLifespans,
      ),
    );
  }

  void setPartLifespanKm(String part, int? km) {
    final updated = Map<String, int>.from(state.partLifespansKm);
    if (km == null || km <= 0) {
      updated.remove(part);
    } else {
      updated[part] = km;
    }
    emit(state.copyWith(partLifespansKm: updated));
  }

  void setPartCost(String part, double? cost) {
    final updated = Map<String, double>.from(state.partCosts);
    if (cost == null || cost <= 0) {
      updated.remove(part);
    } else {
      updated[part] = cost;
    }
    emit(state.copyWith(partCosts: updated));
  }

  void setServiceDate(DateTime date) {
    emit(state.copyWith(serviceDate: date));
  }

  void setNextServiceDate(DateTime? date) {
    emit(state.copyWith(
      nextServiceDate: date,
      nextServiceDateSet: true,
    ));
  }

  void setSaving(bool saving) {
    emit(state.copyWith(isSaving: saving));
  }

  double get partsTotalCost =>
      state.partCosts.values.fold<double>(0, (s, v) => s + v);
}

