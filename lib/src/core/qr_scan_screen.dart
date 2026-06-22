import 'dart:math' as math;

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

class _QrScanScreenState extends State<QrScanScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _checking = true;
  bool _denied = false;
  bool _handled = false;

  // Drives the sweeping scan line inside the framing window.
  late final AnimationController _scanCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final Animation<double> _scan =
      CurvedAnimation(parent: _scanCtl, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _checking = true;
      _denied = false;
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
    // Create the controller with autoStart (the default): the MobileScanner
    // widget attaches it and calls start() once it's built. We must NOT call
    // start() ourselves before the widget exists — mobile_scanner throws
    // "controllerNotAttached" in that case. A start failure (e.g. a real camera
    // error) surfaces through the widget's errorBuilder below.
    if (mounted) {
      setState(() {
        _controller = MobileScannerController(
          formats: const [BarcodeFormat.qrCode],
          detectionSpeed: DetectionSpeed.noDuplicates,
        );
        _checking = false;
      });
    }
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
    _scanCtl.dispose();
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
              : _scanner(l10n),
    );
  }

  Widget _scanner(AppLocalizations l10n) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        // A centred 1:1 framing window, sized to the viewport.
        final double side =
            (math.min(constraints.maxWidth, constraints.maxHeight) * 0.72)
                .clamp(220.0, 340.0);
        final Rect window = Rect.fromCenter(
          center:
              Offset(constraints.maxWidth / 2, constraints.maxHeight / 2 - 24),
          width: side,
          height: side,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) => _CameraProblem(
                  l10n: l10n,
                  onRetry: _init,
                  permission: false,
                  detail: _describe(error),
                ),
              ),
            ),
            // Opaque app background everywhere except the window + corner
            // brackets — so the camera only shows inside the 1:1 frame.
            Positioned.fill(
              child: CustomPaint(
                painter: _FramePainter(
                  window,
                  accent,
                  Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
            // Sweeping, glowing scan line.
            AnimatedBuilder(
              animation: _scan,
              builder: (context, _) {
                final double y =
                    window.top + 6 + _scan.value * (window.height - 12);
                return Positioned(
                  left: window.left + 14,
                  width: window.width - 28,
                  top: y,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(colors: [
                        accent.withValues(alpha: 0),
                        accent,
                        accent.withValues(alpha: 0),
                      ]),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.7),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Hint just below the window.
            Positioned(
              top: window.bottom + 28,
              left: 24,
              right: 24,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(l10n.qrScanHint,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Paints the dim overlay with a transparent rounded-square cutout (the framing
/// window) and a bright corner bracket at each corner.
class _FramePainter extends CustomPainter {
  _FramePainter(this.window, this.accent, this.background);

  final Rect window;
  final Color accent;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 22;
    final RRect hole =
        RRect.fromRectAndRadius(window, const Radius.circular(radius));

    // Cover everything outside the window with the opaque app background, so the
    // camera preview is only visible through the 1:1 window.
    final Path mask = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(hole),
    );
    canvas.drawPath(mask, Paint()..color = background);

    // A faint outline around the window.
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white24,
    );

    // Corner brackets.
    final Paint p = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const double arm = 30; // length of each bracket arm
    const double r = radius; // follow the window's rounded corners
    final Rect w = window;

    // Two straight arms per corner, offset inward by the corner radius.
    void drawCorner(Offset c, double sx, double sy) {
      final double bx = c.dx + sx * r;
      final double by = c.dy + sy * r;
      canvas.drawLine(Offset(bx, by), Offset(bx + sx * arm, by), p);
      canvas.drawLine(Offset(bx, by), Offset(bx, by + sy * arm), p);
    }

    drawCorner(w.topLeft, 1, 1);
    drawCorner(w.topRight, -1, 1);
    drawCorner(w.bottomLeft, 1, -1);
    drawCorner(w.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.window != window ||
      old.accent != accent ||
      old.background != background;
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
