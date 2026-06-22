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
          .addGhost(result.name, result.role, email: result.email);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  Future<void> _editGhost(
      BuildContext context, WidgetRef ref, Member member) async {
    final _AddGhostResult? result = await showDialog<_AddGhostResult>(
      context: context,
      builder: (_) => _EditGhostDialog(member: member),
    );
    if (result == null) {
      return;
    }
    try {
      await ref
          .read(membersControllerProvider(tripRid).notifier)
          .editGhost(member.rid, displayName: result.name, email: result.email ?? '');
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  Future<void> _merge(BuildContext context, WidgetRef ref, Member source,
      List<Member> all) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<Member> targets =
        all.where((m) => m.rid != source.rid).toList(growable: false);
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.memberMergeEmpty)));
      return;
    }
    final Member? target = await showModalBottomSheet<Member>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(l10n.memberMergePrompt(source.displayName),
                  style: Theme.of(ctx).textTheme.bodyMedium),
            ),
            for (final Member m in targets)
              ListTile(
                leading: Icon(m.ghost ? Icons.person_outline : Icons.person),
                title: Text(m.displayName),
                subtitle: Text(roleLabel(ctx, m.role)),
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (target == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(membersControllerProvider(tripRid).notifier)
          .merge(source.rid, target.rid);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.memberMergeDone)));
      }
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
            onPressed: () => context.push('/trips/$tripRid/members/invite'),
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
                      onEdit: () => _editGhost(context, ref, list[i]),
                      onMerge: () => _merge(context, ref, list[i], list),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

enum _MemberAction { changeRole, edit, merge, remove }

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.onRemove,
    required this.onChangeRole,
    required this.onEdit,
    required this.onMerge,
  });

  final Member member;
  final bool isOwner;
  final VoidCallback onRemove;
  final VoidCallback onChangeRole;
  final VoidCallback onEdit;
  final VoidCallback onMerge;

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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (member.ghost && (member.email?.isNotEmpty ?? false))
            Text(member.email!,
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
      trailing: !showActions
          ? null
          : PopupMenuButton<_MemberAction>(
              icon: const Icon(Icons.more_vert),
              tooltip: l10n.actionEdit,
              onSelected: (a) {
                switch (a) {
                  case _MemberAction.changeRole:
                    onChangeRole();
                  case _MemberAction.edit:
                    onEdit();
                  case _MemberAction.merge:
                    onMerge();
                  case _MemberAction.remove:
                    onRemove();
                }
              },
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
                if (member.ghost)
                  PopupMenuItem(
                    value: _MemberAction.edit,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l10n.actionEdit),
                    ),
                  ),
                PopupMenuItem(
                  value: _MemberAction.merge,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.merge_outlined),
                    title: Text(l10n.memberMergeAction),
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
  const _AddGhostResult(this.name, this.email, this.role);
  final String name;
  final String? email;
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
  final _email = TextEditingController();
  String _role = 'VIEWER';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
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
            _GhostEmailField(controller: _email, l10n: l10n),
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
                  Navigator.pop(context,
                      _AddGhostResult(_name.text.trim(), _email.text.trim(), _role));
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

/// Edit a ghost's name + email (role is changed via the separate role action).
class _EditGhostDialog extends StatefulWidget {
  const _EditGhostDialog({required this.member});

  final Member member;

  @override
  State<_EditGhostDialog> createState() => _EditGhostDialogState();
}

class _EditGhostDialogState extends State<_EditGhostDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.member.displayName);
  late final TextEditingController _email =
      TextEditingController(text: widget.member.email ?? '');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.memberEditTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            _GhostEmailField(controller: _email, l10n: l10n),
            const SizedBox(height: 20),
            FormButtons(
              primaryLabel: l10n.actionSave,
              onPrimary: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context,
                      _AddGhostResult(_name.text.trim(), _email.text.trim(), widget.member.role));
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

/// Optional email field for a ghost, with a light format check and a hint about auto-merge.
class _GhostEmailField extends StatelessWidget {
  const _GhostEmailField({required this.controller, required this.l10n});

  final TextEditingController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: l10n.memberEmailLabel,
        helperText: l10n.memberEmailHint,
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.mail_outline),
      ),
      validator: (v) {
        final String s = (v ?? '').trim();
        if (s.isEmpty) {
          return null; // optional
        }
        return s.contains('@') && s.contains('.')
            ? null
            : l10n.validationEmail;
      },
    );
  }
}
