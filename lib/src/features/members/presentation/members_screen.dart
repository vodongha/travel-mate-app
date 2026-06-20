import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/responsive.dart';
import '../../trips/presentation/trip_format.dart';
import '../application/members_controller.dart';
import '../domain/member.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key, required this.tripRid});

  final String tripRid;

  Future<void> _addGhost(BuildContext context, WidgetRef ref) async {
    final _AddGhostResult? result = await showDialog<_AddGhostResult>(
      context: context,
      builder: (_) => const _AddGhostDialog(),
    );
    if (result == null) {
      return;
    }
    try {
      await ref
          .read(membersControllerProvider(tripRid).notifier)
          .addGhost(result.name, result.role);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  Future<void> _remove(
      BuildContext context, WidgetRef ref, Member member) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(l10n.memberRemoveConfirm),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.actionCancel)),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.actionRemove),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) {
      return;
    }
    try {
      await ref
          .read(membersControllerProvider(tripRid).notifier)
          .remove(member.rid);
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
    final AsyncValue<List<Member>> members =
        ref.watch(membersControllerProvider(tripRid));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navMembers),
        actions: [
          IconButton(
            tooltip: l10n.inviteTitle,
            icon: const Icon(Icons.person_add_alt),
            onPressed: () => context.go('/trips/$tripRid/members/invite'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addGhost(context, ref),
        icon: const Icon(Icons.group_add),
        label: Text(l10n.actionAdd),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: members.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(membersControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.membersEmpty))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _MemberTile(
                      member: list[i],
                      onRemove: () => _remove(context, ref, list[i]),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onRemove});

  final Member member;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: member.ghost
            ? scheme.surfaceContainerHighest
            : scheme.primaryContainer,
        foregroundColor:
            member.ghost ? scheme.onSurfaceVariant : scheme.onPrimaryContainer,
        child: Icon(member.ghost ? Icons.person_outline : Icons.person),
      ),
      title: Text(member.displayName),
      subtitle: Row(
        children: [
          Text(roleLabel(context, member.role)),
          if (member.ghost) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text(l10n.memberGhostBadge),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              labelStyle: const TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
      trailing: member.role == 'OWNER'
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.actionRemove,
              onPressed: onRemove,
            ),
    );
  }
}

class _AddGhostResult {
  const _AddGhostResult(this.name, this.role);
  final String name;
  final String role;
}

class _AddGhostDialog extends StatefulWidget {
  const _AddGhostDialog();

  @override
  State<_AddGhostDialog> createState() => _AddGhostDialogState();
}

class _AddGhostDialogState extends State<_AddGhostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _role = 'VIEWER';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.memberAddTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.memberGhostHint,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.authName),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: InputDecoration(labelText: l10n.inviteRoleToGrant),
              items: [
                DropdownMenuItem(
                    value: 'VIEWER', child: Text(roleLabel(context, 'VIEWER'))),
                DropdownMenuItem(
                    value: 'EDITOR', child: Text(roleLabel(context, 'EDITOR'))),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'VIEWER'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel)),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _AddGhostResult(_name.text.trim(), _role));
            }
          },
          child: Text(l10n.actionAdd),
        ),
      ],
    );
  }
}
