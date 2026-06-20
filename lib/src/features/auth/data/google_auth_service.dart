import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// Obtains a Google **ID token** from the device's Google account, to be exchanged for an app
/// session at `POST /auth/google`.
///
/// Integration point: the real implementation uses the `google_sign_in` package together with
/// [AppConfig.googleServerClientId]. Until the Firebase/Google config is supplied it stays a stub
/// (see `SETUP_FCM_GOOGLE.md`) — swap [googleAuthServiceProvider] to return the real impl then.
abstract class GoogleAuthService {
  /// Returns the Google ID token, or `null` if the user cancelled the account picker.
  Future<String?> signInGetIdToken();

  /// Clears the cached Google session (best-effort; called on logout).
  Future<void> signOut();
}

/// Inert placeholder used until Google Sign-In is configured. Tapping the button surfaces a
/// friendly "not configured" message rather than crashing.
class StubGoogleAuthService implements GoogleAuthService {
  const StubGoogleAuthService();

  @override
  Future<String?> signInGetIdToken() async {
    throw ApiException('google-not-configured', code: 'GOOGLE_NOT_CONFIGURED');
  }

  @override
  Future<void> signOut() async {}
}

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  // TODO(config): once `google_sign_in` is added and GOOGLE_SERVER_CLIENT_ID is supplied, return the
  // real implementation, e.g.:
  //   return GoogleSignInAuthService(serverClientId: AppConfig.googleServerClientId);
  return const StubGoogleAuthService();
});
