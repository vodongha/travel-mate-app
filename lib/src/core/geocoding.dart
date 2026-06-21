import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// One place returned by the OpenStreetMap Nominatim geocoder.
class GeoResult {
  const GeoResult(
      {required this.name, required this.displayName, required this.point});

  /// A short label (the first part of [displayName]) — a sensible default place name.
  final String name;

  /// The full address Nominatim returns (e.g. "Marble Mountains, Đà Nẵng, Việt Nam").
  final String displayName;

  final LatLng point;

  factory GeoResult.fromJson(Map<String, dynamic> json) {
    final String display = (json['display_name'] as String?) ?? '';
    final String short =
        display.contains(',') ? display.split(',').first.trim() : display;
    return GeoResult(
      name: short.isEmpty ? display : short,
      displayName: display,
      point: LatLng(
        double.tryParse('${json['lat']}') ?? 0,
        double.tryParse('${json['lon']}') ?? 0,
      ),
    );
  }
}

/// Free-text place search + reverse lookup via OpenStreetMap **Nominatim** (no API key). Uses its
/// own Dio (no bearer/refresh interceptor — this is a third-party endpoint). Respect Nominatim's
/// usage policy: ≤1 request/second (callers debounce) and a descriptive User-Agent.
class GeocodingService {
  GeocodingService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://nominatim.openstreetmap.org',
          // Browsers forbid setting User-Agent (it logs "Refused to set unsafe
          // header") and send their own; only set it off the web.
          headers: kIsWeb
              ? null
              : const {'User-Agent': 'TravelMate/1.0 (vn.trippo.mate)'},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  final Dio _dio;

  /// Searches places by free text. Returns [] on any error (search is best-effort).
  Future<List<GeoResult>> search(String query, {String lang = 'vi'}) async {
    final String q = query.trim();
    if (q.length < 3) {
      return const [];
    }
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/search', queryParameters: {
        'q': q,
        'format': 'json',
        'limit': 6,
        'accept-language': lang,
      });
      final List<dynamic> data = res.data as List<dynamic>;
      return data
          .map((e) => GeoResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Reverse-geocodes a dropped pin into an address label, or null if unavailable.
  Future<GeoResult?> reverse(LatLng point, {String lang = 'vi'}) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/reverse', queryParameters: {
        'lat': point.latitude,
        'lon': point.longitude,
        'format': 'json',
        'accept-language': lang,
      });
      final Map<String, dynamic> json = res.data as Map<String, dynamic>;
      if (json['display_name'] == null) {
        return null;
      }
      // Keep the exact dropped point; only borrow the label.
      final GeoResult labelled = GeoResult.fromJson(json);
      return GeoResult(
          name: labelled.name, displayName: labelled.displayName, point: point);
    } catch (_) {
      return null;
    }
  }
}

final geocodingServiceProvider =
    Provider<GeocodingService>((ref) => GeocodingService());
