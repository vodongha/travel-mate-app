import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/api_client.dart';
import 'google_auth_service.dart';

/// Real [GoogleAuthService] backed by the `google_sign_in` plugin (mobile). Passing [serverClientId]
/// (the project's **Web** OAuth client id) makes the returned ID token's `aud` equal that id, which
/// the backend verifies at `POST /auth/google`.
///
/// Web is intentionally not handled here: google_sign_in 7.x uses a rendered button on web (GIS),
/// so the provider keeps the stub for web (see `google_auth_service.dart`).
class GoogleSignInAuthService implements GoogleAuthService {
  GoogleSignInAuthService(this._serverClientId);

  final String _serverClientId;

  @override
  Future<String?> signInGetIdToken() async {
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    // Sign out first so Google always shows the account chooser instead of
    // silently re-using the last-selected account — otherwise a user with
    // several Google accounts on the device can't switch.
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;
      if (idToken == null) {
        throw ApiException('google-no-id-token', code: 'GOOGLE_NOT_CONFIGURED');
      }
      return idToken;
    } on GoogleSignInException catch (_) {
      return null; // user dismissed the account picker or cancelled
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
