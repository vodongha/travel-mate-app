import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/place_repository.dart';

/// Saved places for one trip (by rid).
class PlaceController extends FamilyAsyncNotifier<List<PlaceItem>, String> {
  PlaceRepository get _repo => ref.read(placeRepositoryProvider);

  @override
  Future<List<PlaceItem>> build(String tripRid) => _repo.list(tripRid);

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

  Future<void> create({
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeType,
  }) async {
    await _repo.create(
      arg,
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

  Future<void> edit({
    required String rid,
    required String name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeType,
  }) async {
    await _repo.update(
      arg,
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
    await _repo.delete(arg, rid);
    ref.invalidateSelf();
    await future;
  }
}

final placeControllerProvider =
    AsyncNotifierProvider.family<PlaceController, List<PlaceItem>, String>(
  PlaceController.new,
);
