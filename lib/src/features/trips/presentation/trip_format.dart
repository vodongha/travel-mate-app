import 'package:flutter/widgets.dart';
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
