import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'api_client.dart';

/// Maps any thrown error to a localized, user-safe message. A server-supplied problem `detail`
/// (e.g. "Email is already registered.") is shown as-is; connection failures and everything else
/// fall back to localized generic copy — Dio's verbose internals never reach the UI.
String friendlyError(BuildContext context, Object error) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  if (error is ApiException) {
    if (error.isConnection) {
      return l10n.errorConnection;
    }
    if (error.serverDetail) {
      return error.message;
    }
  }
  return l10n.errorGeneric;
}
