import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/labels.dart';
import '../../accommodation/data/accommodation_repository.dart';
import '../../timeline/data/event_repository.dart';
import '../../transport/data/transport_repository.dart';

/// Itinerary kinds an expense can attach to. The string values MUST match the backend
/// `ItineraryKind` enum (EVENT / TRANSPORT / ACCOMMODATION).
class ItineraryKinds {
  const ItineraryKinds._();
  static const String event = 'EVENT';
  static const String transport = 'TRANSPORT';
  static const String accommodation = 'ACCOMMODATION';
}

/// A flattened reference to one itinerary item — a timeline event, a transport leg, or an
/// accommodation stay — so the expense "attach to itinerary" picker can list all three tables in a
/// single, sectioned list (the timeline is composed of these three, but they're separate entities).
class ItineraryRef {
  const ItineraryRef({
    required this.kind,
    required this.rid,
    required this.label,
    required this.icon,
  });

  final String kind;
  final String rid;
  final String label;
  final IconData icon;
}

/// Build the combined, kind-ordered list (events, then transport, then accommodation) for the picker.
List<ItineraryRef> buildItineraryRefs(
  BuildContext context,
  List<EventItem> events,
  List<TransportItem> transports,
  List<AccommodationItem> stays,
) {
  return [
    for (final EventItem e in events)
      ItineraryRef(
        kind: ItineraryKinds.event,
        rid: e.rid,
        label: e.title.trim().isEmpty
            ? Labels.eventType(context, e.eventType)
            : e.title,
        icon: Icons.event_note_outlined,
      ),
    for (final TransportItem t in transports)
      ItineraryRef(
        kind: ItineraryKinds.transport,
        rid: t.rid,
        label: _transportLabel(context, t),
        icon: Icons.directions_transit_outlined,
      ),
    for (final AccommodationItem a in stays)
      ItineraryRef(
        kind: ItineraryKinds.accommodation,
        rid: a.rid,
        label: a.name.trim().isEmpty
            ? AppLocalizations.of(context).navAccommodation
            : a.name,
        icon: Icons.hotel_outlined,
      ),
  ];
}

String _transportLabel(BuildContext context, TransportItem t) {
  // The leg holds only what/where/when now — label by route, falling back to its type.
  final String dep = t.departurePlace?.trim() ?? '';
  final String arr = t.arrivalPlace?.trim() ?? '';
  if (dep.isNotEmpty || arr.isNotEmpty) {
    return '$dep → $arr';
  }
  return Labels.transportType(context, t.transportType);
}

/// Section header label for a kind, used by the picker.
String itinerarySectionLabel(BuildContext context, String kind) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  switch (kind) {
    case ItineraryKinds.transport:
      return l10n.navTransport;
    case ItineraryKinds.accommodation:
      return l10n.navAccommodation;
    default:
      return l10n.itineraryEvents;
  }
}
