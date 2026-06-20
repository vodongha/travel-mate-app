import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trip_repository.dart';
import '../domain/trip.dart';

/// The current user's trips. Mutations reload the list so it stays in sync with the server.
class TripsController extends AsyncNotifier<List<Trip>> {
  TripRepository get _repo => ref.read(tripRepositoryProvider);

  @override
  Future<List<Trip>> build() => _repo.listMine();

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
}

final tripsControllerProvider =
    AsyncNotifierProvider<TripsController, List<Trip>>(TripsController.new);

/// A single trip by rid (the trip detail screen).
final tripProvider = FutureProvider.family<Trip, String>((ref, tripRid) {
  return ref.watch(tripRepositoryProvider).get(tripRid);
});
