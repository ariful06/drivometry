// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fuel_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FuelEntry {
  String get id;
  String get vehicleId;
  DateTime get date;
  double get odometer;
  double get liters;
  double get costPerLiter;
  double get totalCost;
  String? get notes;
  double? get fuelEfficiency; // km/L calculated from prev entry
  double? get distanceDriven;

  /// Create a copy of FuelEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FuelEntryCopyWith<FuelEntry> get copyWith =>
      _$FuelEntryCopyWithImpl<FuelEntry>(this as FuelEntry, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FuelEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vehicleId, vehicleId) ||
                other.vehicleId == vehicleId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.odometer, odometer) ||
                other.odometer == odometer) &&
            (identical(other.liters, liters) || other.liters == liters) &&
            (identical(other.costPerLiter, costPerLiter) ||
                other.costPerLiter == costPerLiter) &&
            (identical(other.totalCost, totalCost) ||
                other.totalCost == totalCost) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.fuelEfficiency, fuelEfficiency) ||
                other.fuelEfficiency == fuelEfficiency) &&
            (identical(other.distanceDriven, distanceDriven) ||
                other.distanceDriven == distanceDriven));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, vehicleId, date, odometer,
      liters, costPerLiter, totalCost, notes, fuelEfficiency, distanceDriven);

  @override
  String toString() {
    return 'FuelEntry(id: $id, vehicleId: $vehicleId, date: $date, odometer: $odometer, liters: $liters, costPerLiter: $costPerLiter, totalCost: $totalCost, notes: $notes, fuelEfficiency: $fuelEfficiency, distanceDriven: $distanceDriven)';
  }
}

/// @nodoc
abstract mixin class $FuelEntryCopyWith<$Res> {
  factory $FuelEntryCopyWith(FuelEntry value, $Res Function(FuelEntry) _then) =
      _$FuelEntryCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String vehicleId,
      DateTime date,
      double odometer,
      double liters,
      double costPerLiter,
      double totalCost,
      String? notes,
      double? fuelEfficiency,
      double? distanceDriven});
}

/// @nodoc
class _$FuelEntryCopyWithImpl<$Res> implements $FuelEntryCopyWith<$Res> {
  _$FuelEntryCopyWithImpl(this._self, this._then);

  final FuelEntry _self;
  final $Res Function(FuelEntry) _then;

