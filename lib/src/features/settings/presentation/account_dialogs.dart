import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/form_buttons.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';

/// Shared account actions used by both the avatar menu and the Settings screen. (Edit profile is its
/// own screen now — see EditProfileScreen.)

Future<void> showChangePassword(BuildContext context, WidgetRef ref) async {
  final AuthUser? user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) {
    return;
  }
  final _PasswordResult? result = await showDialog<_PasswordResult>(
    context: context,
    builder: (_) => _ChangePasswordDialog(hasPassword: user.hasPassword),
  );
  if (result == null) {
    return;
  }
  try {
    await ref.read(authControllerProvider.notifier).changePassword(
          currentPassword: result.current,
          newPassword: result.next,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).settingsPasswordChanged)));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(context, error))));
    }
  }
}

Future<void> confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  if (!await confirmDelete(context, message: l10n.settingsDeleteConfirm) ||
      !context.mounted) {
    return;
  }
  try {
    await ref.read(authControllerProvider.notifier).deleteAccount();
    // Signed out → the router redirects to /login.
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(context, error))));
    }
  }
}

Future<void> openExternal(BuildContext context, String url) async {
  final bool ok =
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).settingsOpenFailed)));
  }
}

/// Opens [url] in an in-app WebView on mobile (the `/web` route shows
/// [WebPageScreen]); on web an external site can't be reliably iframed, so it
/// opens in a new browser tab instead. Mirrors family-budget-app.
Future<void> openWebPage(BuildContext context, String title, String url) async {
  if (kIsWeb) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String failMsg = AppLocalizations.of(context).settingsOpenFailed;
    final bool ok =
        await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(failMsg)));
    }
  } else {
    context.push('/web', extra: WebPageArgs(title: title, url: url));
  }
}

/// Route arguments for the in-app WebView page.
class WebPageArgs {
  const WebPageArgs({required this.title, required this.url});
  final String title;
  final String url;
}

// ── dialogs ──────────────────────────────────────────────────────────────────

class _PasswordResult {
  const _PasswordResult(this.current, this.next);
  final String? current;
  final String next;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.hasPassword});
  final bool hasPassword;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.hasPassword
          ? l10n.settingsChangePassword
          : l10n.settingsSetPassword),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.hasPassword) ...[
                TextFormField(
                  controller: _current,
                  obscureText: true,
                  decoration:
                      InputDecoration(labelText: l10n.settingsCurrentPassword),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.validationRequired : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _next,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: l10n.settingsNewPassword),
                validator: (v) => (v == null || v.length < 8)
                    ? l10n.validationPasswordShort
                    : null,
              ),
              const SizedBox(height: 20),
              FormButtons(
                primaryLabel: l10n.actionSave,
                onPrimary: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      _PasswordResult(widget.hasPassword ? _current.text : null,
                          _next.text),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
