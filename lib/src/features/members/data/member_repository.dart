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

  Future<Member> addGhost(String tripRid, String displayName, String role,
      {String? email}) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/trips/$tripRid/members',
        data: {
          'displayName': displayName,
          'role': role,
          if (email != null && email.isNotEmpty) 'email': email,
        },
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

  /// OWNER-only partial update (backend `PATCH /trips/{tripRid}/members/{memberRid}`). `role` works
  /// for any member; `displayName`/`email` are applied to a ghost only. Blank `email` clears it.
  Future<void> update(String tripRid, String memberRid,
      {String? displayName, String? email, String? role}) async {
    try {
      await _dio.patch<dynamic>(
        '/trips/$tripRid/members/$memberRid',
        data: {
          if (displayName != null) 'displayName': displayName,
          if (email != null) 'email': email,
          if (role != null) 'role': role,
        },
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// OWNER-only: merge [memberRid] (a ghost) into [targetRid] — backend re-points its money/tickets.
  Future<void> merge(String tripRid, String memberRid, String targetRid) async {
    try {
      await _dio.post<dynamic>(
        '/trips/$tripRid/members/$memberRid/merge',
        data: {'targetRid': targetRid},
      );
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
