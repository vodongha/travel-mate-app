import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/responsive.dart';
import '../../trips/presentation/trip_format.dart';
import '../data/member_repository.dart';
import '../domain/member.dart';

/// Create an invitation and show it as a QR + link. We render the QR from the link string on the
/// fly (SPEC §2.7 — never store a QR image).
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, required this.tripRid});

  final String tripRid;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  String _role = 'VIEWER';
  int _maxUses = 5;
  bool _creating = false;
  Invitation? _invitation;

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      final Invitation inv = await ref
          .read(memberRepositoryProvider)
          .createInvitation(widget.tripRid, _role, _maxUses);
      setState(() => _invitation = inv);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _copy(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Invitation? inv = _invitation;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 460,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (inv == null) ...[
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration:
                      InputDecoration(labelText: l10n.inviteRoleToGrant),
                  items: [
                    DropdownMenuItem(
                        value: 'VIEWER',
                        child: Text(roleLabel(context, 'VIEWER'))),
                    DropdownMenuItem(
                        value: 'EDITOR',
                        child: Text(roleLabel(context, 'EDITOR'))),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'VIEWER'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _maxUses,
                  decoration: InputDecoration(labelText: l10n.inviteMaxUses),
                  items: const [1, 5, 10, 25, 100]
                      .map((n) =>
                          DropdownMenuItem<int>(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (v) => setState(() => _maxUses = v ?? 5),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _creating ? null : _create,
                  icon: _creating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4))
                      : const Icon(Icons.qr_code_2),
                  label: Text(l10n.inviteTitle),
                ),
              ] else
                _InviteResult(
                    invitation: inv, onCopy: () => _copy(inv.inviteUrl)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteResult extends StatelessWidget {
  const _InviteResult({required this.invitation, required this.onCopy});

  final Invitation invitation;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.inviteShareHint,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: invitation.inviteUrl,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n.inviteLinkLabel,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
        const SizedBox(height: 4),
        SelectableText(invitation.inviteUrl),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy),
          label: Text(l10n.actionCopy),
        ),
      ],
    );
  }
}
