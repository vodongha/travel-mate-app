import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// A timeline event (backend `EventResponse`).
class EventItem {
  const EventItem({
    required this.rid,
    required this.title,
    required this.eventType,
    this.startTime,
    this.endTime,
    this.placeRid,
    this.note,
  });

  final String rid;
  final String title;
  final String eventType;
  final DateTime? startTime;
  final DateTime? endTime;

  /// The linked trip place (its location on the map), or null.
  final String? placeRid;
  final String? note;

  factory EventItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return EventItem(
      rid: json['rid'] as String,
      title: json['title'] as String? ?? '',
      eventType: json['eventType'] as String? ?? 'OTHER',
      startTime: parse(json['startTime']),
      endTime: parse(json['endTime']),
      placeRid: json['placeRid'] as String?,
      note: json['note'] as String?,
    );
  }
}

class EventRepository {
  EventRepository(this._dio);

  final Dio _dio;

  Future<List<EventItem>> list(String tripRid) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/trips/$tripRid/events');
      final List<dynamic> data = (res.data as Map)['data'] as List<dynamic>;
      return data
          .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> create(
    String tripRid, {
    required String title,
    required String eventType,
    required DateTime startTimeUtc,
    DateTime? endTimeUtc,
    String? placeRid,
    String? note,
  }) async {
    try {
      await _dio.post<dynamic>('/trips/$tripRid/events', data: {
        'title': title,
        'eventType': eventType,
        'startTime': startTimeUtc.toIso8601String(),
        if (endTimeUtc != null) 'endTime': endTimeUtc.toIso8601String(),
        if (placeRid != null && placeRid.isNotEmpty) 'placeRid': placeRid,
        if (note != null && note.isNotEmpty) 'note': note,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> update(
    String tripRid,
    String eventRid, {
    required String title,
    required String eventType,
    required DateTime startTimeUtc,
    DateTime? endTimeUtc,
    String? placeRid,
    String? note,
  }) async {
    try {
      await _dio.patch<dynamic>('/trips/$tripRid/events/$eventRid', data: {
        'title': title,
        'eventType': eventType,
        'startTime': startTimeUtc.toIso8601String(),
        'endTime': endTimeUtc?.toIso8601String(),
        // Blank clears the place link; omit-null would leave it unchanged.
        'placeRid': placeRid ?? '',
        'note': note ?? '',
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(String tripRid, String eventRid) async {
    try {
      await _dio.delete<dynamic>('/trips/$tripRid/events/$eventRid');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(dioProvider));
});
