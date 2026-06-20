import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import '../../../core/config.dart';

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
    // Attempt a silent restore so a returning user is recognised without clicking.
    _google.signInSilently();
  }

  @override
  Widget build(BuildContext context) => web.renderButton();
}

Widget buildWebGoogleButton(Future<void> Function(String idToken) onIdToken) =>
    _WebGoogleButton(onIdToken: onIdToken);
