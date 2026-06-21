import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_push_service.dart';

/// Owns the device-side push lifecycle: obtain the FCM token (`firebase_messaging`), ask the OS for
/// notification permission, and register the token with the backend (`POST /users/me/devices`) after
/// sign-in; clear it on logout.
///
/// Integration point: the real implementation needs `firebase_core` + `firebase_messaging` and the
/// Firebase config files (see `SETUP_FCM_GOOGLE.md`). Until then it is a no-op stub, so sign-in and
/// logout work normally — push simply doesn't fire yet. Swap [pushServiceProvider] to the real impl
/// once configured; the backend call lives in `PushRepository` and is already complete.
abstract class PushService {
  /// Best-effort: get this device's FCM token and register it. Safe to call after every sign-in.
  Future<void> registerCurrentDevice();

  /// Best-effort: drop this device's token (called on logout).
  Future<void> unregister();
}

class StubPushService implements PushService {
  const StubPushService();

  @override
  Future<void> registerCurrentDevice() async {}

  @override
  Future<void> unregister() async {}
}

final pushServiceProvider = Provider<PushService>((ref) {
  return FirebasePushService(ref);
});
