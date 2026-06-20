import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../domain/dashboard.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<Dashboard> get(String tripRid) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/trips/$tripRid/dashboard');
      return Dashboard.fromJson(
          (res.data as Map)['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

/// The dashboard for one trip (by rid).
final dashboardProvider =
    FutureProvider.family<Dashboard, String>((ref, tripRid) {
  return ref.watch(dashboardRepositoryProvider).get(tripRid);
});
