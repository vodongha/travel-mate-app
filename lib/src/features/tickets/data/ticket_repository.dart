import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// A ticket belonging to a trip member (backend `TicketResponse`). `qrData` is the decoded ticket
/// string — we render it as a QR on view and never store an image (SPEC §2.7). `mine` marks the
/// caller's own tickets (so any role can manage them).
class Ticket {
  const Ticket({
    required this.rid,
    required this.memberRid,
    required this.memberName,
    required this.mine,
    required this.title,
    required this.ticketType,
    this.qrData,
    this.seat,
    this.note,
  });

  final String rid;
  final String memberRid;
  final String memberName;
  final bool mine;
  final String title;
  final String ticketType;
  final String? qrData;
  final String? seat;
  final String? note;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      rid: json['rid'] as String,
      memberRid: json['memberRid'] as String? ?? '',
      memberName: json['memberName'] as String? ?? '',
      mine: json['mine'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      ticketType: json['ticketType'] as String? ?? 'OTHER',
      qrData: json['qrData'] as String?,
      seat: json['seat'] as String?,
      note: json['note'] as String?,
    );
  }
}

class TicketRepository {
  TicketRepository(this._dio);

  final Dio _dio;

  String _base(String tripRid) => '/trips/$tripRid/tickets';

  List<Ticket> _parseList(Response<dynamic> res) {
    final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
    return data.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// The caller's own tickets (GET /tickets/mine).
  Future<List<Ticket>> listMine(String tripRid) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('${_base(tripRid)}/mine');
      return _parseList(res);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Every ticket in the trip (GET /tickets); `mine` marks the caller's.
  Future<List<Ticket>> listAll(String tripRid) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(_base(tripRid));
      return _parseList(res);
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

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(ref.watch(dioProvider));
});
