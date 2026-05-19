import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../app/theme.dart';
import '../providers/filters_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.returnTo});

  // When set to 'form', the screen pops with the scanned value as its
  // route result so the form can paste it into the barcode field.
  // Otherwise the screen routes to /tablets with the scanned value pushed
  // into the search filter — the list filters via _matchesSearch which
  // already checks barcodeValue.
  final String? returnTo;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'qrScan');
  QRViewController? _controller;
  bool _handled = false;

  @override
  void reassemble() {
    super.reassemble();
    // Hot-reload preservation per qr_code_scanner README.
    if (defaultTargetPlatform == TargetPlatform.android) {
      _controller?.pauseCamera();
    }
    _controller?.resumeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onCreated(QRViewController c) {
    _controller = c;
    c.scannedDataStream.listen((Barcode data) {
      if (_handled) return;
      final String? code = data.code;
      if (code == null || code.trim().isEmpty) return;
      _handled = true;
      c.pauseCamera();
      _handleCode(code.trim());
    });
  }

  void _handleCode(String code) {
    if (!mounted) return;
    if (widget.returnTo == 'form') {
      context.pop(code);
      return;
    }
    ref.read(filtersProvider.notifier).reset();
    ref.read(filtersProvider.notifier).setSearch(code);
    context.go('/tablets');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            QRView(
              key: _qrKey,
              onQRViewCreated: _onCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppColors.primary,
                borderRadius: 12,
                borderLength: 28,
                borderWidth: 6,
                cutOutSize: 260,
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Point the camera at a QR code',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                    tooltip: 'Toggle torch',
                    onPressed: () => _controller?.toggleFlash(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    tooltip: 'Flip camera',
                    onPressed: () => _controller?.flipCamera(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
