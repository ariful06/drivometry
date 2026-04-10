import 'dart:io';

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
import '../../domain/usecases/fuel_usecases.dart';

class AddFuelEntryPage extends StatefulWidget {
  const AddFuelEntryPage({required this.vehicle, super.key});

  final Vehicle vehicle;

  @override
  State<AddFuelEntryPage> createState() => _AddFuelEntryPageState();
}

class _AddFuelEntryPageState extends State<AddFuelEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _tripKmCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _litersCtrl = TextEditingController();
  final _costPerLiterCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  /// Last fuel entry for this vehicle (loaded on init); used to show last refill amount and previous mileage.
  FuelEntry? _lastFuelEntry;
  bool _lastEntryLoading = true;

  /// After the first log: `true` = trip km since last fill; `false` = dashboard odometer.
  bool _useTripMode = true;

  bool _isFullTank = false;

  /// Optional receipt image picked by user; saved to app storage on submit.
  String? _pickedReceiptPath;

  /// Trip / odometer / history only — last-refill mileage does not use current liters or full tank.
  final ValueNotifier<int> _mileagePreviewTick = ValueNotifier(0);

  /// Liters, price, full tank — total cost row.
  final ValueNotifier<int> _costSummaryTick = ValueNotifier(0);

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

  double get _totalCost {
    final liters = _effectiveLiters;
    final t = _costPerLiterCtrl.text.trim().replaceAll(',', '.');
    final costPerLiter = double.tryParse(t) ?? 0;
    return liters * costPerLiter;
  }

  /// Liters to use: when full tank and vehicle has tank capacity, use it; else from input.
  double get _effectiveLiters {
    if (_isFullTank && widget.vehicle.tankCapacityLiters != null) {
      return widget.vehicle.tankCapacityLiters!;
    }
    final t = _litersCtrl.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return 0;
    return double.tryParse(t) ?? 0;
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

  /// km/L for the **last** refill only: distance since that fill divided by liters logged on that fill.
  /// Current refill volume (liters / full tank) does not affect this number.
  double? get _lastRefillMileagePreviewKmPerLiter {
    final d = _distanceKmForPreview;
    if (d == null) return null;
    final lastL = _lastFuelEntry?.liters;
    if (lastL == null || lastL <= 0) return null;
    return d / lastL;
  }

  String? get _mileagePreviewFootnote {
    if (_lastRefillMileagePreviewKmPerLiter == null) return null;
    final lastL = _lastFuelEntry?.liters;
    if (lastL == null || lastL <= 0) return null;
    return 'Uses your last refill (${Formatters.formatLiters(lastL)}).';
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
    _costPerLiterCtrl.addListener(_bumpCostSummary);
    _loadLastFuelEntry();
  }

  Future<void> _loadLastFuelEntry() async {
    try {
      final entry = await sl<GetLastFuelEntry>()(widget.vehicle.id);
      if (mounted) {
        setState(() {
          _lastFuelEntry = entry;
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
    _costPerLiterCtrl.removeListener(_bumpCostSummary);
    _mileagePreviewTick.dispose();
    _costSummaryTick.dispose();
    _tripKmCtrl.dispose();
    _odometerCtrl.dispose();
    _litersCtrl.dispose();
    _costPerLiterCtrl.dispose();
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
                baselineOdometer: _isFirstFuelLog
                    ? null
                    : widget.vehicle.currentOdometer,
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Km since last refill *',
                  hintText: 'e.g. 420',
                  prefixIcon: Icon(Icons.route_outlined),
                  suffixText: 'km',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter distance since last fill';
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
                        if (_lastRefillMileagePreviewKmPerLiter != null) ...[
                          const SizedBox(height: 14),
                          _FuelEfficiencyInsight(
                            kmPerLiter: _lastRefillMileagePreviewKmPerLiter!,
                            colors: colors,
                            footnote: _mileagePreviewFootnote,
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
              ListenableBuilder(
                listenable: _mileagePreviewTick,
                builder: (context, _) {
                  if (_lastRefillMileagePreviewKmPerLiter == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _FuelEfficiencyInsight(
                      kmPerLiter: _lastRefillMileagePreviewKmPerLiter!,
                      colors: colors,
                      footnote: _mileagePreviewFootnote,
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            Material(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              child: SwitchListTile.adaptive(
                value: _isFullTank,
                onChanged: (v) {
                  setState(() => _isFullTank = v);
                  _bumpCostSummary();
                },
                title: const Text('Full tank fill'),
                subtitle: Text(
                  widget.vehicle.tankCapacityLiters != null
                      ? 'Uses ${Formatters.formatNumber(widget.vehicle.tankCapacityLiters!)} L × price per liter'
                      : 'Add tank capacity in vehicle settings to use this',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_isFullTank)
              TextFormField(
                key: const ValueKey('fuel_liters_field'),
                controller: _litersCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Liters *',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                  suffixText: 'L',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
            if (!_isFullTank) const SizedBox(height: 12),
            if (_isFullTank && widget.vehicle.tankCapacityLiters != null) ...[
              _FullTankBadge(
                liters: widget.vehicle.tankCapacityLiters!,
                colors: colors,
              ),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _costPerLiterCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cost per liter *',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
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
    if (_isFullTank && widget.vehicle.tankCapacityLiters == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Set tank capacity in vehicle details to use full tank fill')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final liters = _effectiveLiters;
      final costPerLiter = double.parse(
        _costPerLiterCtrl.text.trim().replaceAll(',', '.'),
      );

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

      final efficiency = (distanceDriven != null && liters > 0)
          ? distanceDriven / liters
          : null;
      final isFullTank = _isFullTank;
      final calculatedMileage = efficiency;

      final entryId = const Uuid().v4();
      String? receiptImagePath;
      if (_pickedReceiptPath != null) {
        receiptImagePath = await saveReceiptImage(entryId, _pickedReceiptPath!);
      }

      final entry = FuelEntry(
        id: entryId,
        vehicleId: widget.vehicle.id,
        date: _date,
        odometer: odometer,
        liters: liters,
        costPerLiter: costPerLiter,
        totalCost: liters * costPerLiter,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
        fuelEfficiency: efficiency,
        distanceDriven: distanceDriven,
        tripDistance: tripDistance,
        isFullTank: isFullTank,
        calculatedMileage: calculatedMileage,
        receiptImagePath: receiptImagePath,
      );

      await sl<AddFuelEntry>()(entry);

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
    this.footnote,
  });

  final double kmPerLiter;
  final AppColors colors;
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
                  'Last refill period',
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
                      'Km per liter for the distance since your last refill, using the liters from that fill.',
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
          color: colors.fuelColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.fuelColor.withOpacity(0.06),
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
                  color: colors.fuelColor.withOpacity(0.12),
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
        color: color.withOpacity(0.08),
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
                  color: color.withOpacity(0.9),
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
          color: colors.fuelColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.fuelColor.withOpacity(0.1),
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
                    color: colors.fuelColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 140,
                  decoration: BoxDecoration(
                    color: colors.fuelColor.withOpacity(0.1),
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

/// Modern badge for "full tank" liters when that option is selected.
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
        color: colors.fuelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.fuelColor.withOpacity(0.25),
          width: 1,
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
                  'Full tank',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.extension<AppColors>()!.textSecondary,
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
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
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
