part of 'rental_cubit.dart';

sealed class RentalState {
  const RentalState();
}

class RentalInitial extends RentalState {
  const RentalInitial();
}

class RentalLoading extends RentalState {
  const RentalLoading();
}

class RentalLoaded extends RentalState {
  const RentalLoaded({
    required this.entries,
    required this.totalFare,
    required this.totalDue,
  });

  final List<RentalEntry> entries;
  final double totalFare;
  final double totalDue;
}

class RentalError extends RentalState {
  const RentalError(this.message);
  final String message;
}
