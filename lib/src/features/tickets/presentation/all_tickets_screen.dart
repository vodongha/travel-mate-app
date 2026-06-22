import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/responsive.dart';
import '../../trips/application/trips_controller.dart';
import '../application/tickets_controller.dart';
import '../data/ticket_repository.dart';
import 'tickets_screen.dart';

/// Trip-wide ticket list (GET /tickets), grouped by member. Anyone can view; you may always manage
/// your OWN ticket, and an EDITOR/OWNER may manage anyone's (the server enforces the 403).
class AllTicketsScreen extends ConsumerWidget {
  const AllTicketsScreen({super.key, required this.tripRid});

  final String tripRid;

  Future<void> _rowActions(
      BuildContext context, WidgetRef ref, Ticket ticket) async {
    final RowAction? action =
        await showRowActions(context, title: ticket.title);
    if (action == null || !context.mounted) {
      return;
    }
    if (action == RowAction.edit) {
      context.push('/trips/$tripRid/tickets/${ticket.rid}/edit', extra: ticket);
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(allTicketsControllerProvider(tripRid).notifier)
          .remove(ticket.rid);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  /// Groups tickets by member, preserving first-seen order; the caller's group first. Group tickets
  /// (no owner) are gathered under [groupLabel].
  List<MapEntry<String, List<Ticket>>> _grouped(
      List<Ticket> list, String groupLabel) {
    final Map<String, List<Ticket>> byMember = {};
    for (final Ticket t in list) {
      final String name = t.shared
          ? groupLabel
          : (t.memberName.isEmpty ? t.memberRid : t.memberName);
      byMember.putIfAbsent(name, () => <Ticket>[]).add(t);
    }
    final List<MapEntry<String, List<Ticket>>> entries =
        byMember.entries.toList();
    // Put any group containing the caller's own tickets first.
    entries.sort((a, b) {
      final bool aMine = a.value.any((t) => t.mine);
      final bool bMine = b.value.any((t) => t.mine);
      if (aMine == bMine) {
        return 0;
      }
      return aMine ? -1 : 1;
    });
    return entries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? myRole = ref.watch(tripProvider(tripRid)).valueOrNull?.myRole;
    final bool isEditor = myRole == 'OWNER' || myRole == 'EDITOR';
    final AsyncValue<List<Ticket>> tickets =
        ref.watch(allTicketsControllerProvider(tripRid));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ticketsAll)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trips/$tripRid/tickets/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.ticketNew),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: tickets.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(allTicketsControllerProvider(tripRid))),
            data: (list) {
              if (list.isEmpty) {
                return Center(child: Text(l10n.ticketsEmpty));
              }
              final List<MapEntry<String, List<Ticket>>> groups =
                  _grouped(list, l10n.ticketAssigneeGroup);
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(allTicketsControllerProvider(tripRid)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    for (final MapEntry<String, List<Ticket>> g in groups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                        child: Text(
                          g.key,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      for (final Ticket t in g.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TicketCard(
                            ticket: t,
                            onTap: () => context.push(
                              '/trips/$tripRid/tickets/${t.rid}/qr',
                              extra: t,
                            ),
                            // You can always manage your own; an editor manages anyone's.
                            onMenu: (t.mine || isEditor)
                                ? () => _rowActions(context, ref, t)
                                : null,
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
