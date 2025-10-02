import 'package:flutter/material.dart';
import 'tareas_page.dart';
import 'costos_page.dart';
import 'reportes_page.dart';
import 'perfil_page.dart';

class DashboardPersonal extends StatefulWidget {
  const DashboardPersonal({super.key});
  @override
  State<DashboardPersonal> createState() => _DashboardPersonalState();
}

class _DashboardPersonalState extends State<DashboardPersonal> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(goToTab: (i) => setState(() => _index = i)),
      const TareasPage(),
      const CostosPage(),
      const ReportesPage(),
      const PerfilPage(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.build_outlined), label: 'Tareas'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Costos'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Reportes'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
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
    final w = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hola, Personal 👷‍♂️',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              _QuickCard(width: w, icon: Icons.build_outlined, title: 'Tareas',
                subtitle: 'Pendientes y asignadas', onTap: () => goToTab(1)),
              _QuickCard(width: w, icon: Icons.receipt_long_outlined, title: 'Costos',
                subtitle: 'Reparaciones y gastos', onTap: () => goToTab(2)),
              _QuickCard(width: w, icon: Icons.bar_chart_outlined, title: 'Reportes',
                subtitle: 'Resumen y métricas', onTap: () => goToTab(3)),
              _QuickCard(width: w, icon: Icons.person_outline, title: 'Perfil',
                subtitle: 'Datos y sesión', onTap: () => goToTab(4)),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: cs.primaryContainer,
            child: ListTile(
              title: const Text('Tarea prioritaria: Fuga en Torre B'),
              subtitle: const Text('Asignada hace 2 h • Prioridad Alta'),
              trailing: FilledButton(
                onPressed: () => goToTab(1),
                child: const Text('Ver'),
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
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: width,
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
