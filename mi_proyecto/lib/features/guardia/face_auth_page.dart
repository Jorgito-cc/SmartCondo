import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const String kBase = 'https://backend-condominio-production.up.railway.app';

Future<String> _fileToDataUrl(String path) async {
  final b = await File(path).readAsBytes();
  return 'data:image/jpeg;base64,${base64Encode(b)}';
}

class FaceSearchMiniPage extends StatefulWidget {
  const FaceSearchMiniPage({super.key});
  @override
  State<FaceSearchMiniPage> createState() => _FaceSearchMiniPageState();
}

class _FaceSearchMiniPageState extends State<FaceSearchMiniPage> {
  CameraController? _cam;
  bool _ready = false, _busy = false;
  final _thrCtrl = TextEditingController(text: '0.40');
  final _topKCtrl = TextEditingController(text: '3');
  String _result = '—';

  @override
  void initState() {
    super.initState();
    _initCam();
  }

  Future<void> _initCam() async {
    final ok = await Permission.camera.request();
    if (!ok.isGranted) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final cams = await availableCameras();
    final front = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );
    _cam = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _cam!.initialize();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _cam?.dispose();
    _thrCtrl.dispose();
    _topKCtrl.dispose();
    super.dispose();
  }

  Future<void> _shotAndSearch() async {
    if (!(_cam?.value.isInitialized ?? false)) return;
    setState(() {
      _busy = true;
      _result = '—';
    });
    try {
      final x = await _cam!.takePicture();
      final dir = await getTemporaryDirectory();
      final f = await File(
        x.path,
      ).copy('${dir.path}/face_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final dataUrl = await _fileToDataUrl(f.path);

      final thr = double.tryParse(_thrCtrl.text.trim()) ?? 0.40;
      final topK = int.tryParse(_topKCtrl.text.trim()) ?? 3;

      final res = await http.post(
        Uri.parse('$kBase/auth_face/search-user/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'photo_base64': dataUrl,
          'threshold_cosine': thr,
          'top_k': topK,
        }),
      );

      final j = jsonDecode(res.body);
      // Este endpoint puede devolver 200 o 404 con 'best_candidate'
      setState(() => _result = const JsonEncoder.withIndent('  ').convert(j));
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar usuario por rostro')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_busy) const LinearProgressIndicator(),
                AspectRatio(
                  aspectRatio: _cam!.value.aspectRatio,
                  child: CameraPreview(_cam!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _thrCtrl,
                        decoration: const InputDecoration(
                          labelText: 'threshold_cosine',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _topKCtrl,
                        decoration: const InputDecoration(labelText: 'top_k'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _shotAndSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Capturar y buscar'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Respuesta:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_result),
                ),
              ],
            ),
    );
  }
}
