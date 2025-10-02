import 'package:flutter/material.dart';

class ReportesPage extends StatelessWidget {
  const ReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat('Tareas completadas', '18'),
      _Stat('Pendientes', '4'),
      _Stat('En proceso', '2'),
      _Stat('Costo total (mes)', 'Bs. 1,235'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12, runSpacing: 12,
            children: stats.map((s) => _StatCard(stat: s)).toList(),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Resumen semanal'),
              subtitle: const Text('Picos de incidencia: Miércoles y Viernes'),
              trailing: FilledButton(
                onPressed: () {},
                child: const Text('Exportar'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Top categorías'),
              subtitle: const Text('Electricidad • Plomería • Pintura'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final String title; final String value;
  _Stat(this.title, this.value);
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;
    return Container(
      width: w,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stat.title, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(stat.value, style: Theme.of(context).textTheme.headlineSmall),
      ]),
    );
  }
}
