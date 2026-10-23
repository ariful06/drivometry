import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/part_replacement.dart';
import '../../domain/repositories/part_replacement_repository.dart';

sealed class PartsState {
  const PartsState();
}

class PartsLoading extends PartsState {
  const PartsLoading();
}

class PartsLoaded extends PartsState {
  const PartsLoaded(this.parts);

  /// Every record for the vehicle, including replaced ones.
  final List<PartReplacement> parts;

  List<PartReplacement> get active =>
      parts.where((p) => !p.isReplaced).toList();

  /// Replaced parts, most recently replaced first.
  List<PartReplacement> get history => parts.where((p) => p.isReplaced).toList()
    ..sort((a, b) => b.replacedAt!.compareTo(a.replacedAt!));

  /// Money spent on parts (every record, replaced or not).
  double get totalSpent =>
      parts.fold<double>(0, (sum, p) => sum + (p.cost ?? 0));
}

class PartsError extends PartsState {
  const PartsError(this.message);
  final String message;
}

class PartsCubit extends Cubit<PartsState> {
  PartsCubit(this._repository, this.vehicleId) : super(const PartsLoading());

  final PartReplacementRepository _repository;
  final String vehicleId;

  Future<void> load() async {
    try {
      emit(PartsLoaded(await _repository.getByVehicle(vehicleId)));
    } catch (error) {
      emit(PartsError(error.toString()));
    }
  }

  Future<void> add(PartReplacement part) async {
    await _repository.add(part);
    await load();
  }

  /// Installs [replacement] and keeps [old] as history linked to it.
  Future<void> replace(
    PartReplacement old,
    PartReplacement replacement, {
    DateTime? now,
  }) async {
    await _repository.add(replacement);
    await _repository.update(old.copyWith(
      replacedAt: replacement.installedAt ?? now ?? DateTime.now(),
      replacedById: replacement.id,
    ));
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }
}
