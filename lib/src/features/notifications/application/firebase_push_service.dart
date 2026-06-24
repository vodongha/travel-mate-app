import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config.dart';
import '../../../core/prefs.dart';
import '../data/push_repository.dart';
import 'push_service.dart';

/// Real [PushService] backed by `firebase_messaging`: requests permission, reads the FCM token, and
/// registers it with the backend (`POST /users/me/devices`); re-registers on token refresh.
///
/// Backend `DevicePlatform` is ANDROID/IOS only, so web/desktop are intentionally skipped (no token
/// is sent) until the backend supports web push.
class FirebasePushService implements PushService {
  FirebasePushService(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _refreshSub;

  PushRepository get _repo => _ref.read(pushRepositoryProvider);

  /// Backend platform string for the current device, or null if unsupported (web/desktop).
  String? _platform() {
    if (kIsWeb) {
      return null;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      default:
        return null;
    }
  }

  @override
  Future<void> registerCurrentDevice() async {
    final String? platform = _platform();
    if (platform == null) {
      return; // unsupported platform — backend has no token type for it
    }
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }
    final String? token = kIsWeb
        ? await messaging.getToken(vapidKey: AppConfig.webPushVapidKey)
        : await messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    final String locale = _localeCode();
    await _repo.registerDevice(
        fcmToken: token, platform: platform, locale: locale);
    _refreshSub ??= messaging.onTokenRefresh.listen((String fresh) {
      _repo
          .registerDevice(
              fcmToken: fresh, platform: platform, locale: _localeCode())
          .catchError((Object _) {});
    });
  }

  /// The language to localize push in: the user's chosen app language, or the device's when they
  /// haven't picked one ("follow the system"). The backend falls back to English for anything else.
  String _localeCode() {
    final ui.Locale? chosen = _ref.read(localeControllerProvider);
    return chosen?.languageCode ??
        ui.PlatformDispatcher.instance.locale.languageCode;
  }

  @override
  Future<void> unregister() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}
