import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';
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
