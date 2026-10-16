// lib/features/vehicles/presentation/pages/add_vehicle_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/vehicle_document_storage.dart';
import '../../../../injection_container.dart';
import '../../../vehicles/domain/usecases/vehicle_usecases.dart';
import '../../domain/entities/vehicle.dart';
import '../data/vehicle_form_options.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key, this.vehicle});

  /// When non-null, the page is in edit mode: form is prefilled and save updates this vehicle.
  final Vehicle? vehicle;

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _makeOtherCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _tankCapacityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedType = AppConstants.vehicleTypeCar;
  int? _selectedYear;
  String? _selectedMake;
  String? _selectedColor;
  bool _isRental = false;
  bool _isSaving = false;
  String? _registrationPath;
  String? _taxTokenPath;
  String? _fitnessPath;
  DateTime? _fitnessExpiry;
  late final ImagePicker _imagePicker;

  bool get _showFitness => _selectedType != AppConstants.vehicleTypeBike;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
    final v = widget.vehicle;
    if (v != null) {
      _nameCtrl.text = v.name;
      final makes = makesForVehicleType(v.type);
      if (makes.contains(v.make)) {
        _selectedMake = v.make;
      } else {
        _selectedMake = 'Other';
        _makeOtherCtrl.text = v.make;
      }
      _isRental = v.isRental;
      _modelCtrl.text = v.model;
      _selectedYear = v.year.clamp(kVehicleYearMin, kVehicleYearMax);
      _plateCtrl.text = v.licensePlate;
      _odometerCtrl.text = v.currentOdometer.toStringAsFixed(0);
      if (v.tankCapacityLiters != null) {
        _tankCapacityCtrl.text = v.tankCapacityLiters!.toStringAsFixed(0);
      }
      final col = v.color?.trim();
      _selectedColor = (col == null || col.isEmpty) ? null : col;
      _notesCtrl.text = v.notes ?? '';
      _selectedType = v.type;
      _registrationPath = v.registrationImagePath;
      _taxTokenPath = v.taxTokenImagePath;
      _fitnessPath = v.fitnessImagePath;
      _fitnessExpiry = v.fitnessExpiryDate;
    } else {
      final y = DateTime.now().year;
      _selectedYear = y.clamp(kVehicleYearMin, kVehicleYearMax);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _makeOtherCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _odometerCtrl.dispose();
    _tankCapacityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Colors shown in the dropdown, including any saved value not in the default list.
  List<String> _colorItems() {
    final list = List<String>.from(kVehicleColors);
    void addIfNeeded(String? c) {
      final t = c?.trim();
      if (t != null && t.isNotEmpty && !list.contains(t)) list.add(t);
    }

    addIfNeeded(widget.vehicle?.color);
    addIfNeeded(_selectedColor);
    return list;
  }

  String _resolveMake() {
    if (_selectedMake == 'Other') {
      return _makeOtherCtrl.text.trim();
    }
    return _selectedMake?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel(label: 'Vehicle Type'),
            const SizedBox(height: 8),
            _TypeSelector(
              selected: _selectedType,
              onChanged: (newType) {
                final savedMake = _resolveMake();
                setState(() {
                  _selectedType = newType;
                  if (newType == AppConstants.vehicleTypeBike) {
                    _fitnessPath = null;
                    _fitnessExpiry = null;
                  }
                  final list = makesForVehicleType(newType);
                  if (savedMake.isNotEmpty && list.contains(savedMake)) {
                    _selectedMake = savedMake;
                    if (savedMake != 'Other') {
                      _makeOtherCtrl.clear();
                    }
                  } else if (savedMake.isNotEmpty && list.contains('Other')) {
                    _selectedMake = 'Other';
                    _makeOtherCtrl.text = savedMake;
                  } else {
                    _selectedMake = null;
                    _makeOtherCtrl.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Usage'),
            const SizedBox(height: 8),
            _UsageToggle(
              isRental: _isRental,
              onChanged: (v) => setState(() => _isRental = v),
            ),
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Basic Info'),
            const SizedBox(height: 8),
            _Field(
              controller: _nameCtrl,
              label: 'Vehicle Nickname *',
              hint: 'e.g. My Honda',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMake,
                    decoration: const InputDecoration(
                      labelText: 'Make *',
                    ),
                    isExpanded: true,
                    items: makesForVehicleType(_selectedType)
                        .map(
                          (m) => DropdownMenuItem<String>(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedMake = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    controller: _modelCtrl,
                    label: 'Model *',
                    hint: 'e.g. Civic',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            if (_selectedMake == 'Other') ...[
              const SizedBox(height: 12),
              _Field(
                controller: _makeOtherCtrl,
                label: 'Make name *',
                hint: 'Enter manufacturer name',
                validator: (v) {
                  if (_selectedMake != 'Other') return null;
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year *',
                    ),
                    isExpanded: true,
                    items: [
                      for (var y = kVehicleYearMax; y >= kVehicleYearMin; y--)
                        DropdownMenuItem<int>(
                          value: y,
                          child: Text('$y'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _selectedYear = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedColor,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Not specified'),
                      ),
                      ..._colorItems().map(
                        (c) => DropdownMenuItem<String?>(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedColor = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _plateCtrl,
              label: 'License Plate *',
              hint: 'e.g. DHA-1234',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Odometer'),
            const SizedBox(height: 8),
            _Field(
              controller: _odometerCtrl,
              label: 'Current Odometer (km) *',
              hint: 'e.g. 15000',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _tankCapacityCtrl,
              label: 'Tank capacity (L)',
              hint: 'e.g. 45',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid capacity';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _notesCtrl,
              label: 'Notes',
              hint: 'Any additional notes...',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Vehicle Documents (optional)'),
            const SizedBox(height: 8),
            _DocumentSection(
              label: 'Registration',
              imagePath: _registrationPath,
              onPick: () => _pickDocument('registration',
                  (path) => setState(() => _registrationPath = path)),
              onRemove: () => setState(() => _registrationPath = null),
            ),
            const SizedBox(height: 12),
            _DocumentSection(
              label: 'Tax token',
              imagePath: _taxTokenPath,
              onPick: () => _pickDocument(
                  'tax_token', (path) => setState(() => _taxTokenPath = path)),
              onRemove: () => setState(() => _taxTokenPath = null),
            ),
            if (_showFitness) ...[
              const SizedBox(height: 12),
              _DocumentSection(
                label: 'Fitness certificate',
                imagePath: _fitnessPath,
                onPick: () => _pickDocument(
                    'fitness', (path) => setState(() => _fitnessPath = path)),
                onRemove: () => setState(() => _fitnessPath = null),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: const Text('Fitness expiry date'),
                  subtitle: Text(
                    _fitnessExpiry == null
                        ? 'Not set'
                        : Formatters.formatDate(_fitnessExpiry!),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_fitnessExpiry != null)
                        TextButton(
                          onPressed: () =>
                              setState(() => _fitnessExpiry = null),
                          child: const Text('Clear'),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        tooltip: 'Pick date',
                        onPressed: _pickFitnessExpiry,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Vehicle'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocument(
      String docType, void Function(String path) onPicked) async {
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
    await _pickDocumentFromSource(source, onPicked);
  }

  Future<void> _pickDocumentFromSource(
    ImageSource source,
    void Function(String path) onPicked,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (xFile != null && mounted) onPicked(xFile.path);
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

  Future<void> _pickFitnessExpiry() async {
    final now = DateTime.now();
    final initial =
        _fitnessExpiry ?? DateTime(now.year + 1, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _fitnessExpiry = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final tankStr = _tankCapacityCtrl.text.trim();
      final tankCapacity = tankStr.isEmpty ? null : double.tryParse(tankStr);
      final existing = widget.vehicle;
      final isEdit = existing != null;
      final vehicleId = existing?.id ?? const Uuid().v4();
      final createdAt = existing?.createdAt ?? DateTime.now();

      String? registrationImagePath = existing?.registrationImagePath;
      String? taxTokenImagePath = existing?.taxTokenImagePath;
      String? fitnessImagePath = existing?.fitnessImagePath;
      DateTime? fitnessExpiryDate = existing?.fitnessExpiryDate;

      if (_registrationPath != null &&
          _registrationPath != existing?.registrationImagePath) {
        registrationImagePath = await saveVehicleDocument(
          vehicleId,
          'registration',
          _registrationPath!,
        );
      } else if (isEdit && _registrationPath == null) {
        registrationImagePath = null;
      }
      if (_taxTokenPath != null &&
          _taxTokenPath != existing?.taxTokenImagePath) {
        taxTokenImagePath = await saveVehicleDocument(
          vehicleId,
          'tax_token',
          _taxTokenPath!,
        );
      } else if (isEdit && _taxTokenPath == null) {
        taxTokenImagePath = null;
      }

      if (!_showFitness) {
        fitnessImagePath = null;
        fitnessExpiryDate = null;
      } else {
        if (_fitnessPath != null &&
            _fitnessPath != existing?.fitnessImagePath) {
          fitnessImagePath = await saveVehicleDocument(
            vehicleId,
            'fitness',
            _fitnessPath!,
          );
        } else if (isEdit && _fitnessPath == null) {
          fitnessImagePath = null;
        }
        fitnessExpiryDate = _fitnessExpiry;
      }

      final odometer = double.parse(_odometerCtrl.text.trim());
      final vehicle = Vehicle(
        id: vehicleId,
        name: _nameCtrl.text.trim(),
        type: _selectedType,
        make: _resolveMake(),
        model: _modelCtrl.text.trim(),
        year: _selectedYear!,
        licensePlate: _plateCtrl.text.trim(),
        initialOdometer: existing?.initialOdometer ?? odometer,
        currentOdometer: odometer,
        createdAt: createdAt,
        color: _selectedColor == null || _selectedColor!.trim().isEmpty
            ? null
            : _selectedColor!.trim(),
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
        tankCapacityLiters: tankCapacity,
        registrationImagePath: registrationImagePath,
        taxTokenImagePath: taxTokenImagePath,
        fitnessImagePath: fitnessImagePath,
        fitnessExpiryDate: fitnessExpiryDate,
        isRental: _isRental,
      );

      if (isEdit) {
        await sl<UpdateVehicle>()(vehicle);
        if (mounted) context.pop(vehicle);
      } else {
        await sl<AddVehicle>()(vehicle);
        if (mounted) context.pop();
      }
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

class _UsageToggle extends StatelessWidget {
  const _UsageToggle({
    required this.isRental,
    required this.onChanged,
  });

  final bool isRental;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment<bool>(
            value: false,
            label: Text('Personal'),
            icon: Icon(Icons.person_outline_rounded, size: 18),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text('Rental'),
            icon: Icon(Icons.local_taxi_rounded, size: 18),
          ),
        ],
        selected: {isRental},
        onSelectionChanged: (Set<bool> next) {
          if (next.isNotEmpty) onChanged(next.first);
        },
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final types = [
      AppConstants.vehicleTypeCar,
      AppConstants.vehicleTypeBike,
      AppConstants.vehicleTypeOther,
    ];
    return Row(
      children: types
          .map(
            (t) => Expanded(
              child: GestureDetector(
                onTap: () => onChanged(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected == t
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        t == AppConstants.vehicleTypeBike
                            ? Icons.two_wheeler
                            : t == AppConstants.vehicleTypeCar
                                ? Icons.directions_car
                                : Icons.commute,
                        color: selected == t
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected == t
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({
    required this.label,
    required this.imagePath,
    required this.onPick,
    required this.onRemove,
  });

  final String label;
  final String? imagePath;
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
                Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (imagePath == null)
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: Text('Add $label image'),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imagePath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text('Remove $label'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
