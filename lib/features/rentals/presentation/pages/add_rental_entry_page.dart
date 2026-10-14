import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/rental_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/usecases/vehicle_usecases.dart';
import '../../data/rental_driver_options.dart';
import '../../domain/entities/rental_entry.dart';
import '../../domain/rental_booking_id.dart';
import '../../domain/usecases/rental_usecases.dart';

class AddRentalEntryPage extends StatefulWidget {
  const AddRentalEntryPage({super.key, this.initialEntry});

  final RentalEntry? initialEntry;

  @override
  State<AddRentalEntryPage> createState() => _AddRentalEntryPageState();
}

class _AddRentalEntryPageState extends State<AddRentalEntryPage> {
  final _formKey = GlobalKey<FormState>();

  final _customerCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _fromCustomCtrl = TextEditingController();
  final _toCustomCtrl = TextEditingController();
  final _startKmCtrl = TextEditingController();
  final _endKmCtrl = TextEditingController();
  final _fareCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController(text: '0');
  final _fuelCostCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  DateTime _bookingDate = DateTime.now();
  DateTime _startDateTime = DateTime.now();
  DateTime _endDateTime = DateTime.now().add(const Duration(hours: 2));
  String _tripType = 'Daily';
  String _tripLeg = 'Single trip';
  String _fuelProvidedBy = 'Owner';
  String _driverMode = 'Self';
  String _driverDirectorySelection = 'Custom';
  String _paymentStatus = 'Due';
  String? _vehicleId;
  String? _nextBookingPreview;
  bool _isSaving = false;
  List<Vehicle> _vehicles = const [];
  bool _hasRentalFleet = false;
  bool _fleetLoaded = false;
  bool _isEditMode = false;

  /// Blocks a vehicle when a prior rental is unpaid/partial, or the trip is in progress.
  static bool _rentalBlocksVehicle(RentalEntry r, DateTime now) {
    if (r.paymentStatus != 'Paid') return true;
    return !now.isBefore(r.startDateTime) && !now.isAfter(r.endDateTime);
  }

  String _fromSelection = RentalRoutes.locations.first;
  String _toSelection = RentalRoutes.locations.first;

  static const List<String> _tripTypes = [
    'Daily',
    'Monthly',
    'Trip',
    'Airport',
    'Contract'
  ];
  static const List<String> _tripLegs = ['Single trip', 'Round trip'];
  static const List<String> _paymentStatuses = ['Paid', 'Partial', 'Due'];
  static const List<String> _fuelProviders = ['Owner', 'Customer'];
  static const List<String> _driverModes = ['Self', 'Driver'];

  double get _startKm => double.tryParse(_startKmCtrl.text.trim()) ?? 0;
  double get _endKm => double.tryParse(_endKmCtrl.text.trim()) ?? 0;
  double get _fare => double.tryParse(_fareCtrl.text.trim()) ?? 0;
  double get _advance => double.tryParse(_advanceCtrl.text.trim()) ?? 0;
  double get _fuelCost => double.tryParse(_fuelCostCtrl.text.trim()) ?? 0;
  double get _totalKm =>
      _isEditMode ? (_endKm - _startKm).clamp(0, double.infinity) : 0;

