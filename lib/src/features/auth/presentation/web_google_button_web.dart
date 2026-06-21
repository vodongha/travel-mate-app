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
    return Stack(
      children: [
        // Visual layer — matches the app's other buttons (and the mobile Google
        // button). Ignores pointers so taps fall through to the GIS button above.
        IgnorePointer(
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppTheme.buttonHeight),
            ),
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: Text(l10n.authGoogle),
          ),
        ),
        // Click layer — the real GIS button, stretched to fill the whole area and
        // made all-but-invisible (a hair above 0 so the DOM element stays
        // clickable). Tapping anywhere on the visible button hits it.
        Positioned.fill(
          child: Opacity(
            opacity: 0.01,
            child: LayoutBuilder(
              builder: (context, constraints) => FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: 40,
                  child: web.renderButton(
                    configuration: web.GSIButtonConfiguration(
                      theme: web.GSIButtonTheme.outline,
                      size: web.GSIButtonSize.large,
                      text: web.GSIButtonText.continueWith,
                      shape: web.GSIButtonShape.rectangular,
                      minimumWidth: constraints.maxWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget buildWebGoogleButton(Future<void> Function(String idToken) onIdToken) =>
    _WebGoogleButton(onIdToken: onIdToken);
