import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/token_storage.dart';
import '../../notifications/application/push_service.dart';
import '../data/auth_repository.dart';
import '../data/google_auth_service.dart';
import '../domain/auth_user.dart';

/// Holds the session as `AsyncValue<AuthUser?>` (null = signed out). On startup it resolves the
/// stored token to a user (the Dio interceptor refreshes a stale access token transparently); a
/// failure clears the tokens and lands signed-out. The router watches this to guard routes.
class AuthController extends AsyncNotifier<AuthUser?> {
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  GoogleAuthService get _google => ref.read(googleAuthServiceProvider);
  PushService get _push => ref.read(pushServiceProvider);

  @override
  Future<AuthUser?> build() async {
    final String? access = await _storage.readAccess();
    if (access == null || access.isEmpty) {
      return null;
    }
    try {
      return await _repo.me();
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final AuthSession session = await _repo.login(email.trim(), password);
    await _persist(session);
  }

  Future<void> register(String name, String email, String password) async {
    final AuthSession session =
        await _repo.register(name.trim(), email.trim(), password);
    await _persist(session);
  }

  /// Signs in with Google (mobile): gets an ID token from the device, exchanges it at `/auth/google`.
  /// Does nothing if the user cancels the Google account picker.
  Future<void> signInWithGoogle() async {
    final String? idToken = await _google.signInGetIdToken();
    if (idToken == null) {
      return;
    }
    await exchangeGoogleIdToken(idToken);
  }

  /// Exchanges an already-obtained Google ID token for an app session. Used by the web sign-in flow,
  /// where the token comes from the Google-rendered button rather than an imperative call.
  Future<void> exchangeGoogleIdToken(String idToken) async {
    final AuthSession session = await _repo.googleLogin(idToken);
    await _persist(session);
  }

  Future<void> logout() async {
    // Best-effort cleanup; never block sign-out on these.
    try {
      await _push.unregister();
    } catch (_) {}
    try {
      await _google.signOut();
    } catch (_) {}
    await _storage.clear();
    state = const AsyncData(null);
  }

  /// Re-fetches the signed-in user from `/users/me` and updates the session.
  Future<void> refreshUser() async {
    final AuthUser user = await _repo.me();
    state = AsyncData(user);
  }

  /// Saves profile fields (name / phone / defaultCurrency) and updates state.
  /// Pass an empty string for [phone] to clear it; null leaves it untouched.
  Future<void> saveProfile({
    String? name,
    String? phone,
    String? defaultCurrency,
  }) async {
    final AuthUser user = await _repo.saveProfile(
      name: name,
      phone: phone,
      defaultCurrency: defaultCurrency,
    );
    state = AsyncData(user);
  }

  /// Changes (or sets, when [currentPassword] is null) the account password.
  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    // hasPassword may have flipped from false → true; reflect it.
    final AuthUser? current = state.valueOrNull;
    if (current != null && !current.hasPassword) {
      try {
        await refreshUser();
      } catch (_) {
        // Non-fatal: the password change itself succeeded.
      }
    }
  }

  /// Deletes the account on the server, then clears the local session.
  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    await _storage.clear();
    state = const AsyncData(null);
  }

  Future<void> _persist(AuthSession session) async {
    await _storage.save(
        access: session.accessToken, refresh: session.refreshToken);
    state = AsyncData(session.user);
    // Best-effort: register this device for push. No-op until FCM is configured.
    try {
      await _push.registerCurrentDevice();
    } catch (_) {}
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);
