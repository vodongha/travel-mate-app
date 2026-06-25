import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'token_storage.dart';

/// Thrown by repositories for any non-2xx response, carrying a user-facing message extracted from
/// the backend's RFC 7807 problem (`error.detail`) when present.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.isConnection = false,
    this.isTimeout = false,
    this.serverDetail = false,
  });

  final String message;
  final int? statusCode;

  /// The backend error `code` (e.g. `VALIDATION_FAILED`, `UNAUTHENTICATED`), when present.
  final String? code;

  /// True when the request never reached the server (offline / DNS / connection refused).
  final bool isConnection;

  /// True when the request reached the network but the server didn't answer in time.
  final bool isTimeout;

  /// True when [message] is a meaningful server-supplied reason (problem `detail`); when false the
  /// UI shows a localized generic message instead of this developer-facing fallback.
  final bool serverDetail;

  @override
  String toString() => message;
}

/// Turns a Dio failure into an [ApiException], reading the `{ data, error, meta }` envelope.
ApiException toApiException(Object error) {
  if (error is DioException) {
    final int? status = error.response?.statusCode;
    final dynamic data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final Map<dynamic, dynamic> problem =
          data['error'] as Map<dynamic, dynamic>;
      final Object? detail = problem['detail'] ?? problem['title'];
      if (detail != null && status != null && status >= 400 && status < 500) {
        return ApiException(
          detail.toString(),
          statusCode: status,
          code: problem['code']?.toString(),
          serverDetail: true,
        );
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException('timeout', isTimeout: true);
    }
    if (error.type == DioExceptionType.connectionError) {
      return ApiException('connection-error', isConnection: true);
    }
    return ApiException('request-failed', statusCode: status);
  }
  return ApiException('request-failed');
}

/// A single configured [Dio] for the whole app: it prefixes `/api/v1`, attaches the bearer token,
/// and transparently refreshes it once on a 401 (rotating refresh token), retrying the request.
final dioProvider = Provider<Dio>((ref) {
  final TokenStorage storage = ref.watch(tokenStorageProvider);

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ),
  );

  // A bare client (no interceptors) for the refresh call, so refreshing can't recurse.
  final Dio refresher = Dio(BaseOptions(baseUrl: dio.options.baseUrl));

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final String? token = await storage.readAccess();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final RequestOptions request = error.requestOptions;
        final bool isAuthCall = request.path.startsWith('/auth/');
        final bool alreadyRetried = request.extra['retried'] == true;
        if (error.response?.statusCode != 401 || isAuthCall || alreadyRetried) {
          return handler.next(error);
        }
        final String? refresh = await storage.readRefresh();
        if (refresh == null || refresh.isEmpty) {
          return handler.next(error);
        }
        try {
          final Response<dynamic> res = await refresher.post<dynamic>(
            '/auth/refresh',
            data: {'refreshToken': refresh},
          );
          final Map<dynamic, dynamic> tokens =
              (res.data as Map)['data'] as Map<dynamic, dynamic>;
          await storage.save(
            access: tokens['accessToken'].toString(),
            refresh: tokens['refreshToken'].toString(),
          );
          request.extra['retried'] = true;
          request.headers['Authorization'] = 'Bearer ${tokens['accessToken']}';
          final Response<dynamic> retried = await dio.fetch<dynamic>(request);
          return handler.resolve(retried);
        } on DioException catch (refreshError) {
          // Only treat the session as dead when the server actually *rejects* the refresh token
          // (a 4xx response). A transient failure (offline, timeout, 5xx, server cold-start) must
          // NOT clear the tokens — otherwise a brief network blip silently logs the user out.
          final int? status = refreshError.response?.statusCode;
          if (status != null && status >= 400 && status < 500) {
            await storage.clear();
          }
          return handler.next(error);
        }
      },
    ),
  );

  return dio;
});
