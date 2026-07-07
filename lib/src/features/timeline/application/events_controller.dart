import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/dashboard_repository.dart';
import '../data/event_repository.dart';

/// Timeline events for one trip (by rid). Creating one refreshes the dashboard (next-event).
class EventsController extends AsyncNotifier<List<EventItem>> {
  EventsController(this._tripRid);
  final String _tripRid;

  EventRepository get _repo => ref.read(eventRepositoryProvider);

  @override
  Future<List<EventItem>> build() => _repo.list(_tripRid);

  Future<void> create({
    required String title,
    required String eventType,
    required DateTime startTimeUtc,
    DateTime? endTimeUtc,
    String? placeRid,
    String? note,
  }) async {
    await _repo.create(
      _tripRid,
      title: title,
      eventType: eventType,
      startTimeUtc: startTimeUtc,
      endTimeUtc: endTimeUtc,
      placeRid: placeRid,
      note: note,
    );
    ref.invalidateSelf();
    ref.invalidate(dashboardProvider(_tripRid));
    await future;
  }

  Future<void> edit({
    required String eventRid,
    required String title,
    required String eventType,
    required DateTime startTimeUtc,
    DateTime? endTimeUtc,
    String? placeRid,
    String? note,
  }) async {
    await _repo.update(
      _tripRid,
      eventRid,
      title: title,
      eventType: eventType,
      startTimeUtc: startTimeUtc,
      endTimeUtc: endTimeUtc,
      placeRid: placeRid,
      note: note,
    );
    ref.invalidateSelf();
    ref.invalidate(dashboardProvider(_tripRid));
    await future;
  }

  Future<void> delete(String eventRid) async {
    await _repo.delete(_tripRid, eventRid);
    ref.invalidateSelf();
    ref.invalidate(dashboardProvider(_tripRid));
    await future;
  }
}

final eventsControllerProvider =
    AsyncNotifierProvider.family<EventsController, List<EventItem>, String>(
  EventsController.new,
);
