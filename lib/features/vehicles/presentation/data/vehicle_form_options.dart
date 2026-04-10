import '../../../../core/constants/app_constants.dart';

/// Dropdown options for add/edit vehicle form.

/// Model years available in the form (inclusive).
const int kVehicleYearMin = 1990;
const int kVehicleYearMax = 2030;

/// Passenger car / light commercial manufacturers (alphabetical, plus Other).
const List<String> kCarMakes = [
  'Acura',
  'Audi',
  'BMW',
  'BYD',
  'Chevrolet',
  'Daihatsu',
  'Fiat',
  'Ford',
  'Genesis',
  'GMC',
  'Honda',
  'Hyundai',
  'Infiniti',
  'Isuzu',
  'Jaguar',
  'Jeep',
  'Kia',
  'Land Rover',
  'Lexus',
  'Mahindra',
  'Mazda',
  'Mercedes-Benz',
  'MG',
  'Mini',
  'Mitsubishi',
  'Nissan',
  'Peugeot',
  'Porsche',
  'Ram',
  'Renault',
  'Subaru',
  'Suzuki',
  'Tata',
  'Tesla',
  'Toyota',
  'Volkswagen',
  'Volvo',
  'Other',
];

/// Motorcycle / scooter manufacturers (alphabetical, plus Other).
const List<String> kBikeMakes = [
  'Aprilia',
  'Bajaj',
  'Benelli',
  'Beta',
  'BMW Motorrad',
  'CFMoto',
  'Ducati',
  'Gas Gas',
  'Harley-Davidson',
  'Hero',
  'Honda',
  'Husqvarna',
  'Indian',
  'Kawasaki',
  'Keeway',
  'KTM',
  'Kymco',
  'Lifan',
  'Mahindra',
  'Moto Guzzi',
  'Norton',
  'Piaggio',
  'Royal Enfield',
  'Sherco',
  'Suzuki',
  'SYM',
  'TVS',
  'Triumph',
  'UM',
  'Vespa',
  'Yamaha',
  'Zongshen',
  'Other',
];

/// Merged car + bike maker names for the "Other" vehicle type (no duplicates, sorted).
List<String> get kOtherVehicleMakes {
  final set = <String>{};
  for (final m in kCarMakes) {
    if (m != 'Other') set.add(m);
  }
  for (final m in kBikeMakes) {
    if (m != 'Other') set.add(m);
  }
  final list = set.toList()..sort();
  list.add('Other');
  return list;
}

/// Make dropdown list for the selected vehicle type (Car / Bike / Other).
List<String> makesForVehicleType(String type) {
  switch (type) {
    case AppConstants.vehicleTypeBike:
      return kBikeMakes;
    case AppConstants.vehicleTypeOther:
      return kOtherVehicleMakes;
    default:
      return kCarMakes;
  }
}

/// Typical exterior colors for cars, bikes, and general vehicles.
const List<String> kVehicleColors = [
  'White',
  'Pearl White',
  'Black',
  'Silver',
  'Metallic Silver',
  'Gray',
  'Grey',
  'Gunmetal',
  'Blue',
  'Navy Blue',
  'Red',
  'Maroon',
  'Green',
  'Yellow',
  'Orange',
  'Brown',
  'Beige',
  'Gold',
  'Bronze',
  'Champagne',
  'Purple',
  'Pink',
  'Turquoise',
  'Matte Black',
  'Two-tone',
];
