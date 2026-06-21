import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../domain/trip.dart';

/// The only place trip HTTP calls live. Returns domain objects; throws [ApiException] on failure.
class TripRepository {
  TripRepository(this._dio);

  final Dio _dio;

  Future<List<Trip>> listMine() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>('/trips');
      final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
      return data.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Trip> get(String tripRid) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>('/trips/$tripRid');
      return Trip.fromJson(_data(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Trip> create({
    required String name,
    required String baseCurrency,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>('/trips', data: {
        'name': name,
        'baseCurrency': baseCurrency,
        if (destination != null && destination.isNotEmpty)
          'destination': destination,
        if (startDate != null) 'startDate': _isoDate(startDate),
        if (endDate != null) 'endDate': _isoDate(endDate),
      });
      return Trip.fromJson(_data(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Partial trip update (OWNER only on the backend). Only the passed fields are sent.
  Future<Trip> update(
    String tripRid, {
    required String name,
    required String baseCurrency,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      final Response<dynamic> res =
          await _dio.patch<dynamic>('/trips/$tripRid', data: {
        'name': name,
        'baseCurrency': baseCurrency,
        'destination': destination ?? '',
        if (startDate != null) 'startDate': _isoDate(startDate),
        if (endDate != null) 'endDate': _isoDate(endDate),
        if (status != null) 'status': status,
      });
      return Trip.fromJson(_data(res));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(String tripRid) async {
    try {
      await _dio.delete<dynamic>('/trips/$tripRid');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Map<String, dynamic> _data(Response<dynamic> res) =>
      (res.data as Map)['data'] as Map<String, dynamic>;

  static String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(ref.watch(dioProvider));
});
