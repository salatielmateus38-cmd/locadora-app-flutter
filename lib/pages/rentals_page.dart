import 'package:flutter/material.dart';

import '../app_store.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class RentalsPage extends StatefulWidget {
  const RentalsPage({super.key});

  @override
  State<RentalsPage> createState() => _RentalsPageState();
}

class _RentalsPageState extends State<RentalsPage> {
  RentalStatus? _filter;

  Future<void> _return(Rental rental) async {
    final store = StoreScope.read(context);
    final days = AppStore.chargeableDays(rental.startDate, store.now);
    final ok = await confirm(
      context,
      title: 'Registrar devolução',
      message: 'Confirmar a devolução de ${rental.vehicle.name}?\n\n'
          'Valor final: ${formatCurrency(rental.dailyRate * days)} (${pluralDays(days)}).',
      confirmLabel: 'Confirmar devolução',
    );
    if (!ok || !mounted) return;
    try {
      store.returnRental(rental.id);
      showMessage(context, 'Devolução registrada');
    } on AppException catch (e) {
      showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final rentals = store.rentals.where((r) => _filter == null || r.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: Text(store.isAdmin ? 'Locações' : 'Minhas locações')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<RentalStatus?>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: null, label: Text('Todas')),
                  ButtonSegment(value: RentalStatus.active, label: Text('Ativas')),
                  ButtonSegment(value: RentalStatus.returned, label: Text('Devolvidas')),
                ],
                selected: {_filter},
                onSelectionChanged: (value) => setState(() => _filter = value.first),
              ),
            ),
          ),
          Expanded(
            child: rentals.isEmpty
                ? const EmptyState(icon: Icons.assignment_outlined, title: 'Nenhuma locação por aqui')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: rentals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _RentalCard(
                      rental: rentals[i],
                      showUser: store.isAdmin,
                      today: store.today,
                      onReturn: () => _return(rentals[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RentalCard extends StatelessWidget {
  const _RentalCard({required this.rental, required this.showUser, required this.today, required this.onReturn});

  final Rental rental;
  final bool showUser;
  final DateTime today;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final active = rental.status == RentalStatus.active;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                VehicleThumb(rental.vehicle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rental.vehicle.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(
                        '${rental.vehicle.plate} · #${rental.id}${showUser ? ' · ${rental.user.name}' : ''}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StatusBadge.rental(rental.status),
                if (rental.isLate(today)) const StatusBadge('Atrasada', tone: BadgeTone.orange),
              ],
            ),
            const Divider(height: 24),
            SummaryRow('Período', '${formatDate(rental.startDate)} → ${formatDate(rental.expectedReturnDate)}'),
            SummaryRow('Diária', formatCurrency(rental.dailyRate)),
            if (active)
              SummaryRow('Estimado (${pluralDays(rental.expectedDays)})', formatCurrency(rental.estimatedAmount))
            else ...[
              if (rental.returnedAt != null) SummaryRow('Devolvido em', formatDateTime(rental.returnedAt!)),
              SummaryRow('Valor final', formatCurrency(rental.totalAmount ?? 0)),
            ],
            if (active) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('Registrar devolução'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
