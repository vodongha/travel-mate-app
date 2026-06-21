import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';

/// Full-screen camera scanner that pops the first decoded QR string. Push it and await the result:
/// `final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const QrScanScreen()));`
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  MobileScannerController? _controller;
  bool _checking = true;
  bool _denied = false;
  // The real underlying camera error (not just "genericError"), shown so we can
  // see *why* it failed instead of masking everything as a permission problem.
  String? _error;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _checking = true;
      _denied = false;
      _error = null;
    });
    // Ask for the camera permission ourselves first (clear denied UI). On web the
    // browser handles its own prompt, so skip permission_handler there.
    if (!kIsWeb) {
      final PermissionStatus status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _checking = false;
            _denied = true;
          });
        }
        return;
      }
    }
    // Start the camera explicitly (autoStart off) so a start failure surfaces its
    // real exception here instead of a bare error inside the widget.
    final MobileScannerController controller = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    try {
      await controller.start();
    } catch (e) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _checking = false;
          _error = _describe(e);
        });
      }
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _checking = false;
    });
  }

  /// Flatten a scanner error into a human-readable line (code + native message).
  static String _describe(Object e) {
    if (e is MobileScannerException) {
      final MobileScannerErrorDetails? d = e.errorDetails;
      final String extra = d?.message ?? d?.details?.toString() ?? '';
      return extra.isEmpty ? e.errorCode.name : '${e.errorCode.name}: $extra';
    }
    return e.toString();
  }

  @override
  void dispose() {
    _controller?.dispose();
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
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : _denied
              ? _CameraProblem(l10n: l10n, onRetry: _init, permission: true)
              : _error != null
                  ? _CameraProblem(
                      l10n: l10n,
                      onRetry: _init,
                      permission: false,
                      detail: _error)
                  : _scanner(l10n),
    );
  }

  Widget _scanner(AppLocalizations l10n) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => _CameraProblem(
            l10n: l10n,
            onRetry: _init,
            permission: false,
            detail: _describe(error),
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
    );
  }
}

/// Shown when the camera can't be used. For a denied permission it explains how
/// to grant it; for any other failure it shows the real error so it can be
/// reported, plus a retry.
class _CameraProblem extends StatelessWidget {
  const _CameraProblem({
    required this.l10n,
    required this.onRetry,
    required this.permission,
    this.detail,
  });

  final AppLocalizations l10n;
  final Future<void> Function() onRetry;
  final bool permission;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 48),
            const SizedBox(height: 16),
            Text(permission ? l10n.qrCameraPermission : l10n.qrCameraError,
                textAlign: TextAlign.center),
            if (!permission && detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('($detail)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.actionRetry),
                ),
                FilledButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l10n.openSettings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
