import 'package:flutter/material.dart';

class TareaDetallePage extends StatefulWidget {
  const TareaDetallePage({super.key, required this.tarea});
  final dynamic tarea; // _Tarea del page anterior

  @override
  State<TareaDetallePage> createState() => _TareaDetallePageState();
}

class _TareaDetallePageState extends State<TareaDetallePage> {
  late String _estado;
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _estado = widget.tarea.estado;
    _descCtrl.text = widget.tarea.descripcion ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tarea;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de tarea')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: Text(t.titulo),
            subtitle: Text('${t.ubicacion} • Prioridad ${t.prioridad}'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _estado,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: const [
              DropdownMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
              DropdownMenuItem(value: 'EN PROCESO', child: Text('En proceso')),
              DropdownMenuItem(value: 'COMPLETADA', child: Text('Completada')),
            ],
            onChanged: (v) => setState(() => _estado = v ?? _estado),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Notas/Trabajo realizado',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              t.estado = _estado;
              t.descripcion = _descCtrl.text.trim();
              Navigator.pop(context, t);
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
