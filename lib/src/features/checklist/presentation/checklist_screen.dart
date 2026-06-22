import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/form_buttons.dart';
import '../../../core/responsive.dart';
import '../../trips/application/trips_controller.dart';
import '../application/checklist_controller.dart';
import '../data/checklist_repository.dart';

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key, required this.tripRid});

  final String tripRid;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final String? title = await showDialog<String>(
      context: context,
      builder: (_) => const _AddItemDialog(),
    );
    if (title == null || title.trim().isEmpty || !context.mounted) {
      return;
    }
    await _run(
        context,
        () => ref
            .read(checklistControllerProvider(tripRid).notifier)
            .add(title.trim()));
  }

  Future<void> _rowActions(
      BuildContext context, WidgetRef ref, ChecklistItem item) async {
    final RowAction? action = await showRowActions(context, title: item.title);
    if (action == null || !context.mounted) {
      return;
    }
    if (action == RowAction.edit) {
      final String? title = await showDialog<String>(
        context: context,
        builder: (_) => _AddItemDialog(initial: item.title),
      );
      if (title == null || title.trim().isEmpty || !context.mounted) {
        return;
      }
      await _run(
          context,
          () => ref
              .read(checklistControllerProvider(tripRid).notifier)
              .rename(item.rid, title.trim()));
    } else {
      if (!await confirmDelete(context) || !context.mounted) {
        return;
      }
      await _run(
          context,
          () => ref
              .read(checklistControllerProvider(tripRid).notifier)
              .remove(item.rid));
    }
  }

  Future<void> _run(BuildContext context, Future<void> Function() op) async {
    try {
      await op();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<ChecklistItem>> items =
        ref.watch(checklistControllerProvider(tripRid));
    // A VIEWER can still tick items off, but can't add/edit/delete them.
    final bool canEdit =
        ref.watch(tripProvider(tripRid)).valueOrNull?.myRole != 'VIEWER';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navChecklist)),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.actionAdd),
            )
          : null,
      body: SafeArea(
        child: ResponsiveCenter(
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(checklistControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.checklistEmpty))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                    children: list
                        .map((item) => GestureDetector(
                              onLongPress: canEdit
                                  ? () => _rowActions(context, ref, item)
                                  : null,
                              child: CheckboxListTile(
                                value: item.completed,
                                title: Text(
                                  item.title,
                                  style: item.completed
                                      ? const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough)
                                      : null,
                                ),
                                secondary: canEdit
                                    ? IconButton(
                                        icon: const Icon(Icons.more_vert),
                                        tooltip: AppLocalizations.of(context)
                                            .actionEdit,
                                        onPressed: () =>
                                            _rowActions(context, ref, item),
                                      )
                                    : null,
                                onChanged: (v) => ref
                                    .read(checklistControllerProvider(tripRid)
                                        .notifier)
                                    .toggle(item.rid, v ?? false),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog({this.initial});

  final String? initial;

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool editing = widget.initial != null;
    return AlertDialog(
      title: Text(editing ? l10n.checklistEditTitle : l10n.checklistAddTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.checklistItem),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          const SizedBox(height: 20),
          FormButtons(
            primaryLabel: editing ? l10n.actionSave : l10n.actionAdd,
            onPrimary: () => Navigator.pop(context, _controller.text),
            onCancel: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