  Vehicle? _selectedVehicle() {
    final id = _vehicleId;
    if (id == null) return null;
    for (final v in _vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }

  double get _startKmResolved {
    final raw = _startKmCtrl.text.trim();
    if (raw.isEmpty) {
      return _selectedVehicle()?.currentOdometer ?? 0;
    }
    return double.tryParse(raw) ?? 0;
  }

  /// When fuel is provided by the customer, fuel cost is subtracted from fare for billable / due.
  bool get _customerCoversFuelCost => _fuelProvidedBy == 'Customer';

  double get _billableTripAmount => RentalEntry.billableTripAmount(
        rentFareAmount: _fare,
        fuelCost: _fuelCost,
        customerPaidFuelBill: _customerCoversFuelCost,
      );

  double get _dueAmount => _billableTripAmount - _advance;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.initialEntry != null;

    if (widget.initialEntry != null) {
      final e = widget.initialEntry!;
      _bookingDate = e.bookingDate;
      _startDateTime = e.startDateTime;
      _endDateTime = e.endDateTime;
      _tripType = e.tripType;
      _tripLeg = e.tripLeg;
      _fuelProvidedBy = e.fuelProvidedBy;
      _driverMode = e.driverMode;
      _paymentStatus = e.paymentStatus;
      _vehicleId = e.vehicleId;

      _customerCtrl.text = e.customerName;
      _phoneCtrl.text = e.phone;
      _fareCtrl.text = e.rentFareAmount.toString();
      _advanceCtrl.text = e.advanceReceived.toString();
      _fuelCostCtrl.text = e.fuelCost.toString();
      _notesCtrl.text = e.notes ?? '';

      if (RentalRoutes.locations.contains(e.fromLocation) &&
          e.fromLocation != RentalRoutes.custom) {
        _fromSelection = e.fromLocation;
        _fromCustomCtrl.clear();
      } else {
        _fromSelection = RentalRoutes.custom;
        _fromCustomCtrl.text = e.fromLocation;
      }
      if (RentalRoutes.locations.contains(e.toLocation) &&
          e.toLocation != RentalRoutes.custom) {
        _toSelection = e.toLocation;
        _toCustomCtrl.clear();
      } else {
        _toSelection = RentalRoutes.custom;
        _toCustomCtrl.text = e.toLocation;
      }

      _startKmCtrl.text = e.startKm.toStringAsFixed(0);
      _endKmCtrl.text = e.endKm.toStringAsFixed(0);

      final driverName = (e.driverName ?? '').trim();
      _driverDirectorySelection =
          driverName.isNotEmpty && driverName != 'Custom'
              ? driverName
              : 'Custom';
      if (_driverDirectorySelection != 'Custom' &&
          rentalDriverDirectory
              .every((d) => d.name != _driverDirectorySelection)) {
        _driverDirectorySelection = 'Custom';
      }

      _driverNameCtrl.text = e.driverName ?? '';
      _driverPhoneCtrl.text = e.driverPhone ?? '';

      _nextBookingPreview = e.bookingId;
    }

    _startKmCtrl.addListener(_recompute);
    _endKmCtrl.addListener(_recompute);
    _fareCtrl.addListener(_recompute);
    _advanceCtrl.addListener(_recompute);
    _fuelCostCtrl.addListener(_recompute);
    _loadVehiclesAndBookingPreview();
  }

