import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api_client.dart';
import '../../../core/app_error.dart';
import '../application/auth_controller.dart';
import 'web_google_button_stub.dart'
    if (dart.library.js_interop) 'web_google_button_web.dart';

/// "Continue with Google" button + an "or" separator above it. Wired to
/// [AuthController.signInWithGoogle]; on success the router redirect navigates. While Google Sign-In
/// is not yet configured the underlying service is a stub that reports a friendly notice.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key, this.enabled = true});

  /// Disables the button while the surrounding form is submitting.
  final bool enabled;

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Web flow: the Google-rendered button supplies the ID token; exchange it for a session.
  Future<void> _onWebIdToken(String idToken) async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .exchangeGoogleIdToken(idToken);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String message =
        error is ApiException && error.code == 'GOOGLE_NOT_CONFIGURED'
            ? l10n.googleNotConfigured
            : friendlyError(context, error);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool on = widget.enabled && !_busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(l10n.authOr,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        if (kIsWeb)
          // Web must use Google's own rendered button (GIS); centre it under the divider.
          Align(child: buildWebGoogleButton(_onWebIdToken))
        else
          OutlinedButton.icon(
            onPressed: on ? _signIn : null,
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50)),
            icon: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4))
                : const Icon(Icons.g_mobiledata, size: 28),
            label: Text(l10n.authGoogle),
          ),
      ],
    );
  }
}
