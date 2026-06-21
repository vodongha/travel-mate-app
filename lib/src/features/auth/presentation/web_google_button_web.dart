import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import '../../../../l10n/app_localizations.dart';
import '../../../core/config.dart';
import '../../../core/theme.dart';

/// Google Sign-In on web uses Google Identity Services, which only works through a Google-rendered
/// button (there is no imperative `signIn()` on web). This widget renders that button and, when the
/// user picks an account, hands the resulting ID token (its `aud` is the web client id) to
/// [onIdToken] for exchange at `/auth/google`.
class _WebGoogleButton extends StatefulWidget {
  const _WebGoogleButton({required this.onIdToken});

  final Future<void> Function(String idToken) onIdToken;

  @override
  State<_WebGoogleButton> createState() => _WebGoogleButtonState();
}

class _WebGoogleButtonState extends State<_WebGoogleButton> {
  late final GoogleSignIn _google = GoogleSignIn(
    clientId: AppConfig.googleServerClientId,
    scopes: const ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _google.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account == null) {
        return;
      }
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      if (idToken != null && idToken.isNotEmpty) {
        await widget.onIdToken(idToken);
      }
    });
    // Deliberately NO signInSilently() here: it would silently log the user in
    // with whatever Google account is already in the browser session, with no
    // chance to pick another. The user must click the button to choose.
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // Google Identity Services (web) only signs in through ITS OWN rendered button, which can't be
    // restyled to match the app. So we draw the app's own Google button (identical to the mobile
    // OutlinedButton) and lay the real GIS button on top, fully transparent — on web it's a DOM
    // element above the Flutter canvas, so it still receives the click and runs the sign-in flow.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        return SizedBox(
          height: AppTheme.buttonHeight,
          width: width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // What the user sees — matches the rest of the app's buttons.
              Positioned.fill(
                child: IgnorePointer(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppTheme.buttonHeight),
                    ),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: Text(l10n.authGoogle),
                  ),
                ),
              ),
              // The real (invisible) GIS button that actually handles the click.
              Opacity(
                opacity: 0.0,
                child: web.renderButton(
                  configuration: web.GSIButtonConfiguration(
                    theme: web.GSIButtonTheme.outline,
                    size: web.GSIButtonSize.large,
                    text: web.GSIButtonText.continueWith,
                    shape: web.GSIButtonShape.rectangular,
                    minimumWidth: width,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget buildWebGoogleButton(Future<void> Function(String idToken) onIdToken) =>
    _WebGoogleButton(onIdToken: onIdToken);