  /// Create a copy of FuelEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vehicleId = null,
    Object? date = null,
    Object? odometer = null,
    Object? liters = null,
    Object? costPerLiter = null,
    Object? totalCost = null,
    Object? notes = freezed,
    Object? fuelEfficiency = freezed,
    Object? distanceDriven = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      vehicleId: null == vehicleId
          ? _self.vehicleId
          : vehicleId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      odometer: null == odometer
          ? _self.odometer
          : odometer // ignore: cast_nullable_to_non_nullable
              as double,
      liters: null == liters
          ? _self.liters
          : liters // ignore: cast_nullable_to_non_nullable
              as double,
      costPerLiter: null == costPerLiter
          ? _self.costPerLiter
          : costPerLiter // ignore: cast_nullable_to_non_nullable
              as double,
      totalCost: null == totalCost
          ? _self.totalCost
          : totalCost // ignore: cast_nullable_to_non_nullable
              as double,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      fuelEfficiency: freezed == fuelEfficiency
          ? _self.fuelEfficiency
          : fuelEfficiency // ignore: cast_nullable_to_non_nullable
              as double?,
      distanceDriven: freezed == distanceDriven
          ? _self.distanceDriven
          : distanceDriven // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// Adds pattern-matching-related methods to [FuelEntry].
extension FuelEntryPatterns on FuelEntry {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FuelEntry value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FuelEntry() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FuelEntry value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FuelEntry():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FuelEntry value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FuelEntry() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String vehicleId,
            DateTime date,
            double odometer,
            double liters,
            double costPerLiter,
            double totalCost,
            String? notes,
            double? fuelEfficiency,
            double? distanceDriven)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FuelEntry() when $default != null:
        return $default(
            _that.id,
            _that.vehicleId,
            _that.date,
            _that.odometer,
            _that.liters,
            _that.costPerLiter,
            _that.totalCost,
            _that.notes,
            _that.fuelEfficiency,
            _that.distanceDriven);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String vehicleId,
            DateTime date,
            double odometer,
            double liters,
            double costPerLiter,
            double totalCost,
            String? notes,
            double? fuelEfficiency,
            double? distanceDriven)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FuelEntry():
        return $default(
            _that.id,
            _that.vehicleId,
            _that.date,
            _that.odometer,
            _that.liters,
            _that.costPerLiter,
            _that.totalCost,
            _that.notes,
            _that.fuelEfficiency,
            _that.distanceDriven);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String vehicleId,
            DateTime date,
            double odometer,
            double liters,
            double costPerLiter,
            double totalCost,
            String? notes,
            double? fuelEfficiency,
            double? distanceDriven)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FuelEntry() when $default != null:
        return $default(
            _that.id,
            _that.vehicleId,
            _that.date,
            _that.odometer,
            _that.liters,
            _that.costPerLiter,
            _that.totalCost,
            _that.notes,
            _that.fuelEfficiency,
            _that.distanceDriven);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _FuelEntry implements FuelEntry {
  const _FuelEntry(
      {required this.id,
      required this.vehicleId,
      required this.date,
      required this.odometer,
      required this.liters,
      required this.costPerLiter,
      required this.totalCost,
      this.notes,
      this.fuelEfficiency,
      this.distanceDriven});

  @override
  final String id;
  @override
  final String vehicleId;
  @override
  final DateTime date;
  @override
  final double odometer;
  @override
  final double liters;
  @override
  final double costPerLiter;
  @override
  final double totalCost;
  @override
  final String? notes;
  @override
  final double? fuelEfficiency;
// km/L calculated from prev entry
  @override
  final double? distanceDriven;

  /// Create a copy of FuelEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FuelEntryCopyWith<_FuelEntry> get copyWith =>
      __$FuelEntryCopyWithImpl<_FuelEntry>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FuelEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vehicleId, vehicleId) ||
                other.vehicleId == vehicleId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.odometer, odometer) ||
                other.odometer == odometer) &&
            (identical(other.liters, liters) || other.liters == liters) &&
            (identical(other.costPerLiter, costPerLiter) ||
                other.costPerLiter == costPerLiter) &&
            (identical(other.totalCost, totalCost) ||
                other.totalCost == totalCost) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.fuelEfficiency, fuelEfficiency) ||
                other.fuelEfficiency == fuelEfficiency) &&
            (identical(other.distanceDriven, distanceDriven) ||
                other.distanceDriven == distanceDriven));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, vehicleId, date, odometer,
      liters, costPerLiter, totalCost, notes, fuelEfficiency, distanceDriven);

  @override
  String toString() {
    return 'FuelEntry(id: $id, vehicleId: $vehicleId, date: $date, odometer: $odometer, liters: $liters, costPerLiter: $costPerLiter, totalCost: $totalCost, notes: $notes, fuelEfficiency: $fuelEfficiency, distanceDriven: $distanceDriven)';
  }
}

/// @nodoc
abstract mixin class _$FuelEntryCopyWith<$Res>
    implements $FuelEntryCopyWith<$Res> {
  factory _$FuelEntryCopyWith(
          _FuelEntry value, $Res Function(_FuelEntry) _then) =
      __$FuelEntryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String vehicleId,
      DateTime date,
      double odometer,
      double liters,
      double costPerLiter,
      double totalCost,
      String? notes,
      double? fuelEfficiency,
      double? distanceDriven});
}

/// @nodoc
class __$FuelEntryCopyWithImpl<$Res> implements _$FuelEntryCopyWith<$Res> {
  __$FuelEntryCopyWithImpl(this._self, this._then);

  final _FuelEntry _self;
  final $Res Function(_FuelEntry) _then;

  /// Create a copy of FuelEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? vehicleId = null,
    Object? date = null,
    Object? odometer = null,
    Object? liters = null,
    Object? costPerLiter = null,
    Object? totalCost = null,
    Object? notes = freezed,
    Object? fuelEfficiency = freezed,
    Object? distanceDriven = freezed,
  }) {
    return _then(_FuelEntry(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      vehicleId: null == vehicleId
          ? _self.vehicleId
          : vehicleId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      odometer: null == odometer
          ? _self.odometer
          : odometer // ignore: cast_nullable_to_non_nullable
              as double,
      liters: null == liters
          ? _self.liters
          : liters // ignore: cast_nullable_to_non_nullable
              as double,
      costPerLiter: null == costPerLiter
          ? _self.costPerLiter
          : costPerLiter // ignore: cast_nullable_to_non_nullable
              as double,
      totalCost: null == totalCost
          ? _self.totalCost
          : totalCost // ignore: cast_nullable_to_non_nullable
              as double,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      fuelEfficiency: freezed == fuelEfficiency
          ? _self.fuelEfficiency
          : fuelEfficiency // ignore: cast_nullable_to_non_nullable
              as double?,
      distanceDriven: freezed == distanceDriven
          ? _self.distanceDriven
          : distanceDriven // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

// dart format on
