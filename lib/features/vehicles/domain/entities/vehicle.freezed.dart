// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Vehicle {
  String get id;
  String get name;
  String get type; // car, bike, other
  String get make;
  String get model;
  int get year;
  String get licensePlate;
  double get initialOdometer;
  double get currentOdometer;
  DateTime get createdAt;
  String? get color;
  String? get notes;

  /// Create a copy of Vehicle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VehicleCopyWith<Vehicle> get copyWith =>
      _$VehicleCopyWithImpl<Vehicle>(this as Vehicle, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Vehicle &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.make, make) || other.make == make) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.licensePlate, licensePlate) ||
                other.licensePlate == licensePlate) &&
            (identical(other.initialOdometer, initialOdometer) ||
                other.initialOdometer == initialOdometer) &&
            (identical(other.currentOdometer, currentOdometer) ||
                other.currentOdometer == currentOdometer) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      make,
      model,
      year,
      licensePlate,
      initialOdometer,
      currentOdometer,
      createdAt,
      color,
      notes);

  @override
  String toString() {
    return 'Vehicle(id: $id, name: $name, type: $type, make: $make, model: $model, year: $year, licensePlate: $licensePlate, initialOdometer: $initialOdometer, currentOdometer: $currentOdometer, createdAt: $createdAt, color: $color, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $VehicleCopyWith<$Res> {
  factory $VehicleCopyWith(Vehicle value, $Res Function(Vehicle) _then) =
      _$VehicleCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String type,
      String make,
      String model,
      int year,
      String licensePlate,
      double initialOdometer,
      double currentOdometer,
      DateTime createdAt,
      String? color,
      String? notes});
}

/// @nodoc
class _$VehicleCopyWithImpl<$Res> implements $VehicleCopyWith<$Res> {
  _$VehicleCopyWithImpl(this._self, this._then);

  final Vehicle _self;
  final $Res Function(Vehicle) _then;

  /// Create a copy of Vehicle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? make = null,
    Object? model = null,
    Object? year = null,
    Object? licensePlate = null,
    Object? initialOdometer = null,
    Object? currentOdometer = null,
    Object? createdAt = null,
    Object? color = freezed,
    Object? notes = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      make: null == make
          ? _self.make
          : make // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _self.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      licensePlate: null == licensePlate
          ? _self.licensePlate
          : licensePlate // ignore: cast_nullable_to_non_nullable
              as String,
      initialOdometer: null == initialOdometer
          ? _self.initialOdometer
          : initialOdometer // ignore: cast_nullable_to_non_nullable
              as double,
      currentOdometer: null == currentOdometer
          ? _self.currentOdometer
          : currentOdometer // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      color: freezed == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Vehicle].
extension VehiclePatterns on Vehicle {
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
    TResult Function(_Vehicle value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Vehicle() when $default != null:
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
    TResult Function(_Vehicle value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Vehicle():
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
    TResult? Function(_Vehicle value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Vehicle() when $default != null:
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
            String name,
            String type,
            String make,
            String model,
            int year,
            String licensePlate,
            double initialOdometer,
            double currentOdometer,
            DateTime createdAt,
            String? color,
            String? notes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Vehicle() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.type,
            _that.make,
            _that.model,
            _that.year,
            _that.licensePlate,
            _that.initialOdometer,
            _that.currentOdometer,
            _that.createdAt,
            _that.color,
            _that.notes);
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
            String name,
            String type,
            String make,
            String model,
            int year,
            String licensePlate,
            double initialOdometer,
            double currentOdometer,
            DateTime createdAt,
            String? color,
            String? notes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Vehicle():
        return $default(
            _that.id,
            _that.name,
            _that.type,
            _that.make,
            _that.model,
            _that.year,
            _that.licensePlate,
            _that.initialOdometer,
            _that.currentOdometer,
            _that.createdAt,
            _that.color,
            _that.notes);
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
            String name,
            String type,
            String make,
            String model,
            int year,
            String licensePlate,
            double initialOdometer,
            double currentOdometer,
            DateTime createdAt,
            String? color,
            String? notes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Vehicle() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.type,
            _that.make,
            _that.model,
            _that.year,
            _that.licensePlate,
            _that.initialOdometer,
            _that.currentOdometer,
            _that.createdAt,
            _that.color,
            _that.notes);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Vehicle implements Vehicle {
  const _Vehicle(
      {required this.id,
      required this.name,
      required this.type,
      required this.make,
      required this.model,
      required this.year,
      required this.licensePlate,
      required this.initialOdometer,
      required this.currentOdometer,
      required this.createdAt,
      this.color,
      this.notes});

  @override
  final String id;
  @override
  final String name;
  @override
  final String type;
// car, bike, other
  @override
  final String make;
  @override
  final String model;
  @override
  final int year;
  @override
  final String licensePlate;
  @override
  final double initialOdometer;
  @override
  final double currentOdometer;
  @override
  final DateTime createdAt;
  @override
  final String? color;
  @override
  final String? notes;

  /// Create a copy of Vehicle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VehicleCopyWith<_Vehicle> get copyWith =>
      __$VehicleCopyWithImpl<_Vehicle>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Vehicle &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.make, make) || other.make == make) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.licensePlate, licensePlate) ||
                other.licensePlate == licensePlate) &&
            (identical(other.initialOdometer, initialOdometer) ||
                other.initialOdometer == initialOdometer) &&
            (identical(other.currentOdometer, currentOdometer) ||
                other.currentOdometer == currentOdometer) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      make,
      model,
      year,
      licensePlate,
      initialOdometer,
      currentOdometer,
      createdAt,
      color,
      notes);

  @override
  String toString() {
    return 'Vehicle(id: $id, name: $name, type: $type, make: $make, model: $model, year: $year, licensePlate: $licensePlate, initialOdometer: $initialOdometer, currentOdometer: $currentOdometer, createdAt: $createdAt, color: $color, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class _$VehicleCopyWith<$Res> implements $VehicleCopyWith<$Res> {
  factory _$VehicleCopyWith(_Vehicle value, $Res Function(_Vehicle) _then) =
      __$VehicleCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String type,
      String make,
      String model,
      int year,
      String licensePlate,
      double initialOdometer,
      double currentOdometer,
      DateTime createdAt,
      String? color,
      String? notes});
}

/// @nodoc
class __$VehicleCopyWithImpl<$Res> implements _$VehicleCopyWith<$Res> {
  __$VehicleCopyWithImpl(this._self, this._then);

  final _Vehicle _self;
  final $Res Function(_Vehicle) _then;

  /// Create a copy of Vehicle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? make = null,
    Object? model = null,
    Object? year = null,
    Object? licensePlate = null,
    Object? initialOdometer = null,
    Object? currentOdometer = null,
    Object? createdAt = null,
    Object? color = freezed,
    Object? notes = freezed,
  }) {
    return _then(_Vehicle(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      make: null == make
          ? _self.make
          : make // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _self.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      licensePlate: null == licensePlate
          ? _self.licensePlate
          : licensePlate // ignore: cast_nullable_to_non_nullable
              as String,
      initialOdometer: null == initialOdometer
          ? _self.initialOdometer
          : initialOdometer // ignore: cast_nullable_to_non_nullable
              as double,
      currentOdometer: null == currentOdometer
          ? _self.currentOdometer
          : currentOdometer // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      color: freezed == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
