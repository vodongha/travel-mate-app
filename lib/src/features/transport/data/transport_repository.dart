import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// A transport leg (backend `TransportResponse`). `qrData` is the decoded ticket string — we render
/// it as a QR on view and never store an image (SPEC §2.7).
class TransportItem {
  const TransportItem({
    required this.rid,
    required this.transportType,
    this.provider,
    this.bookingCode,
    this.seat,
    this.departurePlace,
    this.arrivalPlace,
    this.departureTime,
    this.arrivalTime,
    this.qrData,
    this.note,
  });

  final String rid;
  final String transportType;
  final String? provider;
  final String? bookingCode;
  final String? seat;
  final String? departurePlace;
  final String? arrivalPlace;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String? qrData;
  final String? note;

  factory TransportItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return TransportItem(
      rid: json['rid'] as String,
      transportType: json['transportType'] as String? ?? 'FLIGHT',
      provider: json['provider'] as String?,
      bookingCode: json['bookingCode'] as String?,
      seat: json['seat'] as String?,
      departurePlace: json['departurePlace'] as String?,
      arrivalPlace: json['arrivalPlace'] as String?,
      departureTime: parse(json['departureTime']),
      arrivalTime: parse(json['arrivalTime']),
      qrData: json['qrData'] as String?,
      note: json['note'] as String?,
    );
  }
}

class TransportRepository {
  TransportRepository(this._dio);

  final Dio _dio;

  String _base(String tripRid) => '/trips/$tripRid/transports';

  Future<List<TransportItem>> list(String tripRid) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(_base(tripRid));
      final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
      return data
          .map((e) => TransportItem.fromJson(e as Map<String, dynamic>))
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

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  return TransportRepository(ref.watch(dioProvider));
});
