/// App-wide configuration resolved at build time.
///
/// The API base URL is supplied with `--dart-define=API_BASE_URL=...`. The default targets a local
/// backend for web / iOS simulator (`http://localhost:8000`). From an **Android emulator** use
/// `--dart-define=API_BASE_URL=http://10.0.2.2:8000` (10.0.2.2 maps to the host's localhost); for a
/// physical device use the host LAN IP; in production point it at the deployed backend.
///
/// The production **web** client is served by the backend on the same origin, so it's built with
/// `--dart-define=SAME_ORIGIN=true` and uses relative URLs — it then works on any host (the
/// fly.dev URL and trippo.io.vn alike) with no CORS. Mobile builds pass an absolute API_BASE_URL.
class AppConfig {
  const AppConfig._();

  /// When true, call the API on the same origin that served the app (relative URLs). Set for the
  /// production web build.
  static const bool sameOrigin = bool.fromEnvironment('SAME_ORIGIN');

  static String get apiBaseUrl => sameOrigin
      ? ''
      : const String.fromEnvironment('API_BASE_URL',
          defaultValue: 'http://localhost:8000');

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
    // The project's **Web** OAuth client ID — public (it ships to clients) so it's a safe default.
    // The Google ID token's `aud` equals this; the backend must verify against the SAME id
    // (env `GOOGLE_CLIENT_ID`).
    defaultValue:
        '542406829306-4f37t1brg750jdoksjidh197hkbopnuj.apps.googleusercontent.com',
  );

  /// Whether Google Sign-In is wired up (a client id was provided at build time).
  static bool get googleSignInEnabled => googleServerClientId.isNotEmpty;

  /// Web Push (VAPID) **public** key — required by `getToken` on web only. Must be the key pair from
  /// Firebase Console → Cloud Messaging → Web Push certificates. Empty = web push disabled.
  static const String webPushVapidKey = String.fromEnvironment(
    'WEB_PUSH_VAPID_KEY',
    defaultValue:
        'BFzFkKDu8m8Z5p1xJCI23CYsh0v4KlJMdgH3y60lbpprUJwGclR-DOn8wYxVS_bCSisHK5iwbQ4fR4hMtWfOzoA',
  );

  /// The backend-served, bilingual privacy policy (LegalController). [lang] is `vi` or `en`.
  static String privacyUrl(String lang) =>
      '$apiBaseUrl$apiPrefix/privacy?lang=${lang == 'en' ? 'en' : 'vi'}';
}
