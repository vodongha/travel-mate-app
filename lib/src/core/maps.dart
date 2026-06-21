import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Open a location in Google Maps (the app if installed, otherwise the browser).
/// Uses coordinates when available, otherwise a text query (place name/address).
Future<void> openInGoogleMaps(
  BuildContext context, {
  double? lat,
  double? lng,
  String? query,
}) async {
  final String q =
      (lat != null && lng != null) ? '$lat,$lng' : (query ?? '').trim();
  if (q.isEmpty) {
    return;
  }
  // Capture before the await so we don't use a stale BuildContext afterwards.
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final AppLocalizations l10n = AppLocalizations.of(context);
  final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}');
  final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.mapsOpenFailed)));
  }
}
