import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// Registers (or refreshes) the signed-in user's FCM push token for this device
/// (`POST /users/me/devices`). [platform] is the backend `DevicePlatform` enum — `ANDROID` or `IOS`
/// (web push is not yet supported by the backend).
class PushRepository {
  PushRepository(this._dio);

  final Dio _dio;

  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
    String? locale,
  }) async {
    try {
      await _dio.post<dynamic>('/users/me/devices', data: {
        'fcmToken': fcmToken,
        'platform': platform,
        if (locale != null && locale.isNotEmpty) 'locale': locale,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final pushRepositoryProvider = Provider<PushRepository>((ref) {
  return PushRepository(ref.watch(dioProvider));
});
