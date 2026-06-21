import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'form_buttons.dart';
import 'qr_scan_screen.dart';

/// Shows a stored QR string as a regenerated QR code (SPEC §2.7 — we never store the image). Any
/// trip member can open this to view a ticket's QR.
Future<void> showQrDialog(BuildContext context, String data) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: QrImageView(
                data: data, size: 220, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 16),
          SelectableText(data,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: data));
              ScaffoldMessenger.of(ctx)
                  .showSnackBar(SnackBar(content: Text(l10n.actionCopied)));
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.actionCopy),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionClose)),
      ],
    ),
  );
}

/// A form field for a ticket's QR string: shows the saved value (or a hint), with buttons to scan
/// it from the camera, preview it, or clear it. The value is the decoded string — never an image.
class QrField extends StatelessWidget {
  const QrField({super.key, required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool has = value != null && value!.isNotEmpty;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.qrTicket,
        prefixIcon: const Icon(Icons.qr_code_2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              has ? value! : l10n.qrEmpty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: has
                  ? null
                  : TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          if (has)
            IconButton(
              tooltip: l10n.qrView,
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () => showQrDialog(context, value!),
            ),
          IconButton(
            tooltip: l10n.qrScan,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              final String? code = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const QrScanScreen()),
              );
              if (code != null && code.isNotEmpty) {
                onChanged(code);
              }
            },
          ),
          // Manual type/paste — works everywhere (and the fallback when the camera
          // or web scanner isn't available).
          IconButton(
            tooltip: l10n.qrEnterManually,
            icon: const Icon(Icons.keyboard_outlined),
            onPressed: () async {
              final String? code = await showDialog<String>(
                context: context,
                builder: (_) => _QrManualDialog(initial: value),
              );
              if (code != null) {
                onChanged(code.isEmpty ? null : code);
              }
            },
          ),
          if (has)
            IconButton(
              tooltip: l10n.actionRemove,
              icon: const Icon(Icons.clear),
              onPressed: () => onChanged(null),
            ),
        ],
      ),
    );
  }
}

/// Type/paste the decoded QR string by hand — the fallback when scanning isn't available (e.g. web
/// without camera access). Returns the entered string, or null on cancel.
class _QrManualDialog extends StatefulWidget {
  const _QrManualDialog({this.initial});

  final String? initial;

  @override
  State<_QrManualDialog> createState() => _QrManualDialogState();
}

class _QrManualDialogState extends State<_QrManualDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.qrEnterManually),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(labelText: l10n.qrTicket),
          ),
          const SizedBox(height: 20),
          FormButtons(
            primaryLabel: l10n.actionSave,
            onPrimary: () => Navigator.pop(context, _controller.text.trim()),
            onCancel: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
