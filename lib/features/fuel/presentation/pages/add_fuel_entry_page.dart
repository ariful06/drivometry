import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/receipt_storage.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/usecases/vehicle_usecases.dart';
import '../../domain/entities/fuel_entry.dart';
import '../../domain/services/fuel_consumption_calculator.dart';
import '../../domain/usecases/fuel_usecases.dart';

/// Distances + money fields: decimal keypad. On iOS, plain unsigned decimal maps to
/// `UIKeyboardTypeDecimalPad`, which is broken/invisible as a Liquid Glass bubble on
/// iPadOS 26+ ([flutter/flutter#178096](https://github.com/flutter/flutter/issues/178096)).
/// `signed: true` yields `NumbersAndPunctuation` instead and restores a usable numeric keyboard.
TextInputType _fuelEntryKeyboardTypeForPlatform() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    return const TextInputType.numberWithOptions(decimal: true, signed: true);
  }
  return const TextInputType.numberWithOptions(decimal: true, signed: false);
}

/// Keeps odometer/amount fields to digits plus `.`/` ,` when iOS uses the signed-number keyboard workaround.
final _fuelNumericInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
];

class AddFuelEntryPage extends StatefulWidget {
  const AddFuelEntryPage({required this.vehicle, super.key});

  final Vehicle vehicle;

  @override
  State<AddFuelEntryPage> createState() => _AddFuelEntryPageState();
}

