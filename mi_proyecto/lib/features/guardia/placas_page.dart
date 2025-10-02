import 'dart:math';
import 'package:flutter/material.dart';
import 'camera_capture_page.dart';
import 'dart:io';
class PlacasPage extends StatefulWidget {
  const PlacasPage({super.key});
  @override State<PlacasPage> createState() => _PlacasPageState();
}

class _PlacasPageState extends State<PlacasPage> {
  final _placaCtrl = TextEditingController(text: '1254ABC');
  String? _resultado; // Autorizado / No autorizado
  String? _fotoPath;

  Future<void> _capturarPlaca() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraCapturePage()),
    );
    if (path != null) {
      // MOCK OCR: simplemente setea un valor ejemplo y guarda la foto
      setState(() {
        _fotoPath = path;
        // "Reconocido"
        final muestras = ['1254ABC','CD-456 AB','ABC-123','ZX-77 9GH'];
        _placaCtrl.text = muestras[Random().nextInt(muestras.length)];
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Placa reconocida (mock)')));
    }
  }

  void _validar() {
    final ok = _placaCtrl.text.toUpperCase().contains('AB');
    setState(()=> _resultado = ok ? 'Vehículo AUTORIZADO' : 'Vehículo NO AUTORIZADO');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Validación de Placas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _placaCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Placa vehicular',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _validar,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Validar'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _capturarPlaca,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Capturar'),
            ),
          ]),
          const SizedBox(height: 12),
          if (_resultado != null)
            Card(
              color: _resultado!.contains('NO') ? cs.errorContainer : cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _resultado!,
                  style: TextStyle(
                    color: _resultado!.contains('NO') ? cs.onErrorContainer : cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (_fotoPath != null)
            Card(
              child: Column(
                children: [
                  const ListTile(leading: Icon(Icons.photo), title: Text('Foto capturada')),
                  //Nota: Para ver la foto real capturada, puedes reemplazar el Image.asset(...) por:
                  //Image.file(File(_fotoPath!), height: 180, fit: BoxFit.cover)
Image.file(File(_fotoPath!), height: 180, fit: BoxFit.cover)

                 // Image.asset('assets/placeholder.png', height: 0, width: 0), // opcional si no tienes assets
                  // si quieres ver la foto real, usa Image.file(File(_fotoPath!))
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Text('Historial reciente'),
          const SizedBox(height: 8),
          ...[
            'ABC-123 • AUTORIZADO • 12:41',
            'CD-456 AB • NO AUTORIZADO • 12:10',
            'AB-126 CD • AUTORIZADO • 11:55',
          ].map((s)=> Card(child: ListTile(leading: const Icon(Icons.car_rental), title: Text(s)))),
        ],
      ),
    );
  }
}
