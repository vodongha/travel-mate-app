import 'package:flutter/material.dart';

import '../../../core/labels.dart';

/// Localized label for a ticket type (TRANSPORT/ACCOMMODATION/SIGHTSEEING/EVENT/OTHER).
String ticketTypeLabel(BuildContext context, String value) =>
    Labels.ticketType(context, value);

/// An icon for a ticket type.
IconData ticketTypeIcon(String type) {
  switch (type) {
    case 'TRANSPORT':
      return Icons.commute_outlined;
    case 'ACCOMMODATION':
      return Icons.hotel_outlined;
    case 'SIGHTSEEING':
      return Icons.photo_camera_outlined;
    case 'EVENT':
      return Icons.local_activity_outlined;
    default:
      return Icons.confirmation_number_outlined;
  }
}
