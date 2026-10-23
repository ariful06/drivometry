/// What a vehicle runs on, and the unit its fills are measured in.
///
/// Stored by [name]; unknown or missing values read as [petrol], which is how
/// every fill was recorded before energy types existed.
enum EnergyType {
  petrol('Petrol', 'L', 'liter'),
  diesel('Diesel', 'L', 'liter'),
  cng('CNG', 'kg', 'kg'),
  lpg('LPG', 'L', 'liter'),
  electric('Electric', 'kWh', 'kWh');

  const EnergyType(this.label, this.unit, this.unitName);

  final String label;

  /// Short unit shown next to amounts: `L`, `kg`, `kWh`.
  final String unit;

  /// Unit in sentences, e.g. "Price per liter".
  final String unitName;

  /// Measured in litres, so the global volume setting (L / gal) applies.
  bool get isLiquid => unit == 'L';

  static EnergyType fromName(Object? name) => EnergyType.values.firstWhere(
        (type) => type.name == name,
        orElse: () => EnergyType.petrol,
      );
}
