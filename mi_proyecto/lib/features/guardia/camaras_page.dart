import 'package:flutter/material.dart';

class CamarasPage extends StatelessWidget {
  const CamarasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cams = [
      _Cam('Acceso Principal', 'Persona desconocida detectada', true),
      _Cam('Parqueo Norte', 'Vehículo autorizado', false),
      _Cam('Piscina', 'Sin novedades', false),
      _Cam('Torre C – Lobby', 'Movimiento detectado', true),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Cámaras con IA')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .85,
        ),
        itemCount: cams.length,
        itemBuilder: (_, i) {
          final c = cams[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openDetalle(context, c),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.black12,
                      child: const Center(child: Icon(Icons.videocam, size: 48, color: Colors.black45)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(c.alerta ? Icons.warning_amber_rounded : Icons.verified_outlined,
                                color: c.alerta ? Colors.amber[800] : Colors.green, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(c.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDetalle(BuildContext context, _Cam c) {
    showDialog(context: context, builder: (_) {
      return AlertDialog(
        title: Text(c.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 160, color: Colors.black12, child: const Center(child: Icon(Icons.videocam, size: 48))),
            const SizedBox(height: 12),
            Text(c.descripcion),
          ],
        ),
        actions: [ TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Cerrar')) ],
      );
    });
  }
}

class _Cam { final String nombre; final String descripcion; final bool alerta; _Cam(this.nombre, this.descripcion, this.alerta); }
