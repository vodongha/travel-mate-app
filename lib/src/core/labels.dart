import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Localized labels for backend enums (Category / ExpenseType / SplitType).
class Labels {
  const Labels._();

  static const List<String> categories = [
    'TRANSPORT', 'ACCOMMODATION', 'FOOD', 'SHOPPING', 'ACTIVITY', //
    'SIGHTSEEING', 'MEDICAL', 'PARKING', 'OTHER',
  ];

  static String category(BuildContext context, String value) {
    final AppLocalizations l = AppLocalizations.of(context);
    switch (value) {
      case 'TRANSPORT':
        return l.catTRANSPORT;
      case 'ACCOMMODATION':
        return l.catACCOMMODATION;
      case 'FOOD':
        return l.catFOOD;
      case 'SHOPPING':
        return l.catSHOPPING;
      case 'ACTIVITY':
        return l.catACTIVITY;
      case 'SIGHTSEEING':
        return l.catSIGHTSEEING;
      case 'MEDICAL':
        return l.catMEDICAL;
      case 'PARKING':
        return l.catPARKING;
      default:
        return l.catOTHER;
    }
  }

  static String expenseType(BuildContext context, String value) {
    final AppLocalizations l = AppLocalizations.of(context);
    return value == 'UNEXPECTED' ? l.typeUNEXPECTED : l.typePLANNED;
  }

  // Itinerary events use the canonical Category — minus TRANSPORT and ACCOMMODATION, which are their
  // own dedicated itinerary entities (added via the "+" chooser, not as a generic event).
  static const List<String> eventTypes = [
    'FOOD', 'SHOPPING', 'ACTIVITY', 'SIGHTSEEING', 'MEDICAL', 'PARKING', 'OTHER', //
  ];

  static String eventType(BuildContext context, String value) =>
      category(context, value);

  static const List<String> transportTypes = [
    'FLIGHT', 'TRAIN', 'BUS', 'FERRY', 'TAXI', 'RENTAL_VEHICLE', //
  ];

  static String transportType(BuildContext context, String value) {
    final AppLocalizations l = AppLocalizations.of(context);
    switch (value) {
      case 'FLIGHT':
        return l.ttFLIGHT;
      case 'TRAIN':
        return l.ttTRAIN;
      case 'BUS':
        return l.ttBUS;
      case 'FERRY':
        return l.ttFERRY;
      case 'TAXI':
        return l.ttTAXI;
      default:
        return l.ttRENTAL_VEHICLE;
    }
  }

  // Places use the full canonical Category.
  static const List<String> placeTypes = categories;

  static String placeType(BuildContext context, String value) =>
      category(context, value);

  // Tickets use the full canonical Category.
  static const List<String> ticketTypes = categories;

  static String ticketType(BuildContext context, String value) =>
      category(context, value);

  static String splitType(BuildContext context, String value) {
    final AppLocalizations l = AppLocalizations.of(context);
    switch (value) {
      case 'EXACT':
        return l.splitEXACT;
      case 'PERCENT':
        return l.splitPERCENT;
      case 'SHARES':
        return l.splitSHARES;
      default:
        return l.splitEQUAL;
    }
  }
}
