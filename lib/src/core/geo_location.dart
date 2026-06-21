import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Returns the device's current position, requesting permission if needed. Returns null when the
/// location service is off or permission is denied (callers show a friendly notice). Web uses the
/// browser geolocation API (HTTPS only); Android needs the location permissions in the manifest.
Future<LatLng?> currentLatLng() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final Position pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}
