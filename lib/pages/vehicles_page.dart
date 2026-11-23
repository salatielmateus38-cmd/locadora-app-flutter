import 'package:flutter/material.dart';

import '../app_store.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'rent_vehicle_page.dart';
import 'vehicle_form_page.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final _search = TextEditingController();
  VehicleCategory? _category;
  VehicleStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Vehicle> _filter(List<Vehicle> fleet) {
    final term = _search.text.trim().toLowerCase();
    return fleet
        .where((v) =>
            (_category == null || v.category == _category) &&
            (_status == null || v.status == _status) &&
            (term.isEmpty || '${v.brand} ${v.model} ${v.plate}'.toLowerCase().contains(term)))
        .toList();
  }

  Future<void> _delete(Vehicle vehicle) async {
    final store = StoreScope.read(context);
    final ok = await confirm(
      context,
      title: 'Excluir veículo',
      message: 'Deseja excluir ${vehicle.name} (${vehicle.plate})? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      store.deleteVehicle(vehicle.id);
      showMessage(context, 'Veículo excluído');
    } on AppException catch (e) {
      showMessage(context, e.message, error: true);
    }
  }

  void _openForm([Vehicle? vehicle]) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleFormPage(vehicle: vehicle)));
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final fleet = store.vehicles;
    final vehicles = _filter(fleet);

    return Scaffold(
      appBar: AppBar(title: const Text('Veículos')),
      floatingActionButton: store.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: AppColors.brand600,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Novo veículo'),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList.list(children: [
              _FleetStats(fleet: fleet),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por marca, modelo ou placa',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Todas', _category == null, () => setState(() => _category = null)),
                    for (final c in VehicleCategory.values)
                      _chip(c.label, _category == c, () => setState(() => _category = c)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Todos status', _status == null, () => setState(() => _status = null)),
                    for (final s in VehicleStatus.values)
                      _chip(s.label, _status == s, () => setState(() => _status = s)),
                  ],
                ),
              ),
            ]),
          ),
          if (vehicles.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(icon: Icons.search_off, title: 'Nenhum veículo encontrado'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              sliver: SliverList.separated(
                itemCount: vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final vehicle = vehicles[i];
                  return _VehicleCard(
                    vehicle: vehicle,
                    isAdmin: store.isAdmin,
                    onRent: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RentVehiclePage(vehicleId: vehicle.id)),
                    ),
                    onEdit: () => _openForm(vehicle),
                    onDelete: () => _delete(vehicle),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

class _FleetStats extends StatelessWidget {
  const _FleetStats({required this.fleet});
  final List<Vehicle> fleet;

  @override
  Widget build(BuildContext context) {
    int count(VehicleStatus s) => fleet.where((v) => v.status == s).length;
    final stats = [
      ('Frota', fleet.length, Icons.garage_outlined),
      ('Disponíveis', count(VehicleStatus.available), Icons.check_circle_outline),
      ('Locados', count(VehicleStatus.rented), Icons.key_outlined),
      ('Manutenção', count(VehicleStatus.maintenance), Icons.build_outlined),
    ];

    return Row(
      children: [
        for (final (label, value, icon) in stats)
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Column(
                  children: [
                    Icon(icon, color: AppColors.brand500, size: 22),
                    const SizedBox(height: 4),
                    Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.isAdmin,
    required this.onRent,
    required this.onEdit,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final bool isAdmin;
  final VoidCallback onRent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final available = vehicle.status == VehicleStatus.available;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                VehicleImage(vehicle, height: 160),
                Positioned(top: 10, right: 10, child: StatusBadge.vehicle(vehicle.status)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.category.label.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand600, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(vehicle.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${vehicle.year} · ${vehicle.color} · ${vehicle.plate}',
                      style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(TextSpan(children: [
                          TextSpan(
                            text: formatCurrency(vehicle.dailyRate),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          const TextSpan(text: ' /dia', style: TextStyle(color: AppColors.muted)),
                        ])),
                      ),
                      if (isAdmin) ...[
                        IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), tooltip: 'Editar'),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                          tooltip: 'Excluir',
                        ),
                      ],
                      FilledButton(
                        onPressed: available ? onRent : null,
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                        child: Text(available ? 'Alugar' : 'Indisponível'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