  Future<void> _loadVehiclesAndBookingPreview() async {
    final vehicles = await sl<GetAllVehicles>()();
    if (!mounted) return;

    if (_isEditMode && widget.initialEntry != null) {
      final entryVehicleId = widget.initialEntry!.vehicleId;
      Vehicle? entryVehicle;
      for (final v in vehicles) {
        if (v.id == entryVehicleId) {
          entryVehicle = v;
          break;
        }
      }
      setState(() {
        _hasRentalFleet = vehicles.any((v) => v.isRental);
        _fleetLoaded = true;
        _vehicles = entryVehicle != null ? [entryVehicle] : const [];
        _vehicleId = entryVehicleId;
        _nextBookingPreview = widget.initialEntry!.bookingId;
        _paymentStatus = widget.initialEntry!.paymentStatus;
      });
      return;
    }

    final rentals = await sl<GetAllRentals>()();
    if (!mounted) return;
    final now = DateTime.now();
    final eligibleVehicles = vehicles.where((v) {
      if (!v.isRental) return false;
      final blocked = rentals.any(
        (r) => r.vehicleId == v.id && _rentalBlocksVehicle(r, now),
      );
      return !blocked;
    }).toList();

    setState(() {
      _hasRentalFleet = vehicles.any((v) => v.isRental);
      _fleetLoaded = true;
      _vehicles = eligibleVehicles;
      _vehicleId =
          _vehicles.isNotEmpty ? _vehicleId ?? _vehicles.first.id : null;
      _nextBookingPreview = RentalBookingId.next(rentals);
      _paymentStatus = _defaultPaymentStatus();
    });

    final v = _selectedVehicle();
    if (v != null) {
      _startKmCtrl.text = v.currentOdometer.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _phoneCtrl.dispose();
    _fromCustomCtrl.dispose();
    _toCustomCtrl.dispose();
    _startKmCtrl.dispose();
    _endKmCtrl.dispose();
    _fareCtrl.dispose();
    _advanceCtrl.dispose();
    _fuelCostCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _recompute() {
    setState(() {
      if (!_isEditMode) {
        _paymentStatus = _defaultPaymentStatus();
      }
    });
  }

  String _defaultPaymentStatus() {
    final due = _billableTripAmount - _advance;
    if (due <= 0) return 'Paid';
    if (_advance > 0 && _advance < _billableTripAmount) return 'Partial';
    return 'Due';
  }

  String _resolvedFrom() {
    if (_fromSelection == RentalRoutes.custom)
      return _fromCustomCtrl.text.trim();
    return _fromSelection;
  }

  String _resolvedTo() {
    if (_toSelection == RentalRoutes.custom) return _toCustomCtrl.text.trim();
    return _toSelection;
  }

  String _bookingIdForSave(Iterable<RentalEntry> rentals) {
    if (_isEditMode) return widget.initialEntry!.bookingId;
    return RentalBookingId.next(rentals);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final showTripLeg = _tripType == 'Trip';
    final fromLabel =
        _fromSelection == RentalRoutes.custom ? 'From (custom) *' : 'From *';
    final toLabel =
        _toSelection == RentalRoutes.custom ? 'To (custom) *' : 'To *';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Rental Entry' : 'Add Rental Entry'),
      ),
      body: !_fleetLoaded
          ? const Center(child: CircularProgressIndicator())
          : _isEditMode && _vehicles.isEmpty
              ? const Center(child: Text('Vehicle not found for this rental.'))
              : !_isEditMode && _vehicles.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _hasRentalFleet
                              ? 'No vehicle is available right now. Finish or settle previous rentals first.'
                              : 'Add a vehicle marked for rental first to create bookings.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey('vehicle_$_vehicleId'),
                            initialValue: _vehicleId,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle *',
                              prefixIcon: Icon(Icons.directions_car_outlined),
                            ),
                            items: _vehicles
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v.id,
                                    child:
                                        Text('${v.name} (${v.licensePlate})'),
                                  ),
                                )
                                .toList(),
                            onChanged: _isEditMode
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    final v = _vehicles
                                        .firstWhere((x) => x.id == value);
                                    setState(() {
                                      _vehicleId = value;
                                      _startKmCtrl.text =
                                          v.currentOdometer.toStringAsFixed(0);
                                    });
                                  },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),
                          if (_nextBookingPreview != null)
                            _readOnlyMetric(
                              context,
                              label: _isEditMode
                                  ? 'Booking ID'
                                  : 'Booking ID (auto)',
                              value: Formatters.formatBookingId(
                                  _nextBookingPreview!),
                              color: colors.textSecondary,
                            ),
                          const SizedBox(height: 12),
                          _dateTile(
                            context,
                            label: 'Booking Date',
                            value: Formatters.formatDate(_bookingDate),
                            onTap: () => _pickDate(booking: true),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _customerCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Customer name *',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Customer phone *',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<String>(
                            segments: _driverModes
                                .map((m) => ButtonSegment<String>(
                                    value: m, label: Text(m)))
                                .toList(),
                            selected: {_driverMode},
                            onSelectionChanged: (s) {
                              setState(() {
                                _driverMode = s.first;
                                if (_driverMode != 'Driver') {
                                  _driverDirectorySelection = 'Custom';
                                  _driverNameCtrl.clear();
                                  _driverPhoneCtrl.clear();
                                }
                              });
                            },
                          ),
                          if (_driverMode == 'Driver') ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _driverDirectorySelection,
                              decoration: const InputDecoration(
                                labelText: 'Driver selection *',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              isExpanded: true,
                              items: rentalDriverDirectory
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d.name,
                                      child: Text(d.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                final name = v ?? 'Custom';
                                final option = rentalDriverDirectory.firstWhere(
                                    (d) => d.name == name,
                                    orElse: () => rentalDriverDirectory.last);
                                setState(() {
                                  _driverDirectorySelection = option.name;
                                  _driverNameCtrl.text = option.name == 'Custom'
                                      ? ''
                                      : option.name;
                                  _driverPhoneCtrl.text = option.phone;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_driverDirectorySelection == 'Custom') ...[
                              TextFormField(
                                controller: _driverNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Driver name *',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (v) {
                                  if (_driverMode != 'Driver') return null;
                                  if (v == null || v.trim().isEmpty)
                                    return 'Enter driver name';
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _driverPhoneCtrl,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Driver phone',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey('from_$_fromSelection'),
                            initialValue: _fromSelection,
                            decoration: InputDecoration(
                              labelText: fromLabel,
                              prefixIcon: const Icon(Icons.trip_origin),
                            ),
                            items: RentalRoutes.locations
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _fromSelection = v!),
                          ),
                          if (_fromSelection == RentalRoutes.custom) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fromCustomCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Custom from *',
                                prefixIcon:
                                    Icon(Icons.edit_location_alt_outlined),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (_fromSelection != RentalRoutes.custom)
                                  return null;
                                if (v == null || v.trim().isEmpty)
                                  return 'Required';
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey('to_$_toSelection'),
                            initialValue: _toSelection,
                            decoration: InputDecoration(
                              labelText: toLabel,
                              prefixIcon: const Icon(Icons.place_outlined),
                            ),
                            items: RentalRoutes.locations
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => _toSelection = v!),
                          ),
                          if (_toSelection == RentalRoutes.custom) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _toCustomCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Custom to *',
                                prefixIcon:
                                    Icon(Icons.edit_location_alt_outlined),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (_toSelection != RentalRoutes.custom)
                                  return null;
                                if (v == null || v.trim().isEmpty)
                                  return 'Required';
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_tripType),
                            initialValue: _tripType,
                            decoration:
                                const InputDecoration(labelText: 'Trip Type *'),
                            items: _tripTypes
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => _tripType = v!),
                          ),
                          if (showTripLeg) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _tripLeg,
                              decoration: const InputDecoration(
                                labelText: 'Trip pattern *',
                                helperText: 'Single or round trip',
                              ),
                              items: _tripLegs
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => _tripLeg = v!),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _dateTile(
                            context,
                            label: 'Start Date/Time',
                            value: Formatters.formatDateTime(_startDateTime),
                            onTap: () => _pickDateTime(start: true),
                          ),
                          const SizedBox(height: 12),
                          _dateTile(
                            context,
                            label: 'End Date/Time',
                            value: Formatters.formatDateTime(_endDateTime),
                            onTap: () => _pickDateTime(start: false),
                          ),
                          const SizedBox(height: 12),
                          if (_isEditMode)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _startKmCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                        labelText: 'Start KM *'),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Required';
                                      final n = double.tryParse(v);
                                      if (n == null || n < 0) return 'Invalid';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _endKmCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                        labelText: 'End KM *'),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Required';
                                      final n = double.tryParse(v);
                                      if (n == null || n < 0) return 'Invalid';
                                      if (n < _startKm)
                                        return 'End KM must be >= Start KM';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            TextFormField(
                              controller: _startKmCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Start KM (optional)'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final n = double.tryParse(v);
                                if (n == null || n < 0) return 'Invalid';
                                return null;
                              },
                            ),
                          const SizedBox(height: 10),
                          _readOnlyMetric(
                            context,
                            label: 'Total KM (computed)',
                            value: Formatters.formatDistance(_totalKm),
                            color: colors.maintenanceColor,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _fareCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      labelText: 'Rent/Fare Amount *'),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Required';
                                    final n = double.tryParse(v);
                                    if (n == null || n < 0) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _advanceCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      labelText: 'Advance Received *'),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Required';
                                    final n = double.tryParse(v);
                                    if (n == null || n < 0) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_fuelProvidedBy),
                            initialValue: _fuelProvidedBy,
                            decoration: InputDecoration(
                              labelText: 'Fuel provided by *',
                              helperText: _customerCoversFuelCost
                                  ? 'Customer: fuel cost is subtracted from fare for billable amount and due.'
                                  : 'Owner: fare is unchanged by fuel cost.',
                              prefixIcon:
                                  const Icon(Icons.local_gas_station_outlined),
                            ),
                            items: _fuelProviders
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() {
                              _fuelProvidedBy = v!;
                              if (!_isEditMode) {
                                _paymentStatus = _defaultPaymentStatus();
                              }
                            }),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _fuelCostCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Fuel cost',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final n = double.tryParse(v);
                              if (n == null || n < 0) return 'Invalid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          _readOnlyMetric(
                            context,
                            label: 'Billable trip (after customer fuel)',
                            value:
                                Formatters.formatCurrency(_billableTripAmount),
                            color: colors.maintenanceColor,
                          ),
                          const SizedBox(height: 10),
                          _readOnlyMetric(
                            context,
                            label: 'Due Amount (computed)',
                            value: Formatters.formatCurrency(_dueAmount),
                            color: _dueAmount <= 0
                                ? colors.success
                                : colors.warning,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_paymentStatus),
                            initialValue: _paymentStatus,
                            decoration: const InputDecoration(
                                labelText: 'Payment Status *'),
                            items: _paymentStatuses
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _paymentStatus = v!),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'Notes', alignLabelWithHint: true),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _isSaving ? null : _save,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_isEditMode
                                    ? 'Update Rental'
                                    : 'Save Rental'),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  Widget _dateTile(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value),
      ),
    );
  }

  Widget _readOnlyMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color)),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool booking}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    if (booking) setState(() => _bookingDate = picked);
  }

  Future<void> _pickDateTime({required bool start}) async {
    final initial = start ? _startDateTime : _endDateTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null || !mounted) return;
    final value =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (start) {
        _startDateTime = value;
      } else {
        _endDateTime = value;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleId == null) return;
    if (_driverMode == 'Driver' && _driverNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter driver name')),
      );
      return;
    }
    final from = _resolvedFrom();
    final to = _resolvedTo();
    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete from and to')),
      );
      return;
    }
    if (_endDateTime.isBefore(_startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('End date/time must be after start date/time')),
      );
      return;
    }
    if (_isEditMode && _endKm < _startKm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End KM must be greater than or equal to Start KM'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final rentals = await sl<GetAllRentals>()();
      final bookingId = _bookingIdForSave(rentals);
      final leg = _tripType == 'Trip' ? _tripLeg : '';
      final customerPaidFuelBill = _customerCoversFuelCost;
      final due = RentalEntry.computeDue(
        rentFareAmount: _fare,
        advanceReceived: _advance,
        fuelCost: _fuelCost,
        customerPaidFuelBill: customerPaidFuelBill,
      );

      final startKm = _startKmResolved;
      final endKm = _isEditMode ? _endKm : startKm;
      final entry = RentalEntry(
        id: _isEditMode ? widget.initialEntry!.id : const Uuid().v4(),
        vehicleId: _vehicleId!,
        bookingId: bookingId,
        bookingDate: _bookingDate,
        customerName: _customerCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        fromLocation: from,
        toLocation: to,
        tripType: _tripType,
        tripLeg: leg,
        startDateTime: _startDateTime,
        endDateTime: _endDateTime,
        startKm: startKm,
        endKm: endKm,
        totalKm: _isEditMode ? (endKm - startKm) : 0,
        rentFareAmount: _fare,
        advanceReceived: _advance,
        dueAmount: due,
        paymentStatus: _paymentStatus,
        fuelProvidedBy: _fuelProvidedBy,
        driverMode: _driverMode,
        driverName:
            _driverMode == 'Driver' ? _driverNameCtrl.text.trim() : null,
        driverPhone: _driverMode == 'Driver'
            ? (_driverPhoneCtrl.text.trim().isEmpty
                ? null
                : _driverPhoneCtrl.text.trim())
            : null,
        fuelCost: _fuelCost,
        customerPaidFuelBill: customerPaidFuelBill,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (_isEditMode) {
        await sl<UpdateRental>()(entry);
      } else {
        await sl<AddRental>()(entry);
      }
      await _syncVehicleOdometerAfterRentalSave(entry);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save rental: $e')),
      );
    }
  }

  /// Adds this rental's trip distance (or the edit delta) to the vehicle odometer.
  Future<void> _syncVehicleOdometerAfterRentalSave(RentalEntry entry) async {
    final vehicle = await sl<GetVehicleById>()(entry.vehicleId);
    if (vehicle == null) return;
    final double deltaTripKm;
    if (_isEditMode && widget.initialEntry != null) {
      deltaTripKm = entry.totalKm - widget.initialEntry!.totalKm;
    } else {
      deltaTripKm = entry.totalKm;
    }
    if (deltaTripKm == 0) return;
    final updatedReading = vehicle.currentOdometer + deltaTripKm;
    final clampedReading = updatedReading < vehicle.initialOdometer
        ? vehicle.initialOdometer
        : updatedReading;
    await sl<UpdateVehicle>()(
      vehicle.copyWith(currentOdometer: clampedReading),
    );
  }
}
