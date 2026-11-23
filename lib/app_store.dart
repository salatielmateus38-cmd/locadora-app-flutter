import 'package:flutter/widgets.dart';

import 'models.dart';

/// Erro de regra de negócio, exibido diretamente para o usuário.
class AppException implements Exception {
  AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// "Banco de dados" em memória com as mesmas regras de negócio da API web.
/// Os dados são recriados (seed) a cada vez que o app é aberto.
class AppStore extends ChangeNotifier {
  AppStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _seed();
  }

  final DateTime Function() _clock;
  final List<User> _users = [];
  final List<Vehicle> _vehicles = [];
  final List<Rental> _rentals = [];
  int _nextUserId = 1;
  int _nextVehicleId = 1;
  int _nextRentalId = 1;

  User? currentUser;

  static final plateRegex = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  DateTime get now => _clock();
  DateTime get today {
    final n = now;
    return DateTime(n.year, n.month, n.day);
  }

  bool get isAdmin => currentUser?.isAdmin ?? false;

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);

  /// Clientes veem apenas as próprias locações; administradores veem todas.
  List<Rental> get rentals {
    final user = currentUser;
    if (user == null) return const [];
    final list = user.isAdmin ? _rentals : _rentals.where((r) => r.user.id == user.id);
    return list.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Vehicle vehicleById(int id) => _vehicles.firstWhere(
        (v) => v.id == id,
        orElse: () => throw AppException('Veículo não encontrado'),
      );

  // ---------------------------------------------------------------- Auth

  void login(String email, String password) {
    final normalized = email.trim().toLowerCase();
    final user = _users.where((u) => u.email == normalized).firstOrNull;
    if (user == null || user.password != password) {
      throw AppException('E-mail ou senha inválidos');
    }
    currentUser = user;
    notifyListeners();
  }

  void register(String name, String email, String password) {
    final normalized = email.trim().toLowerCase();
    if (name.trim().length < 3) throw AppException('Informe seu nome completo');
    if (!_emailRegex.hasMatch(normalized)) throw AppException('E-mail inválido');
    if (password.length < 6) throw AppException('A senha deve ter no mínimo 6 caracteres');
    if (_users.any((u) => u.email == normalized)) {
      throw AppException('Este e-mail já está cadastrado');
    }
    final user = User(id: _nextUserId++, name: name.trim(), email: normalized, password: password);
    _users.add(user);
    currentUser = user;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ Veículos

  static String normalizePlate(String plate) =>
      plate.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  void _validateVehicle({
    required String brand,
    required String model,
    required int year,
    required String plate,
    required String color,
    required double dailyRate,
    int? ignoreId,
  }) {
    if (brand.trim().length < 2) throw AppException('Marca é obrigatória');
    if (model.trim().isEmpty) throw AppException('Modelo é obrigatório');
    if (year < 1990 || year > now.year + 1) throw AppException('Ano inválido');
    if (!plateRegex.hasMatch(plate)) {
      throw AppException('Placa inválida (ex.: ABC1D23 ou ABC1234)');
    }
    if (color.trim().length < 2) throw AppException('Cor é obrigatória');
    if (dailyRate <= 0) throw AppException('A diária deve ser maior que zero');
    if (_vehicles.any((v) => v.plate == plate && v.id != ignoreId)) {
      throw AppException('Já existe um veículo com esta placa');
    }
  }

  Vehicle addVehicle({
    required String brand,
    required String model,
    required int year,
    required String plate,
    required String color,
    required VehicleCategory category,
    required double dailyRate,
    VehicleStatus status = VehicleStatus.available,
  }) {
    _requireAdmin();
    final normalizedPlate = normalizePlate(plate);
    _validateVehicle(
      brand: brand,
      model: model,
      year: year,
      plate: normalizedPlate,
      color: color,
      dailyRate: dailyRate,
    );
    if (status == VehicleStatus.rented) {
      throw AppException('Um veículo novo não pode ser cadastrado como locado');
    }
    final vehicle = Vehicle(
      id: _nextVehicleId++,
      brand: brand.trim(),
      model: model.trim(),
      year: year,
      plate: normalizedPlate,
      color: color.trim(),
      category: category,
      dailyRate: dailyRate,
      status: status,
    );
    _vehicles.add(vehicle);
    notifyListeners();
    return vehicle;
  }

  void updateVehicle(
    int id, {
    required String brand,
    required String model,
    required int year,
    required String plate,
    required String color,
    required VehicleCategory category,
    required double dailyRate,
    required VehicleStatus status,
  }) {
    _requireAdmin();
    final vehicle = vehicleById(id);
    final normalizedPlate = normalizePlate(plate);
    _validateVehicle(
      brand: brand,
      model: model,
      year: year,
      plate: normalizedPlate,
      color: color,
      dailyRate: dailyRate,
      ignoreId: id,
    );
    if (vehicle.status == VehicleStatus.rented && status != VehicleStatus.rented) {
      throw AppException('Veículo locado: registre a devolução antes de alterar o status');
    }
    if (vehicle.status != VehicleStatus.rented && status == VehicleStatus.rented) {
      throw AppException('O status "Locado" é definido apenas por uma locação');
    }
    vehicle
      ..brand = brand.trim()
      ..model = model.trim()
      ..year = year
      ..plate = normalizedPlate
      ..color = color.trim()
      ..category = category
      ..dailyRate = dailyRate
      ..status = status;
    notifyListeners();
  }

  void deleteVehicle(int id) {
    _requireAdmin();
    final vehicle = vehicleById(id);
    if (vehicle.status == VehicleStatus.rented) {
      throw AppException('Não é possível excluir um veículo locado');
    }
    if (_rentals.any((r) => r.vehicle.id == id)) {
      throw AppException('Veículo possui histórico de locações e não pode ser excluído');
    }
    _vehicles.remove(vehicle);
    notifyListeners();
  }

  // ------------------------------------------------------------ Locações

  /// Diárias cobradas entre a retirada e a devolução: dias de calendário, mínimo 1.
  static int chargeableDays(DateTime start, DateTime end) {
    final days = daysBetween(start, end);
    return days < 1 ? 1 : days;
  }

  Rental createRental({
    required int vehicleId,
    required DateTime startDate,
    required DateTime expectedReturnDate,
  }) {
    final user = currentUser;
    if (user == null) throw AppException('Faça login para alugar um veículo');

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(expectedReturnDate.year, expectedReturnDate.month, expectedReturnDate.day);
    if (start.isBefore(today)) throw AppException('A data de retirada não pode estar no passado');
    if (!end.isAfter(start)) {
      throw AppException('A devolução prevista deve ser posterior à retirada');
    }

    final vehicle = vehicleById(vehicleId);
    if (vehicle.status != VehicleStatus.available) {
      throw AppException('Veículo indisponível para locação');
    }

    final days = daysBetween(start, end);
    vehicle.status = VehicleStatus.rented;
    final rental = Rental(
      id: _nextRentalId++,
      user: user,
      vehicle: vehicle,
      startDate: start,
      expectedReturnDate: end,
      dailyRate: vehicle.dailyRate,
      estimatedAmount: vehicle.dailyRate * days,
      createdAt: now,
    );
    _rentals.add(rental);
    notifyListeners();
    return rental;
  }

  /// Registra a devolução cobrando os dias efetivamente utilizados (mínimo 1).
  void returnRental(int rentalId) {
    final user = currentUser;
    final rental = _rentals.where((r) => r.id == rentalId).firstOrNull;
    if (user == null || rental == null || (!user.isAdmin && rental.user.id != user.id)) {
      throw AppException('Locação não encontrada');
    }
    if (rental.status != RentalStatus.active) {
      throw AppException('Esta locação já foi finalizada');
    }
    final returnedAt = now;
    rental
      ..status = RentalStatus.returned
      ..returnedAt = returnedAt
      ..totalAmount = rental.dailyRate * chargeableDays(rental.startDate, returnedAt);
    rental.vehicle.status = VehicleStatus.available;
    notifyListeners();
  }

  void _requireAdmin() {
    if (!isAdmin) throw AppException('Apenas administradores podem gerenciar veículos');
  }

  // ---------------------------------------------------------------- Seed

  void _seed() {
    _users.addAll([
      User(id: _nextUserId++, name: 'Administrador', email: 'admin@locadora.com', password: 'admin123', role: Role.admin),
      User(id: _nextUserId++, name: 'Maria Silva', email: 'maria@locadora.com', password: '123456'),
      User(id: _nextUserId++, name: 'João Souza', email: 'joao@locadora.com', password: '123456'),
    ]);

    Vehicle v(String brand, String model, int year, String plate, String color, VehicleCategory category, double rate) =>
        Vehicle(
          id: _nextVehicleId++,
          brand: brand,
          model: model,
          year: year,
          plate: plate,
          color: color,
          category: category,
          dailyRate: rate,
        );

    _vehicles.addAll([
      v('Fiat', 'Mobi', 2023, 'QSA1B23', 'Azul', VehicleCategory.economy, 89.9),
      v('Volkswagen', 'Polo', 2024, 'RFT2C34', 'Azul', VehicleCategory.hatch, 129.9),
      v('Toyota', 'Corolla', 2024, 'PBX3D45', 'Branco', VehicleCategory.sedan, 219.9),
      v('Jeep', 'Compass', 2023, 'OJK4E56', 'Branco', VehicleCategory.suv, 289.9),
      v('Hyundai', 'Creta', 2025, 'SLM5F67', 'Prata', VehicleCategory.suv, 249.9),
      v('Fiat', 'Toro', 2024, 'QWE6G78', 'Vermelho', VehicleCategory.pickup, 319.9),
    ]);

    // Histórico: Maria já alugou o Corolla por 3 dias.
    final maria = _users[1];
    final corolla = _vehicles[2];
    final start = today.subtract(const Duration(days: 10));
    final end = start.add(const Duration(days: 3));
    _rentals.add(Rental(
      id: _nextRentalId++,
      user: maria,
      vehicle: corolla,
      startDate: start,
      expectedReturnDate: end,
      dailyRate: corolla.dailyRate,
      estimatedAmount: corolla.dailyRate * 3,
      createdAt: start,
      returnedAt: end,
      totalAmount: corolla.dailyRate * 3,
      status: RentalStatus.returned,
    ));
  }
}

/// Disponibiliza o [AppStore] para toda a árvore de widgets.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// Acesso sem registrar dependência (para callbacks como onPressed).
  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
