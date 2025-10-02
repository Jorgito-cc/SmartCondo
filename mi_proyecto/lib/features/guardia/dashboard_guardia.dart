import 'package:flutter/material.dart';

import 'visitantes_page.dart';
import 'visitante_form.dart';
import 'placas_page.dart';
import 'camaras_page.dart';
import 'alertas_page.dart';
import 'incidente_form.dart';
import 'qr_access_page.dart';
import 'PerfilGuardiaPage.dart';

class DashboardGuardia extends StatefulWidget {
  const DashboardGuardia({super.key});
  @override
  State<DashboardGuardia> createState() => _DashboardGuardiaState();
}

class _DashboardGuardiaState extends State<DashboardGuardia> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(goToTab: (i) => setState(() => _index = i)),
      const VisitantesPage(),
      const CamarasPage(),
      const AlertasPage(),
      const _QrHubPage(),
         const PerfilGuardiaPage(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Visitantes'),
          NavigationDestination(icon: Icon(Icons.videocam_outlined), label: 'Cámaras'),
          NavigationDestination(icon: Icon(Icons.notifications_active_outlined), label: 'Alertas'),
          NavigationDestination(icon: Icon(Icons.qr_code_2), label: 'QR'),
                    NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),

        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.goToTab});
  final void Function(int) goToTab;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      _Item('Control de Visitantes', Icons.badge_outlined, () => goToTab(1)),
      _Item('Registrar Ingreso', Icons.person_add_alt_1_outlined, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitanteFormPage()));
      }),
      _Item('Validar Placa', Icons.directions_car_filled_outlined, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlacasPage()));
      }),
      _Item('Cámaras IA', Icons.videocam_outlined, () => goToTab(2)),
      _Item('Alertas tiempo real', Icons.notifications_active_outlined, () => goToTab(3)),
      _Item('Reporte de Incidente', Icons.report_gmailerrorred_outlined, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidenteFormPage()));
      }),
      _Item('Escanear QR', Icons.qr_code_scanner, () => goToTab(4)),
      _Item('Datos y sesion', Icons.person_outline, () => goToTab(5)),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1,
          ),
          itemBuilder: (_, i) => _CardItem(item: items[i], cs: cs),
        ),
      ),
    );
  }
}

class _Item {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _Item(this.title, this.icon, this.onTap);
}

class _CardItem extends StatelessWidget {
  const _CardItem({super.key, required this.item, required this.cs});
  final _Item item;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: cs.shadow.withOpacity(.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(item.icon, size: 36, color: cs.primary),
            const SizedBox(height: 12),
            Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

/// Hub de QR con ambas acciones
class _QrHubPage extends StatelessWidget {
  const _QrHubPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso por QR')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Escanear QR'),
                subtitle: const Text('Validar entrada/salida'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScanPage())),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.qr_code_2),
                title: const Text('Mostrar QR de invitado'),
                subtitle: const Text('Para lectura rápida en el control'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrShowPage(code: 'ACCESO-INVITADO-12345')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
