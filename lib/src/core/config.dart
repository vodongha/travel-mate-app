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
}
