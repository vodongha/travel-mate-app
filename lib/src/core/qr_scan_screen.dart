import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/app_localizations.dart';

/// Full-screen camera scanner that pops the first decoded QR string. Push it and await the result:
/// `final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const QrScanScreen()));`
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  // An explicit controller (auto-starts the camera + requests permission) and a dispose, so the
  // camera reliably opens/closes across pushes — and errorBuilder surfaces why if it can't.
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) {
      return;
    }
    final String? code = capture.barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      _handled = true;
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrScan)),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(l10n.qrCameraError, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('(${error.errorCode.name})',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(l10n.qrScanHint,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
