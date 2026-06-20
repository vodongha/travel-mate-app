import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../domain/member.dart';

/// Members + invitations HTTP. Returns domain objects; throws [ApiException] on failure.
class MemberRepository {
  MemberRepository(this._dio);

  final Dio _dio;

  Future<List<Member>> list(String tripRid) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/trips/$tripRid/members');
      final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
      return data
          .map((e) => Member.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Member> addGhost(
      String tripRid, String displayName, String role) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/trips/$tripRid/members',
        data: {'displayName': displayName, 'role': role},
      );
      return Member.fromJson(_data(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> remove(String tripRid, String memberRid) async {
    try {
      await _dio.delete<dynamic>('/trips/$tripRid/members/$memberRid');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Invitation> createInvitation(
      String tripRid, String role, int maxUses) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/trips/$tripRid/invitations',
        data: {'role': role, 'maxUses': maxUses},
      );
      return Invitation.fromJson(_data(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<AcceptResult> accept(String token) async {
    try {
      final Response<dynamic> res =
          await _dio.post<dynamic>('/invitations/$token/accept');
      return AcceptResult.fromJson(_data(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Map<String, dynamic> _data(Response<dynamic> res) =>
      (res.data as Map)['data'] as Map<String, dynamic>;
}

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(ref.watch(dioProvider));
});
