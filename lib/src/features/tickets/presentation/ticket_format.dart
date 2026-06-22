import 'package:flutter/material.dart';

import '../../../core/labels.dart';

/// Localized label for a ticket type (now the canonical Category).
String ticketTypeLabel(BuildContext context, String value) =>
    Labels.ticketType(context, value);

/// An icon for a ticket category.
IconData ticketTypeIcon(String type) {
  switch (type) {
    case 'TRANSPORT':
      return Icons.commute_outlined;
    case 'ACCOMMODATION':
      return Icons.hotel_outlined;
    case 'SIGHTSEEING':
      return Icons.photo_camera_outlined;
    case 'ACTIVITY':
      return Icons.local_activity_outlined;
    case 'FOOD':
      return Icons.restaurant_outlined;
    case 'SHOPPING':
      return Icons.shopping_bag_outlined;
    default:
      return Icons.confirmation_number_outlined;
  }
}
