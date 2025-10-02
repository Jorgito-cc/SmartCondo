import 'dart:io';
import 'package:flutter/material.dart';
import 'camera_capture_page.dart';

class VisitanteFormPage extends StatefulWidget {
  const VisitanteFormPage({super.key});
  @override State<VisitanteFormPage> createState() => _VisitanteFormPageState();
}

class _VisitanteFormPageState extends State<VisitanteFormPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _doc    = TextEditingController();
  final _unidad = TextEditingController();
  String? _fotoPath;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Ingreso')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: InkWell(
                onTap: () async {
                  final path = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const CameraCapturePage()));
                  if (path != null) setState(()=> _fotoPath = path);
                },
                borderRadius: BorderRadius.circular(60),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: cs.primaryContainer,
                  child: _fotoPath == null
                    ? Icon(Icons.camera_alt_outlined, color: cs.onPrimaryContainer, size: 36)
                    : ClipOval(child: Image.file(File(_fotoPath!), width: 96, height: 96, fit: BoxFit.cover)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
              validator: (v)=> v==null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doc,
              decoration: const InputDecoration(labelText: 'Documento de identidad', prefixIcon: Icon(Icons.credit_card)),
              validator: (v)=> v==null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unidad,
              decoration: const InputDecoration(labelText: 'Unidad a visitar (ej. Torre A • Dpto 12)', prefixIcon: Icon(Icons.home_work_outlined)),
              validator: (v)=> v==null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Registrar ingreso'),
              onPressed: () {
                if (_form.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingreso registrado (mock). Foto: ${_fotoPath ?? 'sin foto'}')));
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
