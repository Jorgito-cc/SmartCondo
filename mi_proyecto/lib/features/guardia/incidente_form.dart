import 'package:flutter/material.dart';

class IncidenteFormPage extends StatefulWidget {
  const IncidenteFormPage({super.key});
  @override State<IncidenteFormPage> createState() => _IncidenteFormPageState();
}

class _IncidenteFormPageState extends State<IncidenteFormPage> {
  final _form = GlobalKey<FormState>();
  final _desc = TextEditingController();
  String _estado = 'Pendiente';
  String? _foto; // mock

  @override
  Widget build(BuildContext context) {
    final estados = const ['Pendiente', 'En revisión', 'Resuelto'];

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte de Incidente')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descripción del incidente', alignLabelWithHint: true),
              validator: (v) => (v==null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _estado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(()=> _estado = v ?? 'Pendiente'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.attachment),
              label: Text(_foto == null ? 'Adjuntar foto (mock)' : 'Foto adjunta'),
              onPressed: () => setState(()=> _foto = 'mock.jpg'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Enviar reporte'),
              onPressed: () {
                if (_form.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reporte enviado (mock) • Estado: $_estado')),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
