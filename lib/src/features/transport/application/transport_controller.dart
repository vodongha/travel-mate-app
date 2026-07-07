import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/transport_repository.dart';

/// Transport legs for one trip (by rid). Times are stored UTC; the UI converts to/from local.
class TransportController extends AsyncNotifier<List<TransportItem>> {
  TransportController(this._tripRid);
  final String _tripRid;

  TransportRepository get _repo => ref.read(transportRepositoryProvider);

  @override
  Future<List<TransportItem>> build() => _repo.list(_tripRid);

  Map<String, dynamic> _body({
    required String transportType,
    String? departurePlace,
    String? arrivalPlace,
    DateTime? departureTimeUtc,
    DateTime? arrivalTimeUtc,
    String? note,
  }) {
    return {
      'transportType': transportType,
      'departurePlace': departurePlace ?? '',
      'arrivalPlace': arrivalPlace ?? '',
      'departureTime': departureTimeUtc?.toIso8601String(),
      'arrivalTime': arrivalTimeUtc?.toIso8601String(),
      'note': note ?? '',
    };
  }

  Future<void> create({
    required String transportType,
    String? departurePlace,
    String? arrivalPlace,
    DateTime? departureTimeUtc,
    DateTime? arrivalTimeUtc,
    String? note,
  }) async {
    await _repo.create(
      _tripRid,
      _body(
        transportType: transportType,
        departurePlace: departurePlace,
        arrivalPlace: arrivalPlace,
        departureTimeUtc: departureTimeUtc,
        arrivalTimeUtc: arrivalTimeUtc,
        note: note,
      ),
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> edit({
    required String rid,
    required String transportType,
    String? departurePlace,
    String? arrivalPlace,
    DateTime? departureTimeUtc,
    DateTime? arrivalTimeUtc,
    String? note,
  }) async {
    await _repo.update(
      _tripRid,
      rid,
      _body(
        transportType: transportType,
        departurePlace: departurePlace,
        arrivalPlace: arrivalPlace,
        departureTimeUtc: departureTimeUtc,
        arrivalTimeUtc: arrivalTimeUtc,
        note: note,
      ),
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String rid) async {
    await _repo.delete(_tripRid, rid);
    ref.invalidateSelf();
    await future;
  }
}

final transportControllerProvider = AsyncNotifierProvider.family<
    TransportController, List<TransportItem>, String>(
  TransportController.new,
);
