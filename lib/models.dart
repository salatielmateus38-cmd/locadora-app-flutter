enum Role { admin, customer }

/// Dias de calendário entre duas datas (ignora horário de verão).
int daysBetween(DateTime start, DateTime end) =>
    DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

enum VehicleCategory {
  economy('Econômico', 'assets/images/fiat-mobi.webp'),
  hatch('Hatch', 'assets/images/volkswagen-polo.webp'),
  sedan('Sedan', 'assets/images/toyota-corolla.webp'),
  suv('SUV', 'assets/images/jeep-compass.webp'),
  pickup('Picape', 'assets/images/fiat-toro.webp');

  const VehicleCategory(this.label, this.photo);
  final String label;
  final String photo;
}

enum VehicleStatus {
  available('Disponível'),
  rented('Locado'),
  maintenance('Manutenção');

  const VehicleStatus(this.label);
  final String label;
}

enum RentalStatus {
  active('Em andamento'),
  returned('Devolvido');

  const RentalStatus(this.label);
  final String label;
}

class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = Role.customer,
  });

  final int id;
  final String name;
  final String email;
  final String password;
  final Role role;

  bool get isAdmin => role == Role.admin;
}

class Vehicle {
  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    required this.category,
    required this.dailyRate,
    this.status = VehicleStatus.available,
  });

  final int id;
  String brand;
  String model;
  int year;
  String plate;
  String color;
  VehicleCategory category;
  double dailyRate;
  VehicleStatus status;

  String get name => '$brand $model';

  static const _photos = {
    'fiat mobi': 'assets/images/fiat-mobi.webp',
    'fiat toro': 'assets/images/fiat-toro.webp',
    'hyundai creta': 'assets/images/hyundai-creta.webp',
    'jeep compass': 'assets/images/jeep-compass.webp',
    'toyota corolla': 'assets/images/toyota-corolla.webp',
    'volkswagen polo': 'assets/images/volkswagen-polo.webp',
  };

  /// Foto do modelo, ou a foto da categoria quando não há uma específica.
  String get photo => _photos[name.trim().toLowerCase()] ?? category.photo;
}

class Rental {
  Rental({
    required this.id,
    required this.user,
    required this.vehicle,
    required this.startDate,
    required this.expectedReturnDate,
    required this.dailyRate,
    required this.estimatedAmount,
    required this.createdAt,
    this.returnedAt,
    this.totalAmount,
    this.status = RentalStatus.active,
  });

  final int id;
  final User user;
  final Vehicle vehicle;
  final DateTime startDate;
  final DateTime expectedReturnDate;
  final double dailyRate;
  final double estimatedAmount;
  final DateTime createdAt;
  DateTime? returnedAt;
  double? totalAmount;
  RentalStatus status;

  int get expectedDays => daysBetween(startDate, expectedReturnDate);

  bool isLate(DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    return status == RentalStatus.active && expectedReturnDate.isBefore(day);
  }
}
