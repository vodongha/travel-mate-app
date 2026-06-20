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

  Future<AuthUser> me() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>('/users/me');
      return AuthUser.fromJson(_data(res));
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
