import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/dashboard_repository.dart';
import '../data/event_repository.dart';

/// Timeline events for one trip (by rid). Creating one refreshes the dashboard (next-event).
class EventsController extends FamilyAsyncNotifier<List<EventItem>, String> {
  EventRepository get _repo => ref.read(eventRepositoryProvider);

  @override
  Future<List<EventItem>> build(String tripRid) => _repo.list(tripRid);

  Future<void> create({
    required String title,
    required String eventType,
    required DateTime startTimeUtc,
    DateTime? endTimeUtc,
    String? note,
  }) async {
    await _repo.create(
      arg,
      title: title,
      eventType: eventType,
      startTimeUtc: startTimeUtc,
      endTimeUtc: endTimeUtc,
      note: note,
    );
    ref.invalidateSelf();
    ref.invalidate(dashboardProvider(arg));
    await future;
  }
}

final eventsControllerProvider =
    AsyncNotifierProvider.family<EventsController, List<EventItem>, String>(
  EventsController.new,
);
