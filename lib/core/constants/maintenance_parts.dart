// lib/core/constants/maintenance_parts.dart
// Reusable datasets of common maintenance items by category for cars and motorcycles.

/// Category name → list of part/item names.
typedef PartsByCategory = Map<String, List<String>>;

/// Parts that are replaceable/consumable only (e.g. engine oil, filters). They cannot be
/// "repaired" — show only in "Parts change" tab, hide in "Repair" tab.
const Set<String> ChangeOnlyPartNames = {
  'Engine oil',
  'Oil filter',
  'Air filter',
  'Fuel filter',
  'Spark plugs',
  'Spark plug',
  'Coolant',
  'Brake fluid',
  'Transmission oil',
  'Power steering fluid',
  'Wiper blades',
  'Cabin filter',
  'AC refrigerant',
  'Tire',
  'Fuse',
  'Clutch cable',
};

/// Returns a copy of [parts] with change-only parts removed (for Repair tab).
PartsByCategory filterPartsForRepair(PartsByCategory parts) {
  final result = <String, List<String>>{};
  for (final entry in parts.entries) {
    final filtered = entry.value
        .where((name) => !ChangeOnlyPartNames.contains(name))
        .toList();
    if (filtered.isNotEmpty) {
      result[entry.key] = filtered;
    }
  }
  return result;
}

/// Common car maintenance items grouped by category.
const PartsByCategory CarParts = {
  'Engine': [
    'Engine oil',
    'Oil filter',
    'Air filter',
    'Fuel filter',
    'Spark plugs',
    'Ignition coils',
    'Timing belt',
    'Timing chain',
    'Serpentine belt',
    'Cylinder head',
    'Head gasket',
    'Piston',
    'Piston rings',
    'Crankshaft',
    'Camshaft',
    'Engine mount',
    'Valve cover gasket',
    'Intake manifold',
    'Exhaust manifold',
    'Throttle body',
  ],
  'Cooling System': [
    'Radiator',
    'Radiator fan',
    'Coolant',
    'Thermostat',
    'Water pump',
    'Radiator cap',
    'Coolant reservoir',
    'Radiator hose',
    'Heater core',
  ],
  'Fuel System': [
    'Fuel pump',
    'Fuel injector',
    'Fuel tank',
    'Fuel pressure regulator',
    'Fuel rail',
    'Throttle cable',
  ],
  'Transmission': [
    'Transmission oil',
    'Clutch plate',
    'Clutch pressure plate',
    'Flywheel',
    'Gearbox',
    'Torque converter',
    'Transmission mount',
    'Drive shaft',
    'CV joint',
    'Differential',
  ],
  'Brake System': [
    'Brake pads',
    'Brake shoes',
    'Brake disc',
    'Brake drum',
    'Brake caliper',
    'Brake master cylinder',
    'Brake booster',
    'Brake fluid',
    'ABS sensor',
    'ABS module',
    'Brake lines',
  ],
  'Suspension': [
    'Shock absorber',
    'Strut',
    'Coil spring',
    'Leaf spring',
    'Control arm',
    'Ball joint',
    'Stabilizer bar',
    'Stabilizer link',
    'Bushing',
  ],
  'Steering System': [
    'Steering rack',
    'Tie rod',
    'Tie rod end',
    'Steering column',
    'Power steering pump',
    'Power steering fluid',
    'Steering knuckle',
  ],
  'Electrical': [
    'Battery',
    'Alternator',
    'Starter motor',
    'Fuse',
    'Relay',
    'Wiring harness',
    'ECU',
    'Sensors',
    'Ignition switch',
  ],
  'Body & Exterior': [
    'Headlight',
    'Tail light',
    'Fog light',
    'Side mirror',
    'Windshield',
    'Door handle',
    'Door lock',
    'Wiper blades',
    'Wiper motor',
    'Bumper',
    'Grille',
  ],
  'Interior': [
    'Dashboard',
    'Instrument cluster',
    'Seat',
    'Seat belt',
    'AC vents',
    'Glove box',
    'Center console',
    'Interior lights',
  ],
  'AC System': [
    'AC compressor',
    'AC condenser',
    'AC evaporator',
    'AC blower motor',
    'Cabin filter',
    'Expansion valve',
    'AC refrigerant',
  ],
  'Wheels & Tires': [
    'Tire',
    'Wheel rim',
    'Wheel hub',
    'Wheel bearing',
    'Lug nuts',
  ],
};

/// Common motorcycle maintenance items grouped by category.
const PartsByCategory MotorcycleParts = {
  'Engine': [
    'Engine oil',
    'Oil filter',
    'Air filter',
    'Spark plug',
    'Cylinder',
    'Cylinder head',
    'Piston',
    'Piston rings',
    'Crankshaft',
    'Camshaft',
    'Valve',
    'Timing chain',
  ],
  'Fuel System': [
    'Fuel tank',
    'Fuel pump',
    'Fuel injector',
    'Carburetor',
    'Fuel filter',
    'Throttle body',
  ],
  'Transmission': [
    'Gearbox',
    'Clutch plate',
    'Clutch cable',
    'Gear shifter',
  ],
  'Drive System': [
    'Chain',
    'Front sprocket',
    'Rear sprocket',
    'Chain tensioner',
  ],
  'Brake System': [
    'Brake pads',
    'Brake disc',
    'Brake caliper',
    'Brake master cylinder',
    'Brake fluid',
    'Brake hose',
  ],
  'Suspension': [
    'Front fork',
    'Rear shock absorber',
    'Swing arm',
    'Fork seal',
  ],
  'Electrical': [
    'Battery',
    'Starter motor',
    'Alternator',
    'Ignition coil',
    'CDI unit',
    'Rectifier',
    'Fuse',
    'Wiring',
  ],
  'Controls': [
    'Handlebar',
    'Throttle cable',
    'Clutch lever',
    'Brake lever',
    'Switch assembly',
  ],
  'Lighting': [
    'Headlight',
    'Tail light',
    'Indicator light',
    'Brake light',
  ],
  'Wheels': [
    'Tire',
    'Wheel rim',
    'Wheel hub',
    'Spokes',
    'Wheel bearing',
  ],
  'Body': [
    'Fuel tank cover',
    'Side panel',
    'Front fender',
    'Rear fender',
    'Seat',
    'Exhaust pipe',
  ],
};
