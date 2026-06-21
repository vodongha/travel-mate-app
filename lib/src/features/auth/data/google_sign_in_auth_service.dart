import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/api_client.dart';
import 'google_auth_service.dart';

/// Real [GoogleAuthService] backed by the `google_sign_in` plugin (mobile). Passing [serverClientId]
/// (the project's **Web** OAuth client id) makes the returned ID token's `aud` equal that id, which
/// the backend verifies at `POST /auth/google`.
///
/// Web is intentionally not handled here: `google_sign_in` 6.x cannot do a programmatic `signIn()`
/// on web (it requires a rendered button), and constructing it with a `serverClientId` asserts on
/// web — so the provider keeps the stub for web (see `google_auth_service.dart`).
class GoogleSignInAuthService implements GoogleAuthService {
  GoogleSignInAuthService(String serverClientId)
      : _google = GoogleSignIn(
          scopes: const ['email', 'profile'],
          serverClientId: serverClientId,
        );

  final GoogleSignIn _google;

  @override
  Future<String?> signInGetIdToken() async {
    // Sign out first so Google always shows the account chooser instead of
    // silently re-using the last-selected account — otherwise a user with
    // several Google accounts on the device can't switch.
    try {
      await _google.signOut();
    } catch (_) {
      // Not signed in yet, or the plugin is unavailable — ignore.
    }
    final GoogleSignInAccount? account = await _google.signIn();
    if (account == null) {
      return null; // user dismissed the account picker
    }
    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;
    if (idToken == null) {
      throw ApiException('google-no-id-token', code: 'GOOGLE_NOT_CONFIGURED');
    }
    return idToken;
  }

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
  }
}
