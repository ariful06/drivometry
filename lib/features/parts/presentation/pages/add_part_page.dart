import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/maintenance_parts.dart';
import '../../../../core/utils/formatters.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/part_replacement.dart';

/// Arguments for [AddPartPage]. When [replacing] is set the form is prefilled
/// from that part and saving replaces it.
class AddPartArgs {
  const AddPartArgs({required this.vehicle, this.replacing});
  final Vehicle vehicle;
  final PartReplacement? replacing;
}

/// Pops with the new [PartReplacement]; the caller persists it.
class AddPartPage extends StatefulWidget {
  const AddPartPage({required this.args, super.key});
  final AddPartArgs args;

  @override
  State<AddPartPage> createState() => _AddPartPageState();
}

class _AddPartPageState extends State<AddPartPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _odometer;
  final _cost = TextEditingController();
  late final TextEditingController _lifespanKm;
  late final TextEditingController _lifespanMonths;
  final _warranty = TextEditingController();
  final _notes = TextEditingController();
  String? _category;
  DateTime _installed = DateTime.now();

  Vehicle get _vehicle => widget.args.vehicle;
  PartReplacement? get _replacing => widget.args.replacing;

  PartsByCategory get _catalog =>
      _vehicle.type == 'bike' ? MotorcycleParts : CarParts;

  @override
  void initState() {
    super.initState();
    final old = _replacing;
    _name = TextEditingController(text: old?.partName ?? '');
    _odometer = TextEditingController(
        text: _vehicle.currentOdometer.toStringAsFixed(0));
    _lifespanKm = TextEditingController(
        text: old?.expectedLifespanKm?.toStringAsFixed(0) ?? '');
    _lifespanMonths =
        TextEditingController(text: old?.lifespanMonths?.toString() ?? '');
    _category = old?.category;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _odometer,
      _cost,
      _lifespanKm,
      _lifespanMonths,
      _warranty,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Iterable<String> get _suggestions => _category == null
      ? _catalog.values.expand((names) => names)
      : _catalog[_category] ?? const [];

  String? _optionalNumber(String? value, {bool integer = false}) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed =
        integer ? int.tryParse(value.trim()) : double.tryParse(value.trim());
    return parsed == null || parsed < 0 ? 'Enter a valid number' : null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _installed,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _installed = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    context.pop(PartReplacement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      vehicleId: _vehicle.id,
      partName: _name.text.trim(),
      category: _category,
      installOdometer: double.parse(_odometer.text.trim()),
      expectedLifespanKm: double.tryParse(_lifespanKm.text.trim()),
      lifespanMonths: int.tryParse(_lifespanMonths.text.trim()),
      installedAt: _installed,
      cost: double.tryParse(_cost.text.trim()),
      warrantyMonths: int.tryParse(_warranty.text.trim()),
      notes: text(_notes),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final replacing = _replacing != null;
    return Scaffold(
      appBar: AppBar(title: Text(replacing ? 'Replace part' : 'Add part')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (replacing)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'The old ${_replacing!.partName} is kept in history and '
                  'linked to this new part.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            DropdownButtonFormField<String?>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                for (final c in _catalog.keys)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _name.text),
              optionsBuilder: (value) => _suggestions.where((name) =>
                  name.toLowerCase().contains(value.text.toLowerCase())),
              onSelected: (value) => _name.text = value,
              fieldViewBuilder: (context, controller, focusNode, _) {
                controller.addListener(() => _name.text = controller.text);
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Part name *'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter the part name'
                      : null,
                );
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Installed on'),
              subtitle: Text(Formatters.formatDate(_installed)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _odometer,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Odometer at install (km) *'),
              validator: (value) {
                final odo = double.tryParse(value?.trim() ?? '');
                return odo == null || odo < 0 ? 'Enter the odometer' : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cost,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cost (optional)'),
              validator: _optionalNumber,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lifespanKm,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Lifespan (km)'),
                    validator: _optionalNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lifespanMonths,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Lifespan (months)'),
                    validator: (v) => _optionalNumber(v, integer: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Set km, months or both; the part is due at whichever comes first.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _warranty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Warranty (months)'),
              validator: (v) => _optionalNumber(v, integer: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(replacing ? 'Replace part' : 'Save part'),
            ),
          ],
        ),
      ),
    );
  }
}
