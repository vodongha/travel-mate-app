import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticket_repository.dart';

/// Builds the POST/PATCH body for a ticket. `memberRid` blank/omitted ⇒ the ticket is the caller's
/// own (works at any role); a real memberRid assigns it to another member (needs EDITOR — the
/// server enforces this and a 403 surfaces as a friendly message).
Map<String, dynamic> ticketBody({
  String? memberRid,
  required String title,
  required String ticketType,
  String? qrData,
  String? seat,
  String? note,
}) {
  final Map<String, dynamic> body = {
    'title': title,
    'ticketType': ticketType,
    'qrData': qrData ?? '',
    'seat': seat ?? '',
    'note': note ?? '',
  };
  if (memberRid != null && memberRid.isNotEmpty) {
    body['memberRid'] = memberRid;
  }
  return body;
}

/// The caller's own tickets for one trip (GET /tickets/mine), keyed by trip rid.
class MyTicketsController extends FamilyAsyncNotifier<List<Ticket>, String> {
  TicketRepository get _repo => ref.read(ticketRepositoryProvider);

  @override
  Future<List<Ticket>> build(String tripRid) => _repo.listMine(tripRid);
}

final myTicketsControllerProvider =
    AsyncNotifierProvider.family<MyTicketsController, List<Ticket>, String>(
  MyTicketsController.new,
);

/// Every ticket in one trip (GET /tickets), keyed by trip rid. Mutations live here and invalidate
/// both this list and the caller's own list.
class AllTicketsController extends FamilyAsyncNotifier<List<Ticket>, String> {
  TicketRepository get _repo => ref.read(ticketRepositoryProvider);

  @override
  Future<List<Ticket>> build(String tripRid) => _repo.listAll(tripRid);

  void _invalidateBoth() {
    ref.invalidate(myTicketsControllerProvider(arg));
    ref.invalidateSelf();
  }

  Future<void> create({
    String? memberRid,
    required String title,
    required String ticketType,
    String? qrData,
    String? seat,
    String? note,
  }) async {
    await _repo.create(
      arg,
      ticketBody(
        memberRid: memberRid,
        title: title,
        ticketType: ticketType,
        qrData: qrData,
        seat: seat,
        note: note,
      ),
    );
    _invalidateBoth();
    await future;
  }

  Future<void> edit({
    required String rid,
    String? memberRid,
    required String title,
    required String ticketType,
    String? qrData,
    String? seat,
    String? note,
  }) async {
    await _repo.update(
      arg,
      rid,
      ticketBody(
        memberRid: memberRid,
        title: title,
        ticketType: ticketType,
        qrData: qrData,
        seat: seat,
        note: note,
      ),
    );
    _invalidateBoth();
    await future;
  }

  Future<void> remove(String rid) async {
    await _repo.delete(arg, rid);
    _invalidateBoth();
    await future;
  }
}

final allTicketsControllerProvider =
    AsyncNotifierProvider.family<AllTicketsController, List<Ticket>, String>(
  AllTicketsController.new,
);
