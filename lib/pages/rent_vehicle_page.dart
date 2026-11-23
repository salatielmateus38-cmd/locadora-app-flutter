import 'package:flutter/material.dart';

import '../app_store.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class RentVehiclePage extends StatefulWidget {
  const RentVehiclePage({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  State<RentVehiclePage> createState() => _RentVehiclePageState();
}

class _RentVehiclePageState extends State<RentVehiclePage> {
  late DateTime _start;
  late DateTime _end;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final today = StoreScope.read(context).today;
    _start = today;
    _end = today.add(const Duration(days: 3));
  }

  Future<void> _pickDate({required bool isStart}) async {
    final today = StoreScope.read(context).today;
    final first = isStart ? today : _start.add(const Duration(days: 1));
    final current = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: today.add(const Duration(days: 365)),
      helpText: isStart ? 'Data de retirada' : 'Devolução prevista',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (!_end.isAfter(_start)) _end = _start.add(const Duration(days: 1));
      } else {
        _end = picked;
      }
    });
  }

  void _submit(Vehicle vehicle) {
    setState(() => _error = null);
    try {
      StoreScope.read(context).createRental(vehicleId: vehicle.id, startDate: _start, expectedReturnDate: _end);
      showMessage(context, 'Locação de ${vehicle.name} confirmada! Veja na aba de locações.');
      Navigator.pop(context);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final vehicle = store.vehicles.where((v) => v.id == widget.vehicleId).firstOrNull;
    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.error_outline, title: 'Veículo não encontrado'),
      );
    }

    final days = daysBetween(_start, _end);
    final validPeriod = days > 0;
    final available = vehicle.status == VehicleStatus.available;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar locação')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VehicleImage(vehicle, height: 190),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(vehicle.category.label.toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brand600,
                                          letterSpacing: 1)),
                                  Text(vehicle.name,
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            StatusBadge.vehicle(vehicle.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _InfoTile('Ano', '${vehicle.year}'),
                            const SizedBox(width: 8),
                            _InfoTile('Cor', vehicle.color),
                            const SizedBox(width: 8),
                            _InfoTile('Placa', vehicle.plate),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _Check('Diária fixada no momento da reserva'),
                        const _Check('Devolveu antes? Paga só pelos dias usados'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Período da reserva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 12)],
                  _DateField(label: 'Data de retirada', value: _start, onTap: () => _pickDate(isStart: true)),
                  const SizedBox(height: 12),
                  _DateField(label: 'Devolução prevista', value: _end, onTap: () => _pickDate(isStart: false)),
                  const SizedBox(height: 20),
                  const Text('Resumo financeiro', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Divider(),
                  SummaryRow('Valor da diária', formatCurrency(vehicle.dailyRate)),
                  SummaryRow('Período', validPeriod ? pluralDays(days) : '—'),
                  const SizedBox(height: 8),
                  TotalBox('Total estimado', validPeriod ? formatCurrency(vehicle.dailyRate * days) : '—'),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: validPeriod && available ? () => _submit(vehicle) : null,
                    child: Text(available ? 'Confirmar locação' : 'Veículo indisponível'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined)),
        child: Text(formatDate(value)),
      ),
    );
  }
}
