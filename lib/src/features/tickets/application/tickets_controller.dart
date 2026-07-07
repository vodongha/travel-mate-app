import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticket_repository.dart';

/// Builds the POST/PATCH body for a ticket.
Map<String, dynamic> ticketBody({
  List<String>? memberRids,
  bool shared = false,
  required String title,
  required String ticketType,
  String? qrData,
  String? seat,
  String? provider,
  String? bookingCode,
  String? itineraryKind,
  String? itineraryRid,
  String? note,
}) {
  final Map<String, dynamic> body = {
    'title': title,
    'ticketType': ticketType,
    'qrData': qrData ?? '',
    'seat': seat ?? '',
    'provider': provider ?? '',
    'bookingCode': bookingCode ?? '',
    'itineraryKind': itineraryKind ?? '',
    'itineraryRid': itineraryRid ?? '',
    'note': note ?? '',
  };
  if (shared) {
    body['shared'] = true;
  } else if (memberRids != null) {
    body['memberRids'] = memberRids;
  }
  return body;
}

/// The caller's own tickets for one trip (GET /tickets/mine), keyed by trip rid.
class MyTicketsController extends AsyncNotifier<List<Ticket>> {
  MyTicketsController(this._tripRid);
  final String _tripRid;

  TicketRepository get _repo => ref.read(ticketRepositoryProvider);

  @override
  Future<List<Ticket>> build() => _repo.listMine(_tripRid);
}

final myTicketsControllerProvider =
    AsyncNotifierProvider.family<MyTicketsController, List<Ticket>, String>(
  MyTicketsController.new,
);

/// Every ticket in one trip (GET /tickets), keyed by trip rid. Mutations live here and invalidate
/// both this list and the caller's own list.
class AllTicketsController extends AsyncNotifier<List<Ticket>> {
  AllTicketsController(this._tripRid);
  final String _tripRid;

  TicketRepository get _repo => ref.read(ticketRepositoryProvider);

  @override
  Future<List<Ticket>> build() => _repo.listAll(_tripRid);

  void _invalidateBoth() {
    ref.invalidate(myTicketsControllerProvider(_tripRid));
    ref.invalidateSelf();
  }

  Future<void> create({
    List<String>? memberRids,
    bool shared = false,
    required String title,
    required String ticketType,
    String? qrData,
    String? seat,
    String? provider,
    String? bookingCode,
    String? itineraryKind,
    String? itineraryRid,
    String? note,
  }) async {
    await _repo.create(
      _tripRid,
      ticketBody(
        memberRids: memberRids,
        shared: shared,
        title: title,
        ticketType: ticketType,
        qrData: qrData,
        seat: seat,
        provider: provider,
        bookingCode: bookingCode,
        itineraryKind: itineraryKind,
        itineraryRid: itineraryRid,
        note: note,
      ),
    );
    _invalidateBoth();
    await future;
  }

  Future<void> edit({
    required String rid,
    List<String>? memberRids,
    bool shared = false,
    required String title,
    required String ticketType,
    String? qrData,
    String? seat,
    String? provider,
    String? bookingCode,
    String? itineraryKind,
    String? itineraryRid,
    String? note,
  }) async {
    await _repo.update(
      _tripRid,
      rid,
      ticketBody(
        memberRids: memberRids,
        shared: shared,
        title: title,
        ticketType: ticketType,
        qrData: qrData,
        seat: seat,
        provider: provider,
        bookingCode: bookingCode,
        itineraryKind: itineraryKind,
        itineraryRid: itineraryRid,
        note: note,
      ),
    );
    _invalidateBoth();
    await future;
  }

  Future<void> remove(String rid) async {
    await _repo.delete(_tripRid, rid);
    _invalidateBoth();
    await future;
  }
}

final allTicketsControllerProvider =
    AsyncNotifierProvider.family<AllTicketsController, List<Ticket>, String>(
  AllTicketsController.new,
);
