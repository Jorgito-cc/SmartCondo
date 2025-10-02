import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Escáner de QR con mobile_scanner
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});
  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode], // opcional: solo QR
  );

  String? _ultimo;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final value = b.rawValue;
      if (value == null) continue;
      if (value != _ultimo && mounted) {
        setState(() => _ultimo = value);
        final ok = value.toUpperCase().contains('OK'); // mock de validación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'QR válido: $value' : 'QR inválido: $value')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(_ultimo == null ? 'Apunta al código QR' : 'Último: $_ultimo'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generador de QR (para pases/ingreso)
class QrShowPage extends StatelessWidget {
  final String code;
  const QrShowPage({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mostrar QR')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(data: code, size: 220),
            const SizedBox(height: 16),
            Text(code, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }
}
