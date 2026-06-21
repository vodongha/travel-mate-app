import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// A saved place on the trip (backend `PlaceResponse`).
class PlaceItem {
  const PlaceItem({
    required this.rid,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.placeType,
  });

  final String rid;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? placeType;

  factory PlaceItem.fromJson(Map<String, dynamic> json) {
    double? num2(Object? v) => v == null ? null : double.tryParse(v.toString());
    return PlaceItem(
      rid: json['rid'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      latitude: num2(json['latitude']),
      longitude: num2(json['longitude']),
      placeType: json['placeType'] as String?,
    );
  }
}

class PlaceRepository {
  PlaceRepository(this._dio);

  final Dio _dio;

  String _base(String tripRid) => '/trips/$tripRid/places';

  Future<List<PlaceItem>> list(String tripRid) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(_base(tripRid));
      final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
      return data
          .map((e) => PlaceItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<PlaceItem> create(String tripRid, Map<String, dynamic> body) async {
    try {
      final Response<dynamic> res =
          await _dio.post<dynamic>(_base(tripRid), data: body);
      return PlaceItem.fromJson(
          (res.data as Map)['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> update(
      String tripRid, String rid, Map<String, dynamic> body) async {
    try {
      await _dio.patch<dynamic>('${_base(tripRid)}/$rid', data: body);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(String tripRid, String rid) async {
    try {
      await _dio.delete<dynamic>('${_base(tripRid)}/$rid');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  return PlaceRepository(ref.watch(dioProvider));
});
