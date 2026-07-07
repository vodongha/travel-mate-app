import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/accommodation_repository.dart';

/// Accommodations for one trip (by rid). Times are stored UTC; the UI converts to/from local.
class AccommodationController extends AsyncNotifier<List<AccommodationItem>> {
  AccommodationController(this._tripRid);
  final String _tripRid;

  AccommodationRepository get _repo =>
      ref.read(accommodationRepositoryProvider);

  @override
  Future<List<AccommodationItem>> build() => _repo.list(_tripRid);

  Map<String, dynamic> _body({
    required String name,
    String? address,
    DateTime? checkinTimeUtc,
    DateTime? checkoutTimeUtc,
    String? note,
  }) {
    return {
      'name': name,
      'address': address ?? '',
      'checkinTime': checkinTimeUtc?.toIso8601String(),
      'checkoutTime': checkoutTimeUtc?.toIso8601String(),
      'note': note ?? '',
    };
  }

  Future<void> create({
    required String name,
    String? address,
    DateTime? checkinTimeUtc,
    DateTime? checkoutTimeUtc,
    String? note,
  }) async {
    await _repo.create(
      _tripRid,
      _body(
        name: name,
        address: address,
        checkinTimeUtc: checkinTimeUtc,
        checkoutTimeUtc: checkoutTimeUtc,
        note: note,
      ),
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> edit({
    required String rid,
    required String name,
    String? address,
    DateTime? checkinTimeUtc,
    DateTime? checkoutTimeUtc,
    String? note,
  }) async {
    await _repo.update(
      _tripRid,
      rid,
      _body(
        name: name,
        address: address,
        checkinTimeUtc: checkinTimeUtc,
        checkoutTimeUtc: checkoutTimeUtc,
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

final accommodationControllerProvider = AsyncNotifierProvider.family<
    AccommodationController, List<AccommodationItem>, String>(
  AccommodationController.new,
);
