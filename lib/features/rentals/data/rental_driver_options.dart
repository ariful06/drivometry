class RentalDriverOption {
  const RentalDriverOption({
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;
}

/// Simple built-in driver directory used by the rental create/edit form
/// to auto-fill driver phone in a read-only field.
///
/// If you want, we can later move this to a proper persisted driver
/// directory (so users can manage the list).
const List<RentalDriverOption> rentalDriverDirectory = [
  RentalDriverOption(name: 'Rahim', phone: '01700000001'),
  RentalDriverOption(name: 'Karim', phone: '01700000002'),
  RentalDriverOption(name: 'Jamal', phone: '01700000003'),
  RentalDriverOption(name: 'Salman', phone: '01700000004'),
  RentalDriverOption(name: 'Hasan', phone: '01700000005'),
  RentalDriverOption(name: 'Rafi', phone: '01700000006'),
  RentalDriverOption(name: 'Imran', phone: '01700000007'),
  RentalDriverOption(name: 'Arif', phone: '01700000008'),
  RentalDriverOption(name: 'Sami', phone: '01700000009'),
  RentalDriverOption(name: 'Custom', phone: ''),
];

String driverPhoneForName(String driverName) {
  final t = driverName.trim();
  for (final d in rentalDriverDirectory) {
    if (d.name == t) return d.phone;
  }
  return '';
}
