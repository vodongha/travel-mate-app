# Setup: FCM push & Google Sign-In

The app ships with the **framework** for push notifications and Google Sign-In wired up but
**inert** until you supply the Firebase / Google config. The backend is already complete
(`POST /auth/google`, `POST /users/me/devices`, FCM dispatch). This file lists exactly what to do
to switch the stubs for real implementations.

## What's already in place (no config needed)
- `auth_repository.googleLogin(idToken)` → `POST /auth/google` (full).
- `push_repository.registerDevice(fcmToken, platform)` → `POST /users/me/devices` (full).
- `AuthController.signInWithGoogle()` / push lifecycle on login/logout (full).
- "Continue with Google" button on the login & register screens.
- Integration points: `GoogleAuthService` (stub) and `PushService` (stub).

## 1. Create the Firebase project & apps
1. https://console.firebase.google.com → **Add project** (`travel-mate`).
2. **Add an Android app** → package = `applicationId` from `android/app/build.gradle`. Add the signing
   **SHA-1** (for Google Sign-In). Download **`google-services.json`** → `android/app/`.
3. **Add a Web app** → copy the `firebaseConfig` values. In **Cloud Messaging → Web Push
   certificates** → generate a **VAPID** key pair.
4. **Authentication → Sign-in method → Google → Enable**.
5. **Project Settings → Service accounts → Generate new private key** → JSON for the **backend**
   (FCM Admin SDK). Keep it secret; load via env var, never commit.

## 2. Google OAuth client id
- **Google Cloud Console → APIs & Services → Credentials**: copy the **Web client ID** (used as the
  app's `serverClientId` and for the backend to verify the ID token). Create an **Android** OAuth
  client (package + SHA-1) if one doesn't exist.

## 3. Wire the app
1. Add dependencies: `firebase_core`, `firebase_messaging`, `google_sign_in`.
2. Run `flutterfire configure` (generates `lib/firebase_options.dart`) and
   `Firebase.initializeApp(...)` in `main.dart`.
3. **Google**: replace `StubGoogleAuthService` in
   `lib/src/features/auth/data/google_auth_service.dart` with a real impl that uses `google_sign_in`
   and returns the ID token; pass the web client id via
   `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>` (read in `AppConfig.googleServerClientId`).
   On Web, add the client-id `<meta>` tag to `web/index.html`.
4. **FCM**: replace `StubPushService` in
   `lib/src/features/notifications/application/push_service.dart` with a real impl that requests
   notification permission, reads the token via `FirebaseMessaging.instance.getToken(...)` (Web needs
   the VAPID key), and calls `pushRepositoryProvider.registerDevice(fcmToken, 'ANDROID')`. Backend
   `DevicePlatform` is `ANDROID` / `IOS` only (no Web yet).

## 4. Build
- Android release: `flutter build appbundle --dart-define=GOOGLE_SERVER_CLIENT_ID=...`
- Web: `flutter build web --dart-define=GOOGLE_SERVER_CLIENT_ID=...`
