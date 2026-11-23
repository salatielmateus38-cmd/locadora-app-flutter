import 'package:flutter_test/flutter_test.dart';
import 'package:locadora_app/app_store.dart';
import 'package:locadora_app/format.dart';
import 'package:locadora_app/models.dart';

void main() {
  late DateTime now;
  late AppStore store;

  setUp(() {
    now = DateTime(2026, 3, 10, 9);
    store = AppStore(clock: () => now);
  });

  group('autenticação', () {
    test('login com credenciais do seed', () {
      store.login('admin@locadora.com', 'admin123');
      expect(store.isAdmin, isTrue);
    });

    test('senha errada é rejeitada', () {
      expect(() => store.login('maria@locadora.com', 'errada'), throwsA(isA<AppException>()));
    });

    test('cadastro cria cliente e não permite e-mail duplicado', () {
      store.register('Ana Lima', 'ana@email.com', '123456');
      expect(store.currentUser!.role, Role.customer);
      expect(() => store.register('Outra', 'ANA@email.com', '123456'), throwsA(isA<AppException>()));
    });
  });

  group('locações', () {
    test('alugar marca o veículo como locado e calcula o valor estimado', () {
      store.login('joao@locadora.com', '123456');
      final mobi = store.vehicles.first;
      final rental = store.createRental(
        vehicleId: mobi.id,
        startDate: DateTime(2026, 3, 10),
        expectedReturnDate: DateTime(2026, 3, 13),
      );
      expect(mobi.status, VehicleStatus.rented);
      expect(rental.estimatedAmount, closeTo(89.9 * 3, 0.001));
      expect(
        () => store.createRental(
          vehicleId: mobi.id,
          startDate: DateTime(2026, 3, 10),
          expectedReturnDate: DateTime(2026, 3, 12),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('datas inválidas são rejeitadas', () {
      store.login('joao@locadora.com', '123456');
      final id = store.vehicles.first.id;
      expect(
        () => store.createRental(vehicleId: id, startDate: DateTime(2026, 3, 9), expectedReturnDate: DateTime(2026, 3, 12)),
        throwsA(isA<AppException>()),
      );
      expect(
        () => store.createRental(vehicleId: id, startDate: DateTime(2026, 3, 12), expectedReturnDate: DateTime(2026, 3, 12)),
        throwsA(isA<AppException>()),
      );
    });

    test('devolução cobra os dias usados (mínimo 1) e libera o veículo', () {
      store.login('joao@locadora.com', '123456');
      final polo = store.vehicles[1];
      final rental = store.createRental(
        vehicleId: polo.id,
        startDate: DateTime(2026, 3, 10),
        expectedReturnDate: DateTime(2026, 3, 15),
      );

      now = DateTime(2026, 3, 12, 18); // devolvido 3 dias antes do previsto -> 2 diárias
      store.returnRental(rental.id);

      expect(rental.status, RentalStatus.returned);
      expect(rental.totalAmount, closeTo(129.9 * 2, 0.001));
      expect(polo.status, VehicleStatus.available);
      expect(() => store.returnRental(rental.id), throwsA(isA<AppException>()));
    });

    test('cliente vê apenas as próprias locações; admin vê todas', () {
      store.login('joao@locadora.com', '123456');
      expect(store.rentals, isEmpty);
      store.login('maria@locadora.com', '123456');
      expect(store.rentals, hasLength(1));
      store.login('admin@locadora.com', 'admin123');
      expect(store.rentals, hasLength(1));
    });
  });

  group('veículos', () {
    test('apenas admin cadastra, e a placa é normalizada e única', () {
      store.login('maria@locadora.com', '123456');
      expect(
        () => store.addVehicle(
            brand: 'Fiat', model: 'Argo', year: 2024, plate: 'abc-1d23', color: 'Preto',
            category: VehicleCategory.hatch, dailyRate: 120),
        throwsA(isA<AppException>()),
      );

      store.login('admin@locadora.com', 'admin123');
      final argo = store.addVehicle(
          brand: 'Fiat', model: 'Argo', year: 2024, plate: 'abc-1d23', color: 'Preto',
          category: VehicleCategory.hatch, dailyRate: 120);
      expect(argo.plate, 'ABC1D23');
      expect(
        () => store.addVehicle(
            brand: 'Fiat', model: 'Uno', year: 2020, plate: 'ABC1D23', color: 'Branco',
            category: VehicleCategory.economy, dailyRate: 80),
        throwsA(isA<AppException>()),
      );
    });

    test('veículo com histórico não pode ser excluído', () {
      store.login('admin@locadora.com', 'admin123');
      final corolla = store.vehicles.firstWhere((v) => v.model == 'Corolla');
      expect(() => store.deleteVehicle(corolla.id), throwsA(isA<AppException>()));
      final toro = store.vehicles.firstWhere((v) => v.model == 'Toro');
      store.deleteVehicle(toro.id);
      expect(store.vehicles.any((v) => v.model == 'Toro'), isFalse);
    });
  });

  test('formatação em reais', () {
    expect(formatCurrency(1159.6), 'R\$ 1.159,60');
    expect(formatCurrency(89.9), 'R\$ 89,90');
  });
}
