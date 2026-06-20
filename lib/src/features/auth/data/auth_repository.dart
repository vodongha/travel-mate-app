import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../domain/auth_user.dart';

/// The only place auth HTTP calls live. Returns domain objects; throws [ApiException] on failure.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login(String email, String password) async {
    return _session('/auth/login', {'email': email, 'password': password});
  }

  Future<AuthSession> register(
      String name, String email, String password) async {
    return _session(
        '/auth/register', {'name': name, 'email': email, 'password': password});
  }

  /// Exchanges a Google ID token (obtained client-side) for an app session
  /// (`POST /auth/google`). The backend verifies the token and links/creates the user.
  Future<AuthSession> googleLogin(String idToken) async {
    return _session('/auth/google', {'idToken': idToken});
  }

  Future<AuthUser> me() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>('/users/me');
      return AuthUser.fromJson(_data(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Updates the profile (name / phone / defaultCurrency). Only non-null fields
  /// are sent. Returns the refreshed user.
  Future<AuthUser> saveProfile({
    String? name,
    String? phone,
    String? defaultCurrency,
  }) async {
    final Map<String, dynamic> body = {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (defaultCurrency != null) 'defaultCurrency': defaultCurrency,
    };
    try {
      final Response<dynamic> res =
          await _dio.patch<dynamic>('/users/me', data: body);
      return AuthUser.fromJson(_data(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Changes the password, or sets the first one when [currentPassword] is null
  /// (an OAuth-only account with `hasPassword == false`). 204 on success.
  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    final Map<String, dynamic> body = {
      if (currentPassword != null) 'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
    try {
      await _dio.post<dynamic>('/auth/change-password', data: body);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Permanently deletes the signed-in account (204). The caller clears tokens.
  Future<void> deleteAccount() async {
    try {
      await _dio.delete<dynamic>('/users/me');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<AuthSession> _session(String path, Map<String, dynamic> body) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(path, data: body);
      return AuthSession.fromJson(_data(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Map<String, dynamic> _data(Response<dynamic> res) =>
      (res.data as Map)['data'] as Map<String, dynamic>;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
