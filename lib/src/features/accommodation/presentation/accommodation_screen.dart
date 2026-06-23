import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/responsive.dart';
import '../../tickets/application/tickets_controller.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../trips/application/trips_controller.dart';
import '../application/accommodation_controller.dart';
import '../data/accommodation_repository.dart';

class AccommodationScreen extends ConsumerWidget {
  const AccommodationScreen({super.key, required this.tripRid});

  final String tripRid;

  Future<void> _rowActions(
      BuildContext context, WidgetRef ref, AccommodationItem item) async {
    final RowAction? action = await showRowActions(context, title: item.name);
    if (action == null || !context.mounted) {
      return;
    }
    if (action == RowAction.edit) {
      context.push('/trips/$tripRid/accommodations/${item.rid}/edit',
          extra: item);
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(accommodationControllerProvider(tripRid).notifier)
          .delete(item.rid);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  /// Read-only detail (the eye / tap action). The booking code is read back from the caller's own
  /// ticket for this stay, if any. Long-press is for edit/delete.
  void _showDetail(BuildContext context, AccommodationItem item, Ticket? tk) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();
    String dt(DateTime? t) => t == null
        ? ''
        : DateFormat.yMMMEd(locale).add_Hm().format(t.toLocal());
    final List<(String, String)> rows = [
      (l10n.fieldAddress, item.address ?? ''),
      (l10n.accommodationCheckin, dt(item.checkinTime)),
      (l10n.accommodationCheckout, dt(item.checkoutTime)),
      if (tk?.bookingCode?.isNotEmpty == true)
        (l10n.fieldBookingCode, tk!.bookingCode!),
      (l10n.eventNote, item.note ?? ''),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
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
                    Icon(Icons.hotel_outlined, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.name, style: text.titleLarge)),
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
                                style: text.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<AccommodationItem>> items =
        ref.watch(accommodationControllerProvider(tripRid));
    final bool canEdit =
        ref.watch(tripProvider(tripRid)).valueOrNull?.myRole != 'VIEWER';
    // The caller's ticket per stay — its booking code shows in the read-only detail.
    final List<Ticket> myTickets =
        ref.watch(myTicketsControllerProvider(tripRid)).valueOrNull ?? const [];
    final Map<String, Ticket> myTicketByStay = {};
    for (final Ticket tk in myTickets) {
      if (tk.itineraryKind == 'ACCOMMODATION' && tk.itineraryRid != null) {
        myTicketByStay.putIfAbsent(tk.itineraryRid!, () => tk);
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccommodation)),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/trips/$tripRid/accommodations/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.accommodationNew),
            )
          : null,
      body: SafeArea(
        child: ResponsiveCenter(
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(accommodationControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.accommodationEmpty))
                : RefreshIndicator(
                    onRefresh: () async => ref
                        .invalidate(accommodationControllerProvider(tripRid)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _AccommodationCard(
                        item: list[i],
                        onView: () => _showDetail(
                            context, list[i], myTicketByStay[list[i].rid]),
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

class _AccommodationCard extends StatelessWidget {
  const _AccommodationCard(
      {required this.item, required this.onView, this.onMenu});

  final AccommodationItem item;
  // Read-only detail (tap / the eye icon).
  final VoidCallback onView;
  // null for a VIEWER (read-only) — hides the edit/delete menu (long-press).
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateFormat fmt = DateFormat.MMMd(locale);
    final List<String> subParts = [
      if (item.address?.isNotEmpty == true) item.address!,
      if (item.checkinTime != null && item.checkoutTime != null)
        '${fmt.format(item.checkinTime!.toLocal())} – '
            '${fmt.format(item.checkoutTime!.toLocal())}'
      else if (item.checkinTime != null)
        fmt.format(item.checkinTime!.toLocal()),
    ];
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: const Icon(Icons.hotel_outlined),
        ),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subParts.isEmpty
            ? null
            : Text(subParts.join(' · '),
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
