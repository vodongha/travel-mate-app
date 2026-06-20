import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/accommodation_repository.dart';

/// Accommodations for one trip (by rid). Times are stored UTC; the UI converts to/from local.
class AccommodationController
    extends FamilyAsyncNotifier<List<AccommodationItem>, String> {
  AccommodationRepository get _repo =>
      ref.read(accommodationRepositoryProvider);

  @override
  Future<List<AccommodationItem>> build(String tripRid) => _repo.list(tripRid);

  Map<String, dynamic> _body({
    required String name,
    String? bookingCode,
    String? address,
    DateTime? checkinTimeUtc,
    DateTime? checkoutTimeUtc,
    String? qrData,
    String? note,
  }) {
    return {
      'name': name,
      'bookingCode': bookingCode ?? '',
      'address': address ?? '',
      'checkinTime': checkinTimeUtc?.toIso8601String(),
      'checkoutTime': checkoutTimeUtc?.toIso8601String(),
      'qrData': qrData ?? '',
      'note': note ?? '',
    };
  }

  Future<void> create({
    required String name,
    String? bookingCode,
    String? address,
    DateTime? checkinTimeUtc,
    DateTime? checkoutTimeUtc,
    String? qrData,
    String? note,
  }) async {
    await _repo.create(
      arg,
      _body(
        name: name,
        bookingCode: bookingCode,
        address: address,
        checkinTimeUtc: checkinTimeUtc,
        checkoutTimeUtc: checkoutTimeUtc,
        qrData: qrData,
        note: note,
      ),
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> edit({
    required String rid,
    required String name,
    String? bookingCode,
    String? address,
    DateTime? checkinTimeUtc,
    DateTime? checkoutTimeUtc,
    String? qrData,
    String? note,
  }) async {
    await _repo.update(
      arg,
      rid,
      _body(
        name: name,
        bookingCode: bookingCode,
        address: address,
        checkinTimeUtc: checkinTimeUtc,
        checkoutTimeUtc: checkoutTimeUtc,
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

final accommodationControllerProvider = AsyncNotifierProvider.family<
    AccommodationController, List<AccommodationItem>, String>(
  AccommodationController.new,
);
