import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// Exchange-rate snapshot metadata (backend `RatesResponse`). The app doesn't convert money — it
/// only shows when rates were last updated and lets the user force a refresh.
class RatesInfo {
  const RatesInfo(
      {required this.baseCurrency, this.updatedAt, required this.count});

  final String baseCurrency;
  final DateTime? updatedAt;
  final int count;

  factory RatesInfo.fromJson(Map<String, dynamic> json) {
    final Object? updated = json['updatedAt'];
    return RatesInfo(
      baseCurrency: json['baseCurrency'] as String? ?? 'VND',
      updatedAt: updated is String ? DateTime.tryParse(updated) : null,
      count: (json['rates'] as List<dynamic>?)?.length ?? 0,
    );
  }
}

class RatesRepository {
  RatesRepository(this._dio);

  final Dio _dio;

  Future<RatesInfo> get() => _call('/rates', (d) => _dio.get<dynamic>(d));

  Future<RatesInfo> refresh() =>
      _call('/rates/refresh', (d) => _dio.post<dynamic>(d));

  Future<RatesInfo> _call(
      String path, Future<Response<dynamic>> Function(String) request) async {
    try {
      final Response<dynamic> res = await request(path);
      return RatesInfo.fromJson(
          (res.data as Map)['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final ratesRepositoryProvider = Provider<RatesRepository>((ref) {
  return RatesRepository(ref.watch(dioProvider));
});

/// Current rate snapshot info (for the Settings tile subtitle).
final ratesInfoProvider = FutureProvider<RatesInfo>((ref) {
  return ref.watch(ratesRepositoryProvider).get();
});
