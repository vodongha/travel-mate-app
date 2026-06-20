import 'package:flutter/widgets.dart';

import '../../../../l10n/app_localizations.dart';

final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? requiredValidator(BuildContext context, String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppLocalizations.of(context).validationRequired;
  }
  return null;
}

String? emailValidator(BuildContext context, String? value) {
  final String v = (value ?? '').trim();
  if (v.isEmpty) {
    return AppLocalizations.of(context).validationRequired;
  }
  if (!_emailRe.hasMatch(v)) {
    return AppLocalizations.of(context).validationEmail;
  }
  return null;
}

String? passwordValidator(BuildContext context, String? value) {
  final String v = value ?? '';
  if (v.isEmpty) {
    return AppLocalizations.of(context).validationRequired;
  }
  if (v.length < 8) {
    return AppLocalizations.of(context).validationPasswordShort;
  }
  return null;
}
