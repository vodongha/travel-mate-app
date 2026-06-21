import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trip_repository.dart';
import '../domain/trip.dart';

/// The current user's trips. Mutations reload the list so it stays in sync with the server.
class TripsController extends AsyncNotifier<List<Trip>> {
  TripRepository get _repo => ref.read(tripRepositoryProvider);

  @override
  Future<List<Trip>> build() async {
    final List<Trip> trips = await _repo.listMine();
    return _sortedNewestFirst(trips);
  }

  /// Newest first: by `startDate` descending, trips without a start date last.
  /// `List.sort` is stable, so equal start dates keep their server order.
  static List<Trip> _sortedNewestFirst(List<Trip> trips) {
    final List<Trip> sorted = List<Trip>.of(trips);
    sorted.sort((a, b) {
      final DateTime? sa = a.startDate;
      final DateTime? sb = b.startDate;
      if (sa == null && sb == null) {
        return 0;
      }
      if (sa == null) {
        return 1; // a (no date) sorts after b
      }
      if (sb == null) {
        return -1; // b (no date) sorts after a
      }
      return sb.compareTo(sa); // descending
    });
    return sorted;
  }

  Future<Trip> create({
    required String name,
    required String baseCurrency,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Trip trip = await _repo.create(
      name: name,
      baseCurrency: baseCurrency,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
    );
    ref.invalidateSelf();
    return trip;
  }

  Future<Trip> edit(
    String tripRid, {
    required String name,
    required String baseCurrency,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    final Trip trip = await _repo.update(
      tripRid,
      name: name,
      baseCurrency: baseCurrency,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
    ref.invalidateSelf();
    ref.invalidate(tripProvider(tripRid));
    return trip;
  }

  Future<void> remove(String tripRid) async {
    await _repo.delete(tripRid);
    ref.invalidateSelf();
    ref.invalidate(tripProvider(tripRid));
  }
}

final tripsControllerProvider =
    AsyncNotifierProvider<TripsController, List<Trip>>(TripsController.new);

/// A single trip by rid (the trip detail screen).
final tripProvider = FutureProvider.family<Trip, String>((ref, tripRid) {
  return ref.watch(tripRepositoryProvider).get(tripRid);
});
