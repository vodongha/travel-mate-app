import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/form_buttons.dart';
import '../../../core/responsive.dart';
import '../../trips/application/trips_controller.dart';
import '../data/member_repository.dart';
import '../domain/member.dart';

/// Join a trip by pasting an invite link or code. A scanned link contains `?token=…`; we accept
/// either the full link or the bare token. (Camera scanning lands in a later slice.)
class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  late final TextEditingController _input =
      TextEditingController(text: widget.token ?? '');
  bool _joining = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _extractToken(String raw) {
    final String value = raw.trim();
    final Uri? uri = Uri.tryParse(value);
    if (uri != null && uri.queryParameters['token'] != null) {
      return uri.queryParameters['token']!;
    }
    return value;
  }

  Future<void> _join() async {
    final String token = _extractToken(_input.text);
    if (token.isEmpty) {
      return;
    }
    setState(() => _joining = true);
    try {
      final AcceptResult result =
          await ref.read(memberRepositoryProvider).accept(token);
      ref.invalidate(tripsControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).inviteJoinedSnack)),
        );
        context.go('/trips/${result.tripRid}');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    } finally {
      if (mounted) {
        setState(() => _joining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteJoinTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 460,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _input,
                decoration: InputDecoration(
                  labelText: l10n.inviteCodeLabel,
                  prefixIcon: const Icon(Icons.link),
                ),
                onSubmitted: (_) => _join(),
              ),
              const SizedBox(height: 24),
              FormButtons(
                primaryLabel: l10n.actionJoin,
                loading: _joining,
                onPrimary: _join,
                onCancel: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
