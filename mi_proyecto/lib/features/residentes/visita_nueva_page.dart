import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl =
    'https://backend-condominio-production.up.railway.app/api';

class VisitaNuevaPage extends StatefulWidget {
  const VisitaNuevaPage({super.key});
  @override
  State<VisitaNuevaPage> createState() => _VisitaNuevaPageState();
}

class _VisitaNuevaPageState extends State<VisitaNuevaPage> {
  final _form = GlobalKey<FormState>();
  final _unidadCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  DateTime? _llegada;
  DateTime? _salida;
  File? _imageFile; // Solo para mostrar en UI
  bool _sending = false;

  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (src == null) return;

    final picker = ImagePicker();
    final x = await picker.pickImage(source: src, imageQuality: 85);
    if (x != null) setState(() => _imageFile = File(x.path));
  }

  Future<void> _pickFechaHora({required bool esLlegada}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: (esLlegada ? _llegada : _salida) ?? now,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        (esLlegada ? _llegada : _salida) ?? now,
      ),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => esLlegada ? _llegada = dt : _salida = dt);
  }

  String _isoZ(DateTime dt) => dt.toUtc().toIso8601String();

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_llegada == null || _salida == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona llegada y salida')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No hay token. Inicia sesión.');

      final uri = Uri.parse('$kBaseUrl/visitas/');

      // ⚠️ En un caso real, aquí deberías subir la foto a un storage (Firebase, Cloudinary, etc.)
      // y obtener un link público. De momento, solo ponemos null si no hay.
      final body = {
        'unidad_id': int.parse(_unidadCtrl.text.trim()),
        'nombre': _nombreCtrl.text.trim(),
        'fecha_hora_llegada': _isoZ(_llegada!),
        'fecha_hora_salida': _isoZ(_salida!),
        'url_img': _imageFile != null
            ? "https://mis-imagenes.com/${_imageFile!.path.split('/').last}"
            : null, // 👈 opcional
      };

      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Visita creada')));
        Navigator.pop(context, true);
      } else {
        String msg = 'Error ${res.statusCode}';
        try {
          final err = jsonDecode(res.body);
          msg = (err['detail'] ?? err['message'] ?? msg).toString();
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _unidadCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva visita')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _unidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID de Unidad',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del visitante',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Fecha/Hora de llegada'),
              subtitle: Text(
                _llegada == null
                    ? 'Sin seleccionar'
                    : _llegada!.toLocal().toString(),
              ),
              trailing: TextButton(
                onPressed: () => _pickFechaHora(esLlegada: true),
                child: const Text('Elegir'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Fecha/Hora de salida'),
              subtitle: Text(
                _salida == null
                    ? 'Sin seleccionar'
                    : _salida!.toLocal().toString(),
              ),
              trailing: TextButton(
                onPressed: () => _pickFechaHora(esLlegada: false),
                child: const Text('Elegir'),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : null,
                  child: _imageFile == null
                      ? const Icon(Icons.image_outlined, size: 32)
                      : null,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Seleccionar foto (opcional)'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Crear visita'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
