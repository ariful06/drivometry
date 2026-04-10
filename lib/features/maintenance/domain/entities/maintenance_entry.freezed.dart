// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MaintenanceEntry {
  String get id;
  String get vehicleId;
  String get type; // 'parts' | 'repair'
  String get title;
  String get description;
  double get cost;
  double get odometer;
  DateTime get serviceDate;
  DateTime? get nextServiceDate;
  int? get nextServiceOdometer;
  String? get notes;
  int? get notificationId;

  /// Create a copy of MaintenanceEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MaintenanceEntryCopyWith<MaintenanceEntry> get copyWith =>
      _$MaintenanceEntryCopyWithImpl<MaintenanceEntry>(
          this as MaintenanceEntry, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MaintenanceEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vehicleId, vehicleId) ||
                other.vehicleId == vehicleId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.odometer, odometer) ||
                other.odometer == odometer) &&
            (identical(other.serviceDate, serviceDate) ||
                other.serviceDate == serviceDate) &&
            (identical(other.nextServiceDate, nextServiceDate) ||
                other.nextServiceDate == nextServiceDate) &&
            (identical(other.nextServiceOdometer, nextServiceOdometer) ||
                other.nextServiceOdometer == nextServiceOdometer) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.notificationId, notificationId) ||
                other.notificationId == notificationId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      vehicleId,
      type,
      title,
      description,
      cost,
      odometer,
      serviceDate,
      nextServiceDate,
      nextServiceOdometer,
      notes,
      notificationId);

  @override
  String toString() {
    return 'MaintenanceEntry(id: $id, vehicleId: $vehicleId, type: $type, title: $title, description: $description, cost: $cost, odometer: $odometer, serviceDate: $serviceDate, nextServiceDate: $nextServiceDate, nextServiceOdometer: $nextServiceOdometer, notes: $notes, notificationId: $notificationId)';
  }
}

/// @nodoc
abstract mixin class $MaintenanceEntryCopyWith<$Res> {
  factory $MaintenanceEntryCopyWith(
          MaintenanceEntry value, $Res Function(MaintenanceEntry) _then) =
      _$MaintenanceEntryCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String vehicleId,
      String type,
      String title,
      String description,
      double cost,
      double odometer,
      DateTime serviceDate,
      DateTime? nextServiceDate,
      int? nextServiceOdometer,
      String? notes,
      int? notificationId});
}

