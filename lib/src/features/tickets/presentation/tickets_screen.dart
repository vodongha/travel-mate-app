import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/responsive.dart';
import '../../expenses/presentation/itinerary_ref.dart';
import '../application/tickets_controller.dart';
import '../data/ticket_repository.dart';
import 'ticket_format.dart';

/// "My tickets" — the caller's own tickets (GET /tickets/mine). Tapping a ticket opens a
/// full-screen QR to show at the gate. A FAB adds a ticket. An action opens the trip-wide list.
class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key, required this.tripRid});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Ticket>> tickets =
        ref.watch(myTicketsControllerProvider(tripRid));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTickets),
        actions: [
          IconButton(
            tooltip: l10n.ticketsAll,
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => context.push('/trips/$tripRid/tickets/all'),
          ),
        ],
      ),
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
                    ref.invalidate(myTicketsControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.ticketsEmpty))
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(myTicketsControllerProvider(tripRid)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => TicketCard(
                        ticket: list[i],
                        onTap: () => context.push(
                          '/trips/$tripRid/tickets/${list[i].rid}/qr',
                          extra: list[i],
                        ),
                        onMenu: () => _rowActions(context, ref, list[i]),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A ticket list card: title, type icon + label and the owning member's name. Tapping opens the
/// full-screen QR; the overflow opens edit/delete.
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
    this.onMenu,
  });

  final Ticket ticket;
  final VoidCallback onTap;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<String> subParts = [
      ticketTypeLabel(context, ticket.ticketType),
      if (ticket.shared)
        l10n.ticketAssigneeGroup
      else if (ticket.memberName.isNotEmpty)
        ticket.memberName,
      if (ticket.seat?.isNotEmpty == true) '${l10n.fieldSeat} ${ticket.seat}',
      if (ticket.itineraryKind?.isNotEmpty == true)
        itinerarySectionLabel(context, ticket.itineraryKind!),
    ];
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: Icon(ticketTypeIcon(ticket.ticketType)),
        ),
        title: Text(ticket.title.isEmpty ? l10n.ticketUntitled : ticket.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subParts.join(' · '),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: onMenu == null
            ? const Icon(Icons.qr_code_2)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_2),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: l10n.actionEdit,
                    onPressed: onMenu,
                  ),
                ],
              ),
        onTap: onTap,
      ),
    );
  }
}
