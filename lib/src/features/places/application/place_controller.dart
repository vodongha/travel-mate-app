import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/place_repository.dart';

/// Saved places for one trip (by rid).
class PlaceController extends AsyncNotifier<List<PlaceItem>> {
  PlaceController(this._tripRid);
  final String _tripRid;

  PlaceRepository get _repo => ref.read(placeRepositoryProvider);

  @override
  Future<List<PlaceItem>> build() => _repo.list(_tripRid);

  Map<String, dynamic> _body({
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeType,
  }) {
    return {
      'name': name,
      'address': address ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'placeType': placeType,
    };
  }

  Future<PlaceItem> create({
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeType,
  }) async {
    final PlaceItem created = await _repo.create(
      _tripRid,
      _body(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        placeType: placeType,
      ),
    );
    ref.invalidateSelf();
    await future;
    return created;
  }

  Future<void> edit({
    required String rid,
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeType,
  }) async {
    await _repo.update(
      _tripRid,
      rid,
      _body(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        placeType: placeType,
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

final placeControllerProvider =
    AsyncNotifierProvider.family<PlaceController, List<PlaceItem>, String>(
  PlaceController.new,
);
