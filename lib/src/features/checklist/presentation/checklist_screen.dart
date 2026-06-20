import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/responsive.dart';
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
    if (title == null || title.trim().isEmpty) {
      return;
    }
    try {
      await ref
          .read(checklistControllerProvider(tripRid).notifier)
          .add(title.trim());
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navChecklist)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAdd),
      ),
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
                        .map((item) => CheckboxListTile(
                              value: item.completed,
                              title: Text(
                                item.title,
                                style: item.completed
                                    ? const TextStyle(
                                        decoration: TextDecoration.lineThrough)
                                    : null,
                              ),
                              onChanged: (v) => ref
                                  .read(checklistControllerProvider(tripRid)
                                      .notifier)
                                  .toggle(item.rid, v ?? false),
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
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.checklistAddTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.checklistItem),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel)),
        FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: Text(l10n.actionAdd)),
      ],
    );
  }
}
