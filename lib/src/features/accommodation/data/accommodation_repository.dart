import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// A lodging booking (backend `AccommodationResponse`). The stay holds only name/where/when; the
/// booking voucher code + QR live on the (group) ticket linked to this stay, not here.
class AccommodationItem {
  const AccommodationItem({
    required this.rid,
    required this.name,
    this.address,
    this.checkinTime,
    this.checkoutTime,
    this.note,
  });

  final String rid;
  final String name;
  final String? address;
  final DateTime? checkinTime;
  final DateTime? checkoutTime;
  final String? note;

  factory AccommodationItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return AccommodationItem(
      rid: json['rid'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      checkinTime: parse(json['checkinTime']),
      checkoutTime: parse(json['checkoutTime']),
      note: json['note'] as String?,
    );
  }
}

class AccommodationRepository {
  AccommodationRepository(this._dio);

  final Dio _dio;

  String _base(String tripRid) => '/trips/$tripRid/accommodations';

  Future<List<AccommodationItem>> list(String tripRid) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(_base(tripRid));
      final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
      return data
          .map((e) => AccommodationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> create(String tripRid, Map<String, dynamic> body) async {
    try {
      await _dio.post<dynamic>(_base(tripRid), data: body);
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

final accommodationRepositoryProvider =
    Provider<AccommodationRepository>((ref) {
  return AccommodationRepository(ref.watch(dioProvider));
});
