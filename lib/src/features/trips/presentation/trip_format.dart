import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../domain/trip.dart';

/// Localized label for a member role (OWNER/EDITOR/VIEWER).
String roleLabel(BuildContext context, String? role) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  switch (role) {
    case 'OWNER':
      return l10n.roleOWNER;
    case 'EDITOR':
      return l10n.roleEDITOR;
    case 'VIEWER':
      return l10n.roleVIEWER;
    default:
      return role ?? '';
  }
}

/// A human date range for a trip, e.g. "1 Jan – 10 Jan 2099", localized; falls back when unset.
String tripDateRange(BuildContext context, Trip trip) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final String locale = Localizations.localeOf(context).toLanguageTag();
  final DateFormat fmt = DateFormat.yMMMd(locale);
  if (trip.startDate == null && trip.endDate == null) {
    return l10n.tripNoDates;
  }
  if (trip.startDate != null && trip.endDate != null) {
    return '${fmt.format(trip.startDate!)} – ${fmt.format(trip.endDate!)}';
  }
  return fmt.format((trip.startDate ?? trip.endDate)!);
}

/// Localized label for a trip status. UPCOMING is a derived-only state (the trip starts within a
/// week) — see [tripEffectiveStatus]; the others map to the backend TripStatus.
String tripStatusLabel(BuildContext context, String status) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  switch (status) {
    case 'PLANNING':
      return l10n.tripStatusPlanning;
    case 'UPCOMING':
      return l10n.tripStatusUpcoming;
    case 'ONGOING':
      return l10n.tripStatusOngoing;
    case 'COMPLETED':
      return l10n.tripStatusCompleted;
    case 'CANCELLED':
      return l10n.tripStatusCancelled;
    default:
      return status;
  }
}

/// Number of days within which an upcoming trip flips from PLANNING to UPCOMING ("Sắp diễn ra").
const int kTripUpcomingDays = 7;

/// The status to *display*, derived from the trip's dates so it updates itself
/// automatically: more than a week before the start it's PLANNING, within the
/// last [kTripUpcomingDays] days before the start UPCOMING, between start and
/// end (inclusive) ONGOING, after the end day COMPLETED. A trip explicitly
/// marked CANCELLED stays cancelled. Falls back to the stored status when there
/// are no dates to reason about.
String tripEffectiveStatus(Trip trip) {
  if (trip.status == 'CANCELLED') {
    return 'CANCELLED';
  }
  final DateTime? start = trip.startDate;
  final DateTime? end = trip.endDate;
  if (start == null && end == null) {
    return trip.status;
  }
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
  final DateTime? startDay = start == null ? null : dayOf(start);
  final DateTime? endDay = end == null ? null : dayOf(end);
  if (startDay != null && today.isBefore(startDay)) {
    // Within a week of departure → "Sắp diễn ra"; further out → still planning.
    final int daysUntilStart = startDay.difference(today).inDays;
    return daysUntilStart <= kTripUpcomingDays ? 'UPCOMING' : 'PLANNING';
  }
  if (endDay != null && today.isAfter(endDay)) {
    return 'COMPLETED';
  }
  // Within [start, end] inclusive (or started with no end set).
  return 'ONGOING';
}

/// A colour for a trip status, drawn from the theme's colour scheme so it adapts
/// to light/dark. Returns the (background, foreground) pair for a status chip.
({Color bg, Color fg}) tripStatusColors(BuildContext context, String status) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  switch (status) {
    case 'ONGOING':
      return (bg: scheme.primaryContainer, fg: scheme.onPrimaryContainer);
    case 'UPCOMING':
      return (bg: scheme.secondaryContainer, fg: scheme.onSecondaryContainer);
    case 'COMPLETED':
      return (bg: scheme.surfaceContainerHighest, fg: scheme.onSurfaceVariant);
    case 'CANCELLED':
      return (bg: scheme.errorContainer, fg: scheme.onErrorContainer);
    case 'PLANNING':
    default:
      return (bg: scheme.tertiaryContainer, fg: scheme.onTertiaryContainer);
  }
}

/// A short countdown for a trip relative to today: "in N days" before it starts,
/// "Ongoing" while it runs, "Ended" once over. Null when there are no dates to
/// reason about. Computed from the trip's date range, day-resolution.
String? tripCountdown(BuildContext context, Trip trip) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final DateTime? start = trip.startDate;
  final DateTime? end = trip.endDate;
  if (start == null && end == null) {
    return null;
  }
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);

  DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  final DateTime? startDay = start == null ? null : dayOf(start);
  final DateTime? endDay = end == null ? null : dayOf(end);

  if (startDay != null && today.isBefore(startDay)) {
    final int days = startDay.difference(today).inDays;
    return days == 0
        ? l10n.tripCountdownStartsToday
        : l10n.tripCountdownIn(days);
  }
  if (endDay != null && today.isAfter(endDay)) {
    return l10n.tripCountdownEnded;
  }
  if (startDay != null && endDay == null && today.isAfter(startDay)) {
    return l10n.tripCountdownEnded;
  }
  return l10n.tripCountdownOngoing;
}
