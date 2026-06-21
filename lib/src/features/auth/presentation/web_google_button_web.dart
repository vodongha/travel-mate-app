import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

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
    // The GIS button is Google-rendered, so we can't fully restyle it — but we make it full-width,
    // clip it to the app's shared button radius (14), and reserve the same 50px row height as the
    // app's other buttons (FormButtons / OutlinedButton) so it lines up with them. Both GIS states
    // — the generic "Continue with Google" and the personalised "Continue as <name>" — render the
    // same way here.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        return SizedBox(
          height: AppTheme.buttonHeight,
          width: width,
          child: Center(
            child: ClipRRect(
              borderRadius: AppTheme.buttonRadius,
              child: web.renderButton(
                configuration: web.GSIButtonConfiguration(
                  theme: web.GSIButtonTheme.outline,
                  size: web.GSIButtonSize.large,
                  text: web.GSIButtonText.continueWith,
                  shape: web.GSIButtonShape.rectangular,
                  logoAlignment: web.GSIButtonLogoAlignment.left,
                  minimumWidth: width,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget buildWebGoogleButton(Future<void> Function(String idToken) onIdToken) =>
    _WebGoogleButton(onIdToken: onIdToken);