class _AddFuelEntryPageState extends State<AddFuelEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextInputType _fuelNumericKeyboard =
      _fuelEntryKeyboardTypeForPlatform();
  final _tripKmCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _litersCtrl = TextEditingController();
  final _totalPaidCtrl = TextEditingController();
  final _costPerLiterCtrl = TextEditingController();

  /// Optional override of the tank capacity on a full-tank fill.
  final _fullTankLitersCtrl = TextEditingController();

  /// Optional fuel gauge % after a partial fill (enables estimated consumption).
  final _fuelLevelCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  /// `false` = enter liters; `true` = enter total paid and derive liters as
  /// total ÷ cost per liter.
  bool _useTotalPaidForQuantity = false;

  /// Last fuel entry for this vehicle (loaded on init); used to show last refill amount.
  FuelEntry? _lastFuelEntry;

  /// All saved fills for this vehicle; full-tank consumption needs the whole chain
  /// back to the previous full tank (partial fills in between add their liters).
  List<FuelEntry> _fuelHistory = const [];
  bool _lastEntryLoading = true;

  /// After the first log: `true` = trip km since last fill; `false` = dashboard odometer.
  bool _useTripMode = true;

  /// Filled to the brim. Consumption is measured between two full-tank fills.
  bool _isFullTank = true;

  /// A fill-up since the last log was not recorded; breaks the measurement chain.
  bool _missedPreviousFill = false;

  /// Optional receipt image picked by user; saved to app storage on submit.
  String? _pickedReceiptPath;

  /// Trip / odometer / history inputs changed.
  final ValueNotifier<int> _mileagePreviewTick = ValueNotifier(0);

  /// Liters, price, total paid inputs changed.
  final ValueNotifier<int> _costSummaryTick = ValueNotifier(0);

  /// Consumption preview depends on distance and liters.
  late final Listenable _consumptionPreviewListenable =
      Listenable.merge([_mileagePreviewTick, _costSummaryTick]);

  late final ImagePicker _imagePicker;

  void _bumpMileagePreview() {
    _mileagePreviewTick.value++;
  }

  void _bumpCostSummary() {
    _costSummaryTick.value++;
  }

  /// First fuel log for this vehicle: no previous entry, so we don't ask for trip distance.
  bool get _isFirstFuelLog => !_lastEntryLoading && _lastFuelEntry == null;

  bool get _showRefillOptions => !_lastEntryLoading && !_isFirstFuelLog;

  double get _parsedCostPerLiter {
    final raw = _costPerLiterCtrl.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  /// Full tank fill takes its liters from the vehicle's tank capacity, so no
  /// quantity input is needed. Without a capacity, liters are entered as usual.
  bool get _fullTankUsesCapacity =>
      _isFullTank && widget.vehicle.tankCapacityLiters != null;

  /// Quantity comes from "Total paid" (only when liters are not from capacity).
  bool get _quantityFromTotalPaid =>
      !_fullTankUsesCapacity && _useTotalPaidForQuantity;

  /// Liters typed in the optional full-tank override, if valid.
  double? get _fullTankLitersOverride {
    final parsed = double.tryParse(
      _fullTankLitersCtrl.text.trim().replaceAll(',', '.'),
    );
    return parsed != null && parsed > 0 ? parsed : null;
  }

  double? get _parsedFuelLevelPercent {
    final parsed = double.tryParse(
      _fuelLevelCtrl.text.trim().replaceAll(',', '.'),
    );
    return parsed != null && parsed >= 0 && parsed <= 100 ? parsed : null;
  }

  double get _totalCost {
    if (_quantityFromTotalPaid) {
      final rawTotal = _totalPaidCtrl.text.trim().replaceAll(',', '.');
      return double.tryParse(rawTotal) ?? 0;
    }
    return _effectiveLiters * _parsedCostPerLiter;
  }

  /// Liters to use: full tank → pumped override or tank capacity; total-paid
  /// mode → total ÷ price; else typed liters.
  double get _effectiveLiters {
    if (_fullTankUsesCapacity) {
      return _fullTankLitersOverride ?? widget.vehicle.tankCapacityLiters!;
    }
    if (_quantityFromTotalPaid) {
      final rawTotal = _totalPaidCtrl.text.trim().replaceAll(',', '.');
      final totalPaid = double.tryParse(rawTotal) ?? 0;
      final costPerLiter = _parsedCostPerLiter;
      if (totalPaid <= 0 || costPerLiter <= 0) return 0;
      return totalPaid / costPerLiter;
    }
    final rawLiters = _litersCtrl.text.trim().replaceAll(',', '.');
    if (rawLiters.isEmpty) return 0;
    return double.tryParse(rawLiters) ?? 0;
  }

  void _onQuantityEntryModeChanged(Set<bool> selectedModes) {
    if (selectedModes.length != 1) return;
    final useTotalPaid = selectedModes.single;
    if (useTotalPaid == _useTotalPaidForQuantity) return;
    setState(() {
      _useTotalPaidForQuantity = useTotalPaid;
      if (useTotalPaid) {
        _litersCtrl.clear();
      } else {
        _totalPaidCtrl.clear();
      }
    });
    _bumpCostSummary();
  }

  double? get _tripKmParsed => double.tryParse(_tripKmCtrl.text.trim());

  /// New odometer when trip mode and trip is valid.
  double? get _odometerFromTrip {
    final trip = _tripKmParsed;
    if (trip == null || trip <= 0) return null;
    return widget.vehicle.currentOdometer + trip;
  }

  /// Km since last refill (trip) or odometer delta (full odo mode).
  double? get _distanceKmForPreview {
    if (!_showRefillOptions) return null;
    if (_useTripMode) {
      final trip = _tripKmParsed;
      if (trip == null || trip <= 0) return null;
      return trip;
    }
    final odo = double.tryParse(_odometerCtrl.text.trim());
    if (odo == null || odo <= widget.vehicle.currentOdometer) return null;
    return odo - widget.vehicle.currentOdometer;
  }

  /// Fill being entered, as the calculator sees it. Null until distance is valid.
  FuelEntry? get _draftEntryForPreview {
    final distanceKm = _distanceKmForPreview;
    if (distanceKm == null) return null;
    return FuelEntry(
      id: '__draft__',
      vehicleId: widget.vehicle.id,
      date: _date,
      odometer: widget.vehicle.currentOdometer + distanceKm,
      liters: _effectiveLiters,
      costPerLiter: _parsedCostPerLiter,
      totalCost: _totalCost,
      isFullTank: _isFullTank,
      missedPreviousFill: _missedPreviousFill,
      fuelLevelPercent: _isFullTank ? null : _parsedFuelLevelPercent,
    );
  }

  /// Consumption this fill would close (full-to-full, or gauge estimate).
  FuelConsumptionSegment? get _consumptionPreview {
    final draft = _draftEntryForPreview;
    if (draft == null || draft.liters <= 0) return null;
    return FuelConsumptionCalculator.previewForDraft(
      _fuelHistory,
      draft,
      tankCapacityLiters: widget.vehicle.tankCapacityLiters,
    );
  }

  void _onDistanceModeChanged(bool useTrip) {
    if (useTrip == _useTripMode) return;
    setState(() {
      if (useTrip) {
        final odo = double.tryParse(_odometerCtrl.text.trim());
        if (odo != null && odo > widget.vehicle.currentOdometer) {
          _tripKmCtrl.text =
              (odo - widget.vehicle.currentOdometer).toStringAsFixed(0);
        } else {
          _tripKmCtrl.clear();
        }
        _useTripMode = true;
      } else {
        final trip = _tripKmParsed;
        if (trip != null && trip > 0) {
          _odometerCtrl.text =
              (widget.vehicle.currentOdometer + trip).toStringAsFixed(0);
        }
        _useTripMode = false;
      }
    });
    _bumpMileagePreview();
  }

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
    _odometerCtrl.text = widget.vehicle.currentOdometer.toStringAsFixed(0);
    _tripKmCtrl.addListener(_bumpMileagePreview);
    _odometerCtrl.addListener(_bumpMileagePreview);
    _litersCtrl.addListener(_bumpCostSummary);
    _totalPaidCtrl.addListener(_bumpCostSummary);
    _costPerLiterCtrl.addListener(_bumpCostSummary);
    _fullTankLitersCtrl.addListener(_bumpCostSummary);
    _fuelLevelCtrl.addListener(_bumpCostSummary);
    _loadLastFuelEntry();
  }

  Future<void> _loadLastFuelEntry() async {
    try {
      // Newest first, so the last fill is the head of the history.
      final history = await sl<GetFuelEntriesByVehicle>()(widget.vehicle.id);
      if (mounted) {
        setState(() {
          _lastFuelEntry = history.firstOrNull;
          _fuelHistory = history;
          _lastEntryLoading = false;
        });
        _bumpMileagePreview();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _lastEntryLoading = false);
        _bumpMileagePreview();
      }
    }
  }

  @override
  void dispose() {
    _tripKmCtrl.removeListener(_bumpMileagePreview);
    _odometerCtrl.removeListener(_bumpMileagePreview);
    _litersCtrl.removeListener(_bumpCostSummary);
    _totalPaidCtrl.removeListener(_bumpCostSummary);
    _costPerLiterCtrl.removeListener(_bumpCostSummary);
    _fullTankLitersCtrl.removeListener(_bumpCostSummary);
    _fuelLevelCtrl.removeListener(_bumpCostSummary);
    _mileagePreviewTick.dispose();
    _costSummaryTick.dispose();
    _tripKmCtrl.dispose();
    _odometerCtrl.dispose();
    _litersCtrl.dispose();
    _totalPaidCtrl.dispose();
    _costPerLiterCtrl.dispose();
    _fullTankLitersCtrl.dispose();
    _fuelLevelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Log fuel'),
            const SizedBox(height: 2),
            Text(
              widget.vehicle.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          children: [
            _DatePickerField(date: _date, onTap: _pickDate),
            const SizedBox(height: 20),
            if (_lastEntryLoading) ...[
              _FuelContextCardSkeleton(colors: colors),
            ] else ...[
              _FuelContextCard(
                tankCapacityLiters: widget.vehicle.tankCapacityLiters,
                lastRefillLiters: _lastFuelEntry?.liters,
                colors: colors,
                baselineOdometer:
                    _isFirstFuelLog ? null : widget.vehicle.currentOdometer,
              ),
            ],
            const SizedBox(height: 20),
            if (_showRefillOptions) ...[
              _DistanceModeSelector(
                useTripMode: _useTripMode,
                onChanged: _onDistanceModeChanged,
                colors: colors,
              ),
              const SizedBox(height: 14),
            ],
            if (_isFirstFuelLog || _lastEntryLoading) ...[
              TextFormField(
                controller: _odometerCtrl,
                keyboardType: _fuelNumericKeyboard,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                spellCheckConfiguration:
                    const SpellCheckConfiguration.disabled(),
                enableIMEPersonalizedLearning: false,
                inputFormatters: _fuelNumericInputFormatters,
                decoration: InputDecoration(
                  labelText: 'Odometer (km) *',
                  hintText: _lastEntryLoading
                      ? 'Current reading on dashboard'
                      : 'Current reading on dashboard',
                  prefixIcon: const Icon(Icons.speed_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
            ] else if (_useTripMode) ...[
              _BaselineOdometerHint(
                odometer: widget.vehicle.currentOdometer,
                colors: colors,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('fuel_trip_km_field'),
                controller: _tripKmCtrl,
                keyboardType: _fuelNumericKeyboard,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                spellCheckConfiguration:
                    const SpellCheckConfiguration.disabled(),
                enableIMEPersonalizedLearning: false,
                inputFormatters: _fuelNumericInputFormatters,
                decoration: const InputDecoration(
                  labelText: 'Km since last refill *',
                  hintText: 'e.g. 420',
                  prefixIcon: Icon(Icons.route_outlined),
                  suffixText: 'km',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Enter distance since last fill';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a positive distance';
                  return null;
                },
              ),
              ListenableBuilder(
                listenable: _mileagePreviewTick,
                builder: (context, _) {
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_odometerFromTrip != null) ...[
                          const SizedBox(height: 12),
                          _ComputedOdometerTile(
                            value: _odometerFromTrip!,
                            colors: colors,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              TextFormField(
                key: const ValueKey('fuel_full_odo_field'),
                controller: _odometerCtrl,
                keyboardType: _fuelNumericKeyboard,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                spellCheckConfiguration:
                    const SpellCheckConfiguration.disabled(),
                enableIMEPersonalizedLearning: false,
                inputFormatters: _fuelNumericInputFormatters,
                decoration: const InputDecoration(
                  labelText: 'Odometer (km) *',
                  hintText: 'Reading on dashboard now',
                  prefixIcon: Icon(Icons.speed_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null) return 'Invalid number';
                  if (n <= widget.vehicle.currentOdometer) {
                    return 'Must be greater than saved ${Formatters.formatDistance(widget.vehicle.currentOdometer)}';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            Material(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              child: SwitchListTile.adaptive(
                value: _isFullTank,
                onChanged: (fullTankEnabled) {
                  setState(() => _isFullTank = fullTankEnabled);
                  _bumpCostSummary();
                },
                title: const Text('Full tank'),
                subtitle: Text(
                  !_isFullTank
                      ? 'Partial fill — liters are added to the next full tank\'s consumption'
                      : _fullTankUsesCapacity
                          ? 'Uses ${Formatters.formatNumber(widget.vehicle.tankCapacityLiters!)} L tank capacity × price per liter'
                          : 'Filled to the brim — add tank capacity in vehicle settings to skip entering liters',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.35)),
                ),
              ),
            ),
            if (_showRefillOptions) ...[
              const SizedBox(height: 10),
              Material(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                child: SwitchListTile.adaptive(
                  value: _missedPreviousFill,
                  onChanged: (missed) {
                    setState(() => _missedPreviousFill = missed);
                    _bumpCostSummary();
                  },
                  title: const Text('Missed previous fill-up'),
                  subtitle: Text(
                    'Turn on if you refueled without logging it — '
                    'consumption restarts from this fill',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_fullTankUsesCapacity) ...[
              _FullTankBadge(
                liters: widget.vehicle.tankCapacityLiters!,
                colors: colors,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('fuel_full_tank_liters_field'),
                controller: _fullTankLitersCtrl,
                keyboardType: _fuelNumericKeyboard,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: _fuelNumericInputFormatters,
                decoration: const InputDecoration(
                  labelText: 'Liters pumped (optional)',
                  hintText: 'Leave empty to use tank capacity',
                  helperText:
                      'Enter the pump reading if the tank was not empty — '
                      'makes mileage exact',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                  suffixText: 'L',
                ),
                validator: (rawValue) {
                  if (rawValue == null || rawValue.trim().isEmpty) return null;
                  final liters =
                      double.tryParse(rawValue.trim().replaceAll(',', '.'));
                  if (liters == null || liters <= 0) {
                    return 'Enter a positive amount';
                  }
                  return null;
                },
              ),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quantity',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Liters'),
                    icon: Icon(Icons.water_drop_outlined, size: 18),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Total paid'),
                    icon: Icon(Icons.payments_outlined, size: 18),
                  ),
                ],
                selected: {_useTotalPaidForQuantity},
                onSelectionChanged: _onQuantityEntryModeChanged,
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 12),
              if (!_useTotalPaidForQuantity)
                TextFormField(
                  key: const ValueKey('fuel_liters_field'),
                  controller: _litersCtrl,
                  keyboardType: _fuelNumericKeyboard,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  spellCheckConfiguration:
                      const SpellCheckConfiguration.disabled(),
                  enableIMEPersonalizedLearning: false,
                  inputFormatters: _fuelNumericInputFormatters,
                  decoration: InputDecoration(
                    labelText: 'Liters *',
                    prefixIcon: const Icon(Icons.water_drop_outlined),
                    suffixText: 'L',
                    helperText: _isFullTank
                        ? 'No tank capacity saved for this vehicle'
                        : null,
                  ),
                  validator: (rawValue) {
                    if (rawValue == null || rawValue.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(
                          rawValue.trim().replaceAll(',', '.'),
                        ) ==
                        null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                )
              else ...[
                TextFormField(
                  key: const ValueKey('fuel_total_paid_field'),
                  controller: _totalPaidCtrl,
                  keyboardType: _fuelNumericKeyboard,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  spellCheckConfiguration:
                      const SpellCheckConfiguration.disabled(),
                  enableIMEPersonalizedLearning: false,
                  inputFormatters: _fuelNumericInputFormatters,
                  decoration: const InputDecoration(
                    labelText: 'Total paid *',
                    hintText: 'Receipt total',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  validator: (rawValue) {
                    if (rawValue == null || rawValue.isEmpty) {
                      return 'Required';
                    }
                    final totalPaid = double.tryParse(
                      rawValue.trim().replaceAll(',', '.'),
                    );
                    if (totalPaid == null || totalPaid <= 0) {
                      return 'Enter a positive amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                ListenableBuilder(
                  listenable: _costSummaryTick,
                  builder: (context, _) {
                    final derivedLiters = _effectiveLiters;
                    if (derivedLiters <= 0) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '≈ ${Formatters.formatLiters(derivedLiters)} refueled '
                      '(total ÷ cost per liter)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ],
            if (!_isFullTank && widget.vehicle.tankCapacityLiters != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('fuel_level_percent_field'),
                controller: _fuelLevelCtrl,
                keyboardType: _fuelNumericKeyboard,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: _fuelNumericInputFormatters,
                decoration: const InputDecoration(
                  labelText: 'Fuel level after fill (optional)',
                  hintText: 'Gauge reading, e.g. 75',
                  helperText: 'Lets mileage be estimated without a full tank',
                  prefixIcon: Icon(Icons.speed_outlined),
                  suffixText: '%',
                ),
                validator: (rawValue) {
                  if (rawValue == null || rawValue.trim().isEmpty) return null;
                  final level =
                      double.tryParse(rawValue.trim().replaceAll(',', '.'));
                  if (level == null || level < 0 || level > 100) {
                    return 'Enter 0–100';
                  }
                  return null;
                },
              ),
            ],
            ListenableBuilder(
              listenable: _costSummaryTick,
              builder: (context, _) {
                final capacity = widget.vehicle.tankCapacityLiters;
                final liters = _effectiveLiters;
                if (capacity == null || liters <= capacity) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'More than the ${Formatters.formatLiters(capacity)} tank '
                    'capacity — double-check the amount.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                );
              },
            ),
            ListenableBuilder(
              listenable: _consumptionPreviewListenable,
              builder: (context, _) => AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _buildConsumptionPreview(colors),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _costPerLiterCtrl,
              keyboardType: _fuelNumericKeyboard,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              enableIMEPersonalizedLearning: false,
              inputFormatters: _fuelNumericInputFormatters,
              decoration: InputDecoration(
                labelText: 'Cost per liter *',
                prefixIcon: const Icon(Icons.payments_outlined),
                helperText: _quantityFromTotalPaid
                    ? 'Used with total paid to calculate liters'
                    : null,
              ),
              validator: (rawValue) {
                if (rawValue == null || rawValue.isEmpty) {
                  return 'Required';
                }
                final costPerLiter = double.tryParse(
                  rawValue.trim().replaceAll(',', '.'),
                );
                if (costPerLiter == null) return 'Invalid number';
                if (_quantityFromTotalPaid && costPerLiter <= 0) {
                  return 'Must be greater than 0 to calculate liters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: _costSummaryTick,
              builder: (context, _) => _SummaryRow(totalCost: _totalCost),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional — station, fuel type…',
              ),
            ),
            const SizedBox(height: 16),
            _ReceiptSection(
              receiptPath: _pickedReceiptPath,
              onPick: _pickReceipt,
              onRemove: () => setState(() => _pickedReceiptPath = null),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_rounded, size: 22),
                label: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionPreview(AppColors colors) {
    if (!_showRefillOptions) return const SizedBox(width: double.infinity);
    final draft = _draftEntryForPreview;
    if (draft == null || draft.liters <= 0) {
      return const SizedBox(width: double.infinity);
    }

    final segment = _consumptionPreview;
    if (segment != null) {
      final opening = _fuelHistory
          .where((entry) => entry.id == segment.startEntryId)
          .firstOrNull;
      final partialFills = segment.fillCount - 1;
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: _FuelEfficiencyInsight(
          kmPerLiter: segment.kmPerLiter,
          colors: colors,
          title: segment.isEstimated
              ? 'Estimated consumption (fuel gauge)'
              : 'Consumption since last full tank',
          footnote: '${Formatters.formatDistance(segment.distanceKm)}'
              '${opening != null ? ' since ${DateFormat('dd MMM').format(opening.date)}' : ''}'
              ' ÷ ${Formatters.formatLiters(segment.liters)}'
              '${partialFills > 0 ? ' (incl. $partialFills partial ${partialFills == 1 ? 'fill' : 'fills'})' : ''}'
              ' · ${segment.litersPer100Km.toStringAsFixed(1)} L/100 km',
        ),
      );
    }

    final String note;
    if (_missedPreviousFill) {
      note = _isFullTank
          ? 'Consumption tracking restarts from this full tank.'
          : 'Consumption tracking restarts at your next full tank.';
    } else if (!_isFullTank) {
      note = 'Partial fill — ${Formatters.formatLiters(draft.liters)} will be '
          'included when you next fill up to full.';
    } else {
      note = 'This full tank starts tracking — consumption appears at your '
          'next full tank.';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: _ConsumptionNote(text: note, colors: colors),
    );
  }

  Future<void> _pickReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _pickReceiptFromSource(source);
  }

  Future<void> _pickReceiptFromSource(ImageSource source) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() => _pickedReceiptPath = xFile.path);
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = e.code == 'channel-error' ||
              e.message?.contains('channel') == true
          ? 'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}. Try again, or restart the app.'
          : (e.message ?? 'Failed to pick image');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final costPerLiter = double.parse(
      _costPerLiterCtrl.text.trim().replaceAll(',', '.'),
    );
    final liters = _effectiveLiters;
    if (_quantityFromTotalPaid) {
      if (liters <= 0 || !liters.isFinite) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter total paid and a valid cost per liter to calculate volume.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final double odometer;
      final double? distanceDriven;
      final double? tripDistance;

      if (_isFirstFuelLog) {
        odometer = double.parse(_odometerCtrl.text.trim());
        distanceDriven = null;
        tripDistance = null;
      } else if (_useTripMode) {
        final trip = double.parse(_tripKmCtrl.text.trim());
        odometer = widget.vehicle.currentOdometer + trip;
        distanceDriven = trip;
        tripDistance = trip;
      } else {
        odometer = double.parse(_odometerCtrl.text.trim());
        distanceDriven = odometer > widget.vehicle.currentOdometer
            ? odometer - widget.vehicle.currentOdometer
            : null;
        tripDistance = null;
      }

      final isFullTank = _isFullTank;
      final missedPreviousFill = !_isFirstFuelLog && _missedPreviousFill;

      final entryId = const Uuid().v4();
      String? receiptImagePath;
      if (_pickedReceiptPath != null) {
        receiptImagePath = await saveReceiptImage(entryId, _pickedReceiptPath!);
      }

      final totalCostForEntry = _quantityFromTotalPaid
          ? double.parse(
              _totalPaidCtrl.text.trim().replaceAll(',', '.'),
            )
          : liters * costPerLiter;

      final entry = FuelEntry(
        id: entryId,
        vehicleId: widget.vehicle.id,
        date: _date,
        odometer: odometer,
        liters: liters,
        costPerLiter: costPerLiter,
        totalCost: totalCostForEntry,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
        distanceDriven: distanceDriven,
        tripDistance: tripDistance,
        isFullTank: isFullTank,
        receiptImagePath: receiptImagePath,
        missedPreviousFill: missedPreviousFill,
        fuelLevelPercent: isFullTank ? null : _parsedFuelLevelPercent,
      );

      await sl<AddFuelEntry>()(entry);
      // Full-tank consumption spans several fills, so derive it from the whole chain.
      await sl<RecalculateFuelConsumption>()(widget.vehicle.id);

      // Update vehicle odometer so next trip is relative to this reading.
      await sl<UpdateVehicle>()(
        widget.vehicle.copyWith(currentOdometer: odometer),
      );

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _DistanceModeSelector extends StatelessWidget {
  const _DistanceModeSelector({
    required this.useTripMode,
    required this.onChanged,
    required this.colors,
  });

  final bool useTripMode;
  final ValueChanged<bool> onChanged;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<bool>(
            value: true,
            groupValue: useTripMode,
            onChanged: (_) => onChanged(true),
            title: const Text('Trip distance'),
            subtitle: const Text(
              'Km since last fill — added to your saved odometer',
            ),
            secondary: Icon(Icons.route_outlined, color: colors.fuelColor),
            controlAffinity: ListTileControlAffinity.trailing,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.dividerColor.withValues(alpha: 0.35),
          ),
          RadioListTile<bool>(
            value: false,
            groupValue: useTripMode,
            onChanged: (_) => onChanged(false),
            title: const Text('Full odometer'),
            subtitle: const Text('Enter the reading on your dashboard'),
            secondary: Icon(Icons.speed_outlined, color: colors.fuelColor),
            controlAffinity: ListTileControlAffinity.trailing,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

class _BaselineOdometerHint extends StatelessWidget {
  const _BaselineOdometerHint({
    required this.odometer,
    required this.colors,
  });

  final double odometer;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.fuelColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.fuelColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: colors.fuelColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Saved odometer ${Formatters.formatDistance(odometer)} — trip is added to this',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComputedOdometerTile extends StatelessWidget {
  const _ComputedOdometerTile({
    required this.value,
    required this.colors,
  });

  final double value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Odometer after save',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            Formatters.formatDistance(value),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelEfficiencyInsight extends StatelessWidget {
  const _FuelEfficiencyInsight({
    required this.kmPerLiter,
    required this.colors,
    required this.title,
    this.footnote,
  });

  final double kmPerLiter;
  final AppColors colors;
  final String title;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.fuelColor.withValues(alpha: 0.14),
            colors.fuelColor.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.fuelColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.fuelColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.eco_rounded, color: colors.fuelColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatFuelEfficiency(kmPerLiter),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.fuelColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  footnote ??
                      'Distance since your last full tank ÷ liters added since then.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern card showing tank capacity and last refill as quick reference.
class _FuelContextCard extends StatelessWidget {
  const _FuelContextCard({
    required this.colors,
    this.tankCapacityLiters,
    this.lastRefillLiters,
    this.baselineOdometer,
  });

  final double? tankCapacityLiters;
  final double? lastRefillLiters;
  final double? baselineOdometer;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTank = tankCapacityLiters != null;
    final hasLast = lastRefillLiters != null;
    final hasBaseline = baselineOdometer != null;
    if (!hasTank && !hasLast && !hasBaseline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.fuelColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.fuelColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.fuelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_gas_station_rounded,
                  size: 20,
                  color: colors.fuelColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Vehicle fuel',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasBaseline) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.fuelColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed_outlined, size: 20, color: colors.fuelColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saved odometer',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.extension<AppColors>()!.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    Formatters.formatDistance(baselineOdometer!),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.fuelColor,
                    ),
                  ),
                ],
              ),
            ),
            if (hasTank || hasLast) const SizedBox(height: 12),
          ],
          if (hasTank || hasLast)
            Row(
              children: [
                if (hasTank) ...[
                  Expanded(
                    child: _FuelStatCell(
                      icon: Icons.inventory_2_outlined,
                      value: Formatters.formatNumber(tankCapacityLiters!),
                      unit: 'L',
                      label: 'Tank capacity',
                      color: colors.fuelColor,
                      theme: theme,
                    ),
                  ),
                  if (hasLast) const SizedBox(width: 12),
                ],
                if (hasLast)
                  Expanded(
                    child: _FuelStatCell(
                      icon: Icons.water_drop_outlined,
                      value: Formatters.formatNumber(lastRefillLiters!),
                      unit: 'L',
                      label: 'Last refill',
                      color: colors.fuelColor,
                      theme: theme,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FuelStatCell extends StatelessWidget {
  const _FuelStatCell({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
    required this.theme,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.extension<AppColors>()!.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder while last fuel entry is loading.
class _FuelContextCardSkeleton extends StatelessWidget {
  const _FuelContextCardSkeleton({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.fuelColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.fuelColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: colors.fuelColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 140,
                  decoration: BoxDecoration(
                    color: colors.fuelColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

/// Muted explanation of how this fill affects consumption tracking.
class _ConsumptionNote extends StatelessWidget {
  const _ConsumptionNote({required this.text, required this.colors});

  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.fuelColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.fuelColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: colors.fuelColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the full-tank liters taken from the vehicle's tank capacity.
class _FullTankBadge extends StatelessWidget {
  const _FullTankBadge({
    required this.liters,
    required this.colors,
  });
  final double liters;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.fuelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.fuelColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 22,
            color: colors.fuelColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Full tank (from vehicle)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.formatNumber(liters)} L',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.fuelColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.totalCost});

  final double totalCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined),
          const SizedBox(width: 10),
          Text(
            'Total cost:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            Formatters.formatCurrency(totalCost),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  const _ReceiptSection({
    required this.receiptPath,
    required this.onPick,
    required this.onRemove,
  });

  final String? receiptPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Receipt (optional)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (receiptPath == null)
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: const Text('Add receipt image'),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(receiptPath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove receipt'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(DateFormat('dd MMM yyyy').format(date)),
      ),
    );
  }
}
