import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticket_repository.dart';

/// Builds the POST/PATCH body for a ticket. `shared` ⇒ a group ticket (no specific members, shared by
/// the whole trip — needs EDITOR). Otherwise `memberRids` lists the covered members (empty ⇒ the
/// caller's own); assigning to others/the group needs EDITOR (the server enforces it; a 403 surfaces
/// as a friendly message).
Map<String, dynamic> ticketBody({
  List<String>? memberRids,
  bool shared = false,
  required String title,
  required String ticketType,
  String? qrData,
  String? seat,
  String? itineraryKind,
  String? itineraryRid,
  String? note,
}) {
  final Map<String, dynamic> body = {
    'title': title,
    'ticketType': ticketType,
    'qrData': qrData ?? '',
    'seat': seat ?? '',
    // Blank itineraryRid clears the link; a value (re)sets it to that itinerary item.
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
    List<String>? memberRids,
    bool shared = false,
    required String title,
    required String ticketType,
    String? qrData,
    String? seat,
    String? itineraryKind,
    String? itineraryRid,
    String? note,
  }) async {
    await _repo.create(
      arg,
      ticketBody(
        memberRids: memberRids,
        shared: shared,
        title: title,
        ticketType: ticketType,
        qrData: qrData,
        seat: seat,
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
    String? itineraryKind,
    String? itineraryRid,
    String? note,
  }) async {
    await _repo.update(
      arg,
      rid,
      ticketBody(
        memberRids: memberRids,
        shared: shared,
        title: title,
        ticketType: ticketType,
        qrData: qrData,
        seat: seat,
        itineraryKind: itineraryKind,
        itineraryRid: itineraryRid,
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
