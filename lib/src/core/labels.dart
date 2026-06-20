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

  static const List<String> eventTypes = [
    'TRANSPORT',
    'HOTEL',
    'FOOD',
    'ACTIVITY',
    'SIGHTSEEING',
    'SHOPPING',
    'OTHER',
  ];

  static String eventType(BuildContext context, String value) {
    final AppLocalizations l = AppLocalizations.of(context);
    switch (value) {
      case 'TRANSPORT':
        return l.evtTRANSPORT;
      case 'HOTEL':
        return l.evtHOTEL;
      case 'FOOD':
        return l.evtFOOD;
      case 'ACTIVITY':
        return l.evtACTIVITY;
      case 'SIGHTSEEING':
        return l.evtSIGHTSEEING;
      case 'SHOPPING':
        return l.evtSHOPPING;
      default:
        return l.evtOTHER;
    }
  }

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

  static const List<String> placeTypes = [
    'HOTEL', 'RESTAURANT', 'ATTRACTION', 'AIRPORT', 'STATION', 'SHOPPING',
    'OTHER', //
  ];

  static String placeType(BuildContext context, String value) {
    final AppLocalizations l = AppLocalizations.of(context);
    switch (value) {
      case 'HOTEL':
        return l.ptHOTEL;
      case 'RESTAURANT':
        return l.ptRESTAURANT;
      case 'ATTRACTION':
        return l.ptATTRACTION;
      case 'AIRPORT':
        return l.ptAIRPORT;
      case 'STATION':
        return l.ptSTATION;
      case 'SHOPPING':
        return l.ptSHOPPING;
      default:
        return l.ptOTHER;
    }
  }

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
