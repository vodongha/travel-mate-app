import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/transport_repository.dart';

/// Transport legs for one trip (by rid). Times are stored UTC; the UI converts to/from local.
class TransportController
    extends FamilyAsyncNotifier<List<TransportItem>, String> {
  TransportRepository get _repo => ref.read(transportRepositoryProvider);

  @override
  Future<List<TransportItem>> build(String tripRid) => _repo.list(tripRid);

  Map<String, dynamic> _body({
    required String transportType,
    String? provider,
    String? bookingCode,
    String? departurePlace,
    String? arrivalPlace,
    DateTime? departureTimeUtc,
    DateTime? arrivalTimeUtc,
    String? qrData,
    String? note,
  }) {
    return {
      'transportType': transportType,
      'provider': provider ?? '',
      'bookingCode': bookingCode ?? '',
      'departurePlace': departurePlace ?? '',
      'arrivalPlace': arrivalPlace ?? '',
      'departureTime': departureTimeUtc?.toIso8601String(),
      'arrivalTime': arrivalTimeUtc?.toIso8601String(),
      'qrData': qrData ?? '',
      'note': note ?? '',
    };
  }

  Future<void> create({
    required String transportType,
    String? provider,
    String? bookingCode,
    String? departurePlace,
    String? arrivalPlace,
    DateTime? departureTimeUtc,
    DateTime? arrivalTimeUtc,
    String? qrData,
    String? note,
  }) async {
    await _repo.create(
      arg,
      _body(
        transportType: transportType,
        provider: provider,
        bookingCode: bookingCode,
        departurePlace: departurePlace,
        arrivalPlace: arrivalPlace,
        departureTimeUtc: departureTimeUtc,
        arrivalTimeUtc: arrivalTimeUtc,
        qrData: qrData,
        note: note,
      ),
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> edit({
    required String rid,
    required String transportType,
    String? provider,
    String? bookingCode,
    String? departurePlace,
    String? arrivalPlace,
    DateTime? departureTimeUtc,
    DateTime? arrivalTimeUtc,
    String? qrData,
    String? note,
  }) async {
    await _repo.update(
      arg,
      rid,
      _body(
        transportType: transportType,
        provider: provider,
        bookingCode: bookingCode,
        departurePlace: departurePlace,
        arrivalPlace: arrivalPlace,
        departureTimeUtc: departureTimeUtc,
        arrivalTimeUtc: arrivalTimeUtc,
        qrData: qrData,
        note: note,
      ),
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String rid) async {
    await _repo.delete(arg, rid);
    ref.invalidateSelf();
    await future;
  }
}

final transportControllerProvider = AsyncNotifierProvider.family<
    TransportController, List<TransportItem>, String>(
  TransportController.new,
);
