import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/form_buttons.dart';
import '../../../core/responsive.dart';
import '../../trips/application/trips_controller.dart';
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.memberRemoveConfirm),
                const SizedBox(height: 20),
                FormButtons(
                  primaryLabel: l10n.actionRemove,
                  primaryDanger: true,
                  onPrimary: () => Navigator.pop(ctx, true),
                  onCancel: () => Navigator.pop(ctx, false),
                ),
              ],
            ),
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

  Future<void> _changeRole(
      BuildContext context, WidgetRef ref, Member member) async {
    final String? role = await showDialog<String>(
      context: context,
      builder: (_) => _ChangeRoleDialog(current: member.role),
    );
    if (role == null || role == member.role || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(membersControllerProvider(tripRid).notifier)
          .changeRole(member.rid, role);
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
    final bool isOwner =
        ref.watch(tripProvider(tripRid)).valueOrNull?.myRole == 'OWNER';
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
                      isOwner: isOwner,
                      onRemove: () => _remove(context, ref, list[i]),
                      onChangeRole: () => _changeRole(context, ref, list[i]),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

enum _MemberAction { changeRole, remove }

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.onRemove,
    required this.onChangeRole,
  });

  final Member member;
  final bool isOwner;
  final VoidCallback onRemove;
  final VoidCallback onChangeRole;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // The OWNER manages every other member's role and membership; non-owners and
    // the OWNER's own row have no actions.
    final bool showActions = isOwner && member.role != 'OWNER';
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
      trailing: !showActions
          ? null
          : PopupMenuButton<_MemberAction>(
              icon: const Icon(Icons.more_vert),
              tooltip: l10n.actionEdit,
              onSelected: (a) =>
                  a == _MemberAction.changeRole ? onChangeRole() : onRemove(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _MemberAction.changeRole,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(l10n.memberChangeRole),
                  ),
                ),
                PopupMenuItem(
                  value: _MemberAction.remove,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline, color: scheme.error),
                    title: Text(l10n.actionRemove,
                        style: TextStyle(color: scheme.error)),
                  ),
                ),
              ],
            ),
    );
  }
}

/// OWNER-only role picker. Only EDITOR/VIEWER are assignable — ownership transfer
/// is out of scope (the backend keeps a single OWNER).
class _ChangeRoleDialog extends StatefulWidget {
  const _ChangeRoleDialog({required this.current});

  final String current;

  @override
  State<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<_ChangeRoleDialog> {
  late String _role = widget.current == 'EDITOR' || widget.current == 'VIEWER'
      ? widget.current
      : 'VIEWER';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.memberChangeRole),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(height: 20),
          FormButtons(
            primaryLabel: l10n.actionSave,
            onPrimary: () => Navigator.pop(context, _role),
            onCancel: () => Navigator.pop(context),
          ),
        ],
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
            const SizedBox(height: 20),
            FormButtons(
              primaryLabel: l10n.actionAdd,
              onPrimary: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(
                      context, _AddGhostResult(_name.text.trim(), _role));
                }
              },
              onCancel: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
