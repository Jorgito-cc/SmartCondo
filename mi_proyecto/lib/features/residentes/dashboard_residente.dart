import 'package:flutter/material.dart';
import 'finanzas_page.dart';
import 'reservas_page.dart';
import 'avisos_page.dart';
import 'notificaciones_page.dart';
import 'comunidad_page.dart';
import 'visita_nueva_page.dart'; // <- NUEVA


class DashboardResidente extends StatefulWidget {
  const DashboardResidente({super.key});
  @override
  State<DashboardResidente> createState() => _DashboardResidenteState();
}

class _DashboardResidenteState extends State<DashboardResidente> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // 👇 AQUI: agrega la 6ta página (Comunidad)
    final pages = [
      _HomeTab(goToTab: (i) => setState(() => _index = i)),
      const FinanzasPage(),
      const ReservasPage(),
      const AvisosPage(),
      const NotificacionesPage(),
      const ComunidadPage(), // <- NUEVA
      const VisitaNuevaPage(), // <- NUEVA
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Finanzas',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            label: 'Avisos',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Notifs',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            label: 'Comunidad',
          ), // <- NUEVA
          NavigationDestination(
            icon: Icon(Icons.visibility_outlined),
            label: 'visita',
          ), // <- NUEVA
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.goToTab});
  final void Function(int index) goToTab;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bienvenido, Residente 👋',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Finanzas',
                subtitle: 'Cuotas y pagos',
                onTap: () => goToTab(1),
              ),
              _QuickCard(
                icon: Icons.event_available_outlined,
                title: 'Reservas',
                subtitle: 'Áreas comunes',
                onTap: () => goToTab(2),
              ),
              _QuickCard(
                icon: Icons.campaign_outlined,
                title: 'Avisos',
                subtitle: 'Comunicados',
                onTap: () => goToTab(3),
              ),
              _QuickCard(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                subtitle: 'Vencimientos y alertas',
                onTap: () => goToTab(4),
              ),
              _QuickCard(
                icon: Icons.forum_outlined,
                title: 'Comunidad',
                subtitle: 'Feedback y reportes vecinales',
                onTap: () => goToTab(5), // índice coincide con pages[5]
              ),
              _QuickCard(
                icon: Icons.visibility_outlined,
                title: 'visita',
                subtitle: 'visitas',
                onTap: () => goToTab(6), // índice coincide con pages[5]
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: cs.primaryContainer,
            child: ListTile(
              title: const Text('Próximo vencimiento: 30/10'),
              subtitle: const Text('Cuota de expensas – Bs. 350'),
              trailing: FilledButton(
                onPressed: () => goToTab(1),
                child: const Text('Pagar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: w,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
