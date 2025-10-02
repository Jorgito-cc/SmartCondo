import 'package:flutter/material.dart';

class AvisosPage extends StatefulWidget {
  const AvisosPage({super.key});
  @override
  State<AvisosPage> createState() => _AvisosPageState();
}

class _AvisosPageState extends State<AvisosPage> {
  final List<_Aviso> _items = [
    _Aviso(
      titulo: 'Corte de agua programado',
      contenido:
          'La empresa prestadora realizará un corte de agua el martes 22/10 de 09:00 a 12:00. '
          'Se recomienda almacenar agua con anticipación.',
      fecha: DateTime.now(),
      leido: false,
    ),
    _Aviso(
      titulo: 'Reunión de copropietarios',
      contenido:
          'Se convoca a reunión ordinaria el jueves 24/10 a las 20:00 en el Salón de eventos. '
          'Orden del día: informe de tesorería, seguridad y mantenimiento.',
      fecha: DateTime.now().subtract(const Duration(days: 1)),
      leido: true,
    ),
    _Aviso(
      titulo: 'Mantenimiento de ascensor',
      contenido:
          'El ascensor de la Torre B estará en mantenimiento el viernes 25/10 de 14:00 a 16:00.',
      fecha: DateTime.now().subtract(const Duration(days: 2)),
      leido: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final a = _items[i];
          return Card(
            child: ListTile(
              leading: Icon(
                a.leido ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
              ),
              title: Text(a.titulo),
              subtitle: Text(
                a.contenido,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(_fmt(a.fecha)),
              onTap: () async {
                // marca leído y abre detalle
                setState(() => a.leido = true);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AvisoDetallePage(aviso: a)),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _fmt(DateTime dt) {
    final d = '${dt.day}/${dt.month}';
    final h = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $h';
  }
}

class _Aviso {
  final String titulo;
  final String contenido;
  final DateTime fecha;
  bool leido;
  _Aviso({required this.titulo, required this.contenido, required this.fecha, this.leido = true});
}

class AvisoDetallePage extends StatelessWidget {
  final _Aviso aviso;
  const AvisoDetallePage({super.key, required this.aviso});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del aviso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(aviso.titulo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Publicado el ${aviso.fecha.day}/${aviso.fecha.month} '
              'a las ${aviso.fecha.hour.toString().padLeft(2, '0')}:${aviso.fecha.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(aviso.contenido, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
