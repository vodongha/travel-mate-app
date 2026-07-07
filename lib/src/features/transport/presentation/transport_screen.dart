import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/labels.dart';
import '../../../core/responsive.dart';
import '../../tickets/application/tickets_controller.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../trips/application/trips_controller.dart';
import '../application/transport_controller.dart';
import '../data/transport_repository.dart';

class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key, required this.tripRid});

  final String tripRid;

  Future<void> _rowActions(
      BuildContext context, WidgetRef ref, TransportItem item) async {
    final String title = _titleOf(context, item);
    final RowAction? action = await showRowActions(context, title: title);
    if (action == null || !context.mounted) {
      return;
    }
    if (action == RowAction.edit) {
      context.push('/trips/$tripRid/transports/${item.rid}/edit', extra: item);
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(transportControllerProvider(tripRid).notifier)
          .delete(item.rid);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  /// Read-only detail (the eye / tap action). Carrier, booking code and seat are read back from the
  /// caller's own ticket for this leg, if any. Long-press is for edit/delete.
  void _showDetail(BuildContext context, TransportItem item, Ticket? tk) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();
    String dt(DateTime? t) =>
        t == null ? '' : DateFormat.yMMMEd(locale).add_Hm().format(t.toLocal());
    final List<(String, String)> rows = [
      (l10n.fieldType, Labels.transportType(context, item.transportType)),
      (l10n.transportFrom, item.departurePlace ?? ''),
      (l10n.transportTo, item.arrivalPlace ?? ''),
      (l10n.transportDeparture, dt(item.departureTime)),
      (l10n.transportArrival, dt(item.arrivalTime)),
      if (tk?.provider?.isNotEmpty == true)
        (l10n.transportProvider, tk!.provider!),
      if (tk?.bookingCode?.isNotEmpty == true)
        (l10n.fieldBookingCode, tk!.bookingCode!),
      if (tk?.seat?.isNotEmpty == true) (l10n.fieldSeat, tk!.seat!),
      (l10n.eventNote, item.note ?? ''),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Grow + scroll so long detail never overflows off the bottom.
      isScrollControlled: true,
      builder: (ctx) {
        final ColorScheme scheme = Theme.of(ctx).colorScheme;
        final TextTheme text = Theme.of(ctx).textTheme;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(_iconOf(item.transportType), color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                        child:
                            Text(_titleOf(ctx, item), style: text.titleLarge)),
                  ]),
                  const SizedBox(height: 14),
                  for (final (String label, String value) in rows)
                    if (value.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
                                style: text.labelSmall
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                            Text(value, style: text.bodyLarge),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _titleOf(BuildContext context, TransportItem item) {
    final String from = item.departurePlace ?? '';
    final String to = item.arrivalPlace ?? '';
    if (from.isNotEmpty || to.isNotEmpty) {
      return '$from → $to';
    }
    return Labels.transportType(context, item.transportType);
  }

  static IconData _iconOf(String type) {
    switch (type) {
      case 'FLIGHT':
        return Icons.flight;
      case 'TRAIN':
        return Icons.train;
      case 'BUS':
        return Icons.directions_bus;
      case 'FERRY':
        return Icons.directions_boat;
      case 'TAXI':
        return Icons.local_taxi;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<TransportItem>> items =
        ref.watch(transportControllerProvider(tripRid));
    final bool canEdit =
        ref.watch(tripProvider(tripRid)).value?.myRole != 'VIEWER';
    // The caller's ticket per leg — its carrier/booking code/seat show in the read-only detail.
    final List<Ticket> myTickets =
        ref.watch(myTicketsControllerProvider(tripRid)).value ?? const [];
    final Map<String, Ticket> myTicketByLeg = {};
    for (final Ticket tk in myTickets) {
      if (tk.itineraryKind == 'TRANSPORT' && tk.itineraryRid != null) {
        myTicketByLeg.putIfAbsent(tk.itineraryRid!, () => tk);
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTransport)),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/trips/$tripRid/transports/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.transportNew),
            )
          : null,
      body: SafeArea(
        child: ResponsiveCenter(
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(transportControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.transportEmpty))
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(transportControllerProvider(tripRid)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _TransportCard(
                        item: list[i],
                        onView: () => _showDetail(
                            context, list[i], myTicketByLeg[list[i].rid]),
                        onMenu: canEdit
                            ? () => _rowActions(context, ref, list[i])
                            : null,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TransportCard extends StatelessWidget {
  const _TransportCard({required this.item, required this.onView, this.onMenu});

  final TransportItem item;
  // Read-only detail (tap / the eye icon).
  final VoidCallback onView;
  // null for a VIEWER (read-only) — hides the edit/delete menu (long-press).
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final String when = item.departureTime == null
        ? ''
        : DateFormat.MMMEd(locale)
            .add_Hm()
            .format(item.departureTime!.toLocal());
    final List<String> subParts = [
      Labels.transportType(context, item.transportType),
      if (when.isNotEmpty) when,
    ];
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: Icon(TransportScreen._iconOf(item.transportType)),
        ),
        title: Text(TransportScreen._titleOf(context, item),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subParts.join(' · '),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        // Tap / eye = read-only detail; long-press = edit/delete (editors only).
        trailing: IconButton(
          icon: const Icon(Icons.visibility_outlined),
          tooltip: AppLocalizations.of(context).actionView,
          onPressed: onView,
        ),
        onTap: onView,
        onLongPress: onMenu,
      ),
    );
  }
}
