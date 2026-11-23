import 'package:flutter/material.dart';

import '../app_store.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final user = store.currentUser;
    if (user == null) return const SizedBox.shrink();

    final rentals = store.rentals;
    final active = rentals.where((r) => r.status == RentalStatus.active).length;
    final spent = rentals.fold<double>(0, (sum, r) => sum + (r.totalAmount ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.brand100,
                    child: Text(
                      user.name.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.brand700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(user.email, style: const TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 6),
                        StatusBadge(user.isAdmin ? 'Administrador' : 'Cliente',
                            tone: user.isAdmin ? BadgeTone.orange : BadgeTone.blue),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.isAdmin ? 'Resumo da locadora' : 'Seu resumo',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Divider(),
                  SummaryRow('Locações', '${rentals.length}'),
                  SummaryRow('Em andamento', '$active'),
                  SummaryRow(user.isAdmin ? 'Faturamento (finalizadas)' : 'Total pago', formatCurrency(spent)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Como funciona', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 8),
                  _Step(Icons.search, 'Escolha o veículo', 'Filtre por categoria, marca ou modelo.'),
                  _Step(Icons.calendar_month, 'Defina as datas', 'O valor estimado aparece na hora.'),
                  _Step(Icons.key, 'Retire e devolva', 'Na devolução, você paga só pelos dias usados.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => StoreScope.read(context).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Projeto acadêmico UNIPÊ · dados mantidos em memória',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.icon, this.title, this.text);
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.brand50,
        child: Icon(icon, color: AppColors.brand600),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(text),
    );
  }
}
