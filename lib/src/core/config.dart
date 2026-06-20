/// App-wide configuration resolved at build time.
///
/// The API base URL is supplied with `--dart-define=API_BASE_URL=...`. The default targets a local
/// backend for web / iOS simulator (`http://localhost:8000`). From an **Android emulator** use
/// `--dart-define=API_BASE_URL=http://10.0.2.2:8000` (10.0.2.2 maps to the host's localhost); for a
/// physical device use the host LAN IP; in production point it at the deployed backend.
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// API base path — every endpoint is nested under this (backend SPEC §4).
  static const String apiPrefix = '/api/v1';

  /// Community & support forum, opened from Settings.
  static const String communityUrl = 'https://vodongha.forumvi.com';

  /// Google OAuth **Web client ID** (from Google Cloud → Credentials). Required for Google Sign-In:
  /// on web it is the client id; on Android it is the `serverClientId` so the backend can verify the
  /// returned ID token. Supply with `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`. Empty = Google
  /// Sign-In disabled (the button reports "not configured").
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Whether Google Sign-In is wired up (a client id was provided at build time).
  static bool get googleSignInEnabled => googleServerClientId.isNotEmpty;

  /// The backend-served, bilingual privacy policy (LegalController). [lang] is `vi` or `en`.
  static String privacyUrl(String lang) =>
      '$apiBaseUrl$apiPrefix/privacy?lang=${lang == 'en' ? 'en' : 'vi'}';
}
