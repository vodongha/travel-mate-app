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
    if (error.isTimeout) {
      return l10n.errorTimeout;
    }
    // A meaningful server-supplied reason (e.g. "Email is already registered.") is the friendliest
    // message we have — show it as-is.
    if (error.serverDetail) {
      return error.message;
    }
    // No server detail: fall back to friendly copy keyed on the status family.
    switch (error.statusCode) {
      case 401:
        return l10n.errorSession;
      case 403:
        return l10n.errorForbidden;
      case 404:
        return l10n.errorNotFound;
    }
    if (error.statusCode != null && error.statusCode! >= 500) {
      return l10n.errorServer;
    }
  }
  return l10n.errorGeneric;
}
