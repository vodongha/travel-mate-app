import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'form_buttons.dart';

/// A row action chosen from the long-press / overflow sheet.
enum RowAction { edit, delete }

/// Shows a small bottom sheet offering Edit / Delete for a list row. Returns the
/// chosen action, or null if dismissed. Used consistently across the app so every
/// list (expenses, budgets, events, checklist, …) is editable and deletable the
/// same way (long-press a row).
Future<RowAction?> showRowActions(
  BuildContext context, {
  String? title,
  bool allowEdit = true,
  bool allowDelete = true,
}) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  return showModalBottomSheet<RowAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            ListTile(
              dense: true,
              title: Text(title,
                  style: Theme.of(ctx).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          if (allowEdit)
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.actionEdit),
              onTap: () => Navigator.pop(ctx, RowAction.edit),
            ),
          if (allowDelete)
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text(l10n.actionDelete,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () => Navigator.pop(ctx, RowAction.delete),
            ),
        ],
      ),
    ),
  );
}

/// Shows a confirm dialog before a destructive delete. Returns true only if the
/// user taps the red confirm. Every delete in the app must go through this.
Future<bool> confirmDelete(BuildContext context, {String? message}) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? l10n.deleteConfirmMessage),
          const SizedBox(height: 20),
          FormButtons(
            primaryLabel: l10n.actionDelete,
            primaryDanger: true,
            onPrimary: () => Navigator.pop(ctx, true),
            onCancel: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}
