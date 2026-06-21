import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../l10n/app_localizations.dart';
import '../data/ticket_repository.dart';
import 'ticket_format.dart';

/// Full-screen QR a member shows at the gate. The `qrData` string is regenerated as a QR with
/// `qr_flutter` (SPEC §2.7 — never an image). The QR sits on a forced light/white surface so it
/// stays scannable even when the app is in dark mode.
class TicketQrScreen extends StatelessWidget {
  const TicketQrScreen({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String data = ticket.qrData ?? '';
    final bool hasQr = data.isNotEmpty;
    return Scaffold(
      // Force a light scaffold so the gate scanner sees high contrast regardless of theme.
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text(
          ticket.title.isEmpty ? l10n.ticketUntitled : ticket.title,
          style: const TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasQr)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double size = constraints.maxWidth.isFinite
                            ? constraints.maxWidth.clamp(180.0, 320.0)
                            : 280.0;
                        // QrImageView defaults to black modules on white —
                        // exactly the high contrast a gate scanner needs.
                        return QrImageView(
                          data: data,
                          size: size,
                          backgroundColor: Colors.white,
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.qrEmpty,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  ticket.title.isEmpty ? l10n.ticketUntitled : ticket.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ticketTypeLabel(context, ticket.ticketType),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                ),
                if (ticket.memberName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ticket.memberName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
                if (ticket.note?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  Text(
                    ticket.note!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
