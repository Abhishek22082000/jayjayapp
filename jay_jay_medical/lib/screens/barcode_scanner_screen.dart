import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

// Camera-based barcode scanner backed by flutter_zxing (zxing-cpp via FFI,
// no Google MLKit / Play Services dependency).
//
// Pops with the first detected raw value as a String, or with null if the
// user cancels.
//
// Usage:
//   final String? code = await Navigator.of(context).push<String>(
//     MaterialPageRoute<String>(builder: (_) => const BarcodeScannerScreen()),
//   );
//
// PERMISSIONS:
//   • Android: `<uses-permission android:name="android.permission.CAMERA"/>`
//     in `android/app/src/main/AndroidManifest.xml`. flutter_zxing also
//     declares it in its own plugin manifest so manifest merger usually
//     covers this, but the CI workflow adds it explicitly for safety.
//   • iOS: add NSCameraUsageDescription to `ios/Runner/Info.plist`:
//       <key>NSCameraUsageDescription</key>
//       <string>Scan barcodes on tablet packaging.</string>
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _handled = false;

  void _onScan(Code result) {
    if (_handled) return;
    final String? text = result.text;
    if (text == null || text.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop<String>(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan barcode'),
      ),
      body: ReaderWidget(
        onScan: _onScan,
        showFlashlight: true,
        showGallery: false,
        showToggleCamera: true,
        showScannerOverlay: true,
        scanDelay: const Duration(milliseconds: 300),
      ),
    );
  }
}