/// @nodoc
class _$MaintenanceEntryCopyWithImpl<$Res>
    implements $MaintenanceEntryCopyWith<$Res> {
  _$MaintenanceEntryCopyWithImpl(this._self, this._then);

  final MaintenanceEntry _self;
  final $Res Function(MaintenanceEntry) _then;

  /// Create a copy of MaintenanceEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vehicleId = null,
    Object? type = null,
    Object? title = null,
    Object? description = null,
    Object? cost = null,
    Object? odometer = null,
    Object? serviceDate = null,
    Object? nextServiceDate = freezed,
    Object? nextServiceOdometer = freezed,
    Object? notes = freezed,
    Object? notificationId = freezed,
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
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      cost: null == cost
          ? _self.cost
          : cost // ignore: cast_nullable_to_non_nullable
              as double,
      odometer: null == odometer
          ? _self.odometer
          : odometer // ignore: cast_nullable_to_non_nullable
              as double,
      serviceDate: null == serviceDate
          ? _self.serviceDate
          : serviceDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      nextServiceDate: freezed == nextServiceDate
          ? _self.nextServiceDate
          : nextServiceDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextServiceOdometer: freezed == nextServiceOdometer
          ? _self.nextServiceOdometer
          : nextServiceOdometer // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      notificationId: freezed == notificationId
          ? _self.notificationId
          : notificationId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [MaintenanceEntry].
extension MaintenanceEntryPatterns on MaintenanceEntry {
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
    TResult Function(_MaintenanceEntry value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MaintenanceEntry() when $default != null:
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
    TResult Function(_MaintenanceEntry value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MaintenanceEntry():
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
    TResult? Function(_MaintenanceEntry value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MaintenanceEntry() when $default != null:
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
            String type,
            String title,
            String description,
            double cost,
            double odometer,
            DateTime serviceDate,
            DateTime? nextServiceDate,
            int? nextServiceOdometer,
            String? notes,
            int? notificationId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MaintenanceEntry() when $default != null:
        return $default(
            _that.id,
            _that.vehicleId,
            _that.type,
            _that.title,
            _that.description,
            _that.cost,
            _that.odometer,
            _that.serviceDate,
            _that.nextServiceDate,
            _that.nextServiceOdometer,
            _that.notes,
            _that.notificationId);
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
            String type,
            String title,
            String description,
            double cost,
            double odometer,
            DateTime serviceDate,
            DateTime? nextServiceDate,
            int? nextServiceOdometer,
            String? notes,
            int? notificationId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MaintenanceEntry():
        return $default(
            _that.id,
            _that.vehicleId,
            _that.type,
            _that.title,
            _that.description,
            _that.cost,
            _that.odometer,
            _that.serviceDate,
            _that.nextServiceDate,
            _that.nextServiceOdometer,
            _that.notes,
            _that.notificationId);
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
            String type,
            String title,
            String description,
            double cost,
            double odometer,
            DateTime serviceDate,
            DateTime? nextServiceDate,
            int? nextServiceOdometer,
            String? notes,
            int? notificationId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MaintenanceEntry() when $default != null:
        return $default(
            _that.id,
            _that.vehicleId,
            _that.type,
            _that.title,
            _that.description,
            _that.cost,
            _that.odometer,
            _that.serviceDate,
            _that.nextServiceDate,
            _that.nextServiceOdometer,
            _that.notes,
            _that.notificationId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MaintenanceEntry implements MaintenanceEntry {
  const _MaintenanceEntry(
      {required this.id,
      required this.vehicleId,
      required this.type,
      required this.title,
      required this.description,
      required this.cost,
      required this.odometer,
      required this.serviceDate,
      this.nextServiceDate,
      this.nextServiceOdometer,
      this.notes,
      this.notificationId});

  @override
  final String id;
  @override
  final String vehicleId;
  @override
  final String type;
// 'parts' | 'repair'
  @override
  final String title;
  @override
  final String description;
  @override
  final double cost;
  @override
  final double odometer;
  @override
  final DateTime serviceDate;
  @override
  final DateTime? nextServiceDate;
  @override
  final int? nextServiceOdometer;
  @override
  final String? notes;
  @override
  final int? notificationId;

  /// Create a copy of MaintenanceEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MaintenanceEntryCopyWith<_MaintenanceEntry> get copyWith =>
      __$MaintenanceEntryCopyWithImpl<_MaintenanceEntry>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MaintenanceEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vehicleId, vehicleId) ||
                other.vehicleId == vehicleId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.odometer, odometer) ||
                other.odometer == odometer) &&
            (identical(other.serviceDate, serviceDate) ||
                other.serviceDate == serviceDate) &&
            (identical(other.nextServiceDate, nextServiceDate) ||
                other.nextServiceDate == nextServiceDate) &&
            (identical(other.nextServiceOdometer, nextServiceOdometer) ||
                other.nextServiceOdometer == nextServiceOdometer) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.notificationId, notificationId) ||
                other.notificationId == notificationId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      vehicleId,
      type,
      title,
      description,
      cost,
      odometer,
      serviceDate,
      nextServiceDate,
      nextServiceOdometer,
      notes,
      notificationId);

  @override
  String toString() {
    return 'MaintenanceEntry(id: $id, vehicleId: $vehicleId, type: $type, title: $title, description: $description, cost: $cost, odometer: $odometer, serviceDate: $serviceDate, nextServiceDate: $nextServiceDate, nextServiceOdometer: $nextServiceOdometer, notes: $notes, notificationId: $notificationId)';
  }
}

/// @nodoc
abstract mixin class _$MaintenanceEntryCopyWith<$Res>
    implements $MaintenanceEntryCopyWith<$Res> {
  factory _$MaintenanceEntryCopyWith(
          _MaintenanceEntry value, $Res Function(_MaintenanceEntry) _then) =
      __$MaintenanceEntryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String vehicleId,
      String type,
      String title,
      String description,
      double cost,
      double odometer,
      DateTime serviceDate,
      DateTime? nextServiceDate,
      int? nextServiceOdometer,
      String? notes,
      int? notificationId});
}

/// @nodoc
class __$MaintenanceEntryCopyWithImpl<$Res>
    implements _$MaintenanceEntryCopyWith<$Res> {
  __$MaintenanceEntryCopyWithImpl(this._self, this._then);

  final _MaintenanceEntry _self;
  final $Res Function(_MaintenanceEntry) _then;

  /// Create a copy of MaintenanceEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? vehicleId = null,
    Object? type = null,
    Object? title = null,
    Object? description = null,
    Object? cost = null,
    Object? odometer = null,
    Object? serviceDate = null,
    Object? nextServiceDate = freezed,
    Object? nextServiceOdometer = freezed,
    Object? notes = freezed,
    Object? notificationId = freezed,
  }) {
    return _then(_MaintenanceEntry(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      vehicleId: null == vehicleId
          ? _self.vehicleId
          : vehicleId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      cost: null == cost
          ? _self.cost
          : cost // ignore: cast_nullable_to_non_nullable
              as double,
      odometer: null == odometer
          ? _self.odometer
          : odometer // ignore: cast_nullable_to_non_nullable
              as double,
      serviceDate: null == serviceDate
          ? _self.serviceDate
          : serviceDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      nextServiceDate: freezed == nextServiceDate
          ? _self.nextServiceDate
          : nextServiceDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextServiceOdometer: freezed == nextServiceOdometer
          ? _self.nextServiceOdometer
          : nextServiceOdometer // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      notificationId: freezed == notificationId
          ? _self.notificationId
          : notificationId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
