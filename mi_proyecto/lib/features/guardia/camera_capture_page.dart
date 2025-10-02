import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});
  @override State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  bool _ready = false;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) { if (mounted) Navigator.pop(context); return; }

    final cams = await availableCameras();
    final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);

    _controller = CameraController(back, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();

    if (mounted) setState(()=> _ready = true);
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  Future<void> _takePhoto() async {
    if (!(_controller?.value.isInitialized ?? false)) return;
    final x = await _controller!.takePicture();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/visitante_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(x.path).copy(file.path);

    if (mounted) Navigator.pop(context, file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tomar foto del visitante')),
      body: !_ready
        ? const Center(child: CircularProgressIndicator())
        : Column(children: [
            AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: CameraPreview(_controller!)),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _takePhoto, icon: const Icon(Icons.camera), label: const Text('Capturar')),
          ]),
    );
  }
}
