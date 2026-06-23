import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/labels.dart';
import '../../../core/maps.dart';
import '../../../core/money.dart';
import '../../../core/responsive.dart';
import '../../accommodation/application/accommodation_controller.dart';
import '../../accommodation/data/accommodation_repository.dart';
import '../../expenses/application/expenses_controller.dart';
import '../../expenses/data/expense_repository.dart';
import '../../places/application/place_controller.dart';
import '../../places/data/place_repository.dart';
import '../../tickets/application/tickets_controller.dart';
import '../../tickets/data/ticket_repository.dart';
import '../../transport/application/transport_controller.dart';
import '../../transport/data/transport_repository.dart';
import '../../trips/application/trips_controller.dart';
import '../application/events_controller.dart';
import '../data/event_repository.dart';

/// One thing happening on the trip — an event, a transport leg, or a stay — placed on the day-by-day
/// itinerary. The timeline is the trip's main axis; everything with a time shows up here.
class _Entry {
  _Entry({
    required this.when,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onLongPress,
  });

  final DateTime? when; // local time, null = no time set
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; // e.g. open the entry's place in Google Maps
}

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key, required this.tripRid});

  final String tripRid;

  String _dt(BuildContext context, DateTime? t) => t == null
      ? ''
      : DateFormat.yMMMEd(Localizations.localeOf(context).toLanguageTag())
          .add_Hm()
          .format(t.toLocal());

  /// Read-only detail of an itinerary item (the eye / tap action). Long-press is for edit/delete.
  /// [rows] are (label, value) pairs; blanks are skipped. An "Open in Maps" button shows when
  /// [onMaps] is given.
  void _showDetail(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<(String, String)> rows,
    VoidCallback? onMaps,
  }) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Let the sheet grow with its content and scroll, so long detail (carrier/code/seat/note)
      // never overflows off the bottom of the screen.
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
                    Icon(icon, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(title, style: text.titleLarge)),
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
                  if (onMaps != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onMaps();
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: Text(l10n.openInMaps),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _eventActions(BuildContext context, WidgetRef ref,
      EventItem event, PlaceItem? place, bool canEdit) async {
    // A VIEWER only ever gets "Open in Google Maps" (read-only); nothing to show
    // if there's no place either.
    if (!canEdit && place == null) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (place != null)
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(l10n.openInMaps),
                onTap: () => Navigator.pop(ctx, 'maps'),
              ),
            if (canEdit) ...[
              ListTile(
                leading: const Icon(Icons.add_card_outlined),
                title: Text(l10n.expenseNew),
                onTap: () => Navigator.pop(ctx, 'expense'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.actionEdit),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text(l10n.actionDelete,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) {
      return;
    }
    if (action == 'maps' && place != null) {
      await openInGoogleMaps(context,
          lat: place.latitude, lng: place.longitude, query: place.name);
      return;
    }
    if (action == 'edit') {
      context.push('/trips/$tripRid/timeline/${event.rid}/edit', extra: event);
      return;
    }
    if (action == 'expense') {
      // Pre-attach the new expense to this event (polymorphic itinerary link).
      context.push('/trips/$tripRid/expenses/new',
          extra: (kind: 'EVENT', rid: event.rid));
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(eventsControllerProvider(tripRid).notifier)
          .delete(event.rid);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  /// Long-press / tap actions for a transport leg or accommodation stay on the timeline: attach an
  /// expense, edit, or delete. Mirrors [_eventActions] for the dedicated itinerary entities.
  Future<void> _itemActions(
    BuildContext context,
    WidgetRef ref, {
    required bool canEdit,
    required String kind, // 'TRANSPORT' | 'ACCOMMODATION'
    required String rid,
    required String editPath,
    required Object editExtra,
    required Future<void> Function() onDelete,
  }) async {
    // Transport/accommodation rows have no read-only action — a VIEWER can't edit
    // them, so the sheet would be empty.
    if (!canEdit) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_card_outlined),
              title: Text(l10n.expenseNew),
              onTap: () => Navigator.pop(ctx, 'expense'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.actionEdit),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text(l10n.actionDelete,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) {
      return;
    }
    if (action == 'expense') {
      context
          .push('/trips/$tripRid/expenses/new', extra: (kind: kind, rid: rid));
      return;
    }
    if (action == 'edit') {
      context.push(editPath, extra: editExtra);
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await onDelete();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  /// "+" on the timeline: pick what kind of itinerary item to add. Transport and accommodation are
  /// their own entities (single source of truth, shown here and on their own screens); everything
  /// else is a generic event.
  Future<void> _addToItinerary(
      BuildContext context, AppLocalizations l10n) async {
    final String? choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: Text(l10n.itineraryEvents),
              onTap: () => Navigator.pop(ctx, 'event'),
            ),
            ListTile(
              leading: const Icon(Icons.directions_transit_outlined),
              title: Text(l10n.navTransport),
              onTap: () => Navigator.pop(ctx, 'transport'),
            ),
            ListTile(
              leading: const Icon(Icons.hotel_outlined),
              title: Text(l10n.navAccommodation),
              onTap: () => Navigator.pop(ctx, 'accommodation'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) {
      return;
    }
    switch (choice) {
      case 'transport':
        context.push('/trips/$tripRid/transports/new');
      case 'accommodation':
        context.push('/trips/$tripRid/accommodations/new');
      default:
        context.push('/trips/$tripRid/timeline/new');
    }
  }

  static IconData _eventIcon(String type) {
    switch (type) {
      case 'TRANSPORT':
        return Icons.commute_outlined;
      case 'ACCOMMODATION':
        return Icons.hotel_outlined;
      case 'FOOD':
        return Icons.restaurant_outlined;
      case 'SIGHTSEEING':
        return Icons.attractions_outlined;
      case 'SHOPPING':
        return Icons.shopping_bag_outlined;
      case 'ACTIVITY':
        return Icons.local_activity_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  static IconData _transportIcon(String type) {
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

  List<_Entry> _entries(
    BuildContext context,
    WidgetRef ref,
    List<EventItem> events,
    List<TransportItem> transports,
    List<AccommodationItem> stays,
    List<PlaceItem> places,
    List<ExpenseItem> expenses,
    List<Ticket> myTickets,
    String baseCurrency,
    bool canEdit,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // The caller's ticket for each transport leg — carrier/booking code/seat are read from it (the
    // leg itself no longer carries them). First mine ticket linked to the leg wins.
    final Map<String, Ticket> myTicketByLeg = {};
    for (final Ticket tk in myTickets) {
      if (tk.itineraryKind == 'TRANSPORT' && tk.itineraryRid != null) {
        myTicketByLeg.putIfAbsent(tk.itineraryRid!, () => tk);
      }
    }
    final Map<String, PlaceItem> placeByRid = {
      for (final PlaceItem p in places) p.rid: p
    };
    // Sum each itinerary item's attached expenses (already in the trip's base currency). Keyed by
    // "KIND:rid" so events, transport legs and stays each accumulate their own costs.
    final Map<String, num> costByItem = {};
    for (final ExpenseItem x in expenses) {
      if (x.itineraryKind != null && x.itineraryRid != null) {
        final String k = '${x.itineraryKind}:${x.itineraryRid}';
        costByItem[k] = (costByItem[k] ?? 0) + x.amountBase;
      }
    }
    final List<_Entry> entries = [];

    for (final EventItem e in events) {
      final PlaceItem? pl = e.placeRid == null ? null : placeByRid[e.placeRid];
      final num cost = costByItem['EVENT:${e.rid}'] ?? 0;
      entries.add(_Entry(
        when: e.startTime?.toLocal(),
        icon: _eventIcon(e.eventType),
        title: e.title,
        subtitle: [
          Labels.eventType(context, e.eventType),
          if (pl != null && pl.name.isNotEmpty) pl.name,
          if (cost > 0) Money.format(cost, baseCurrency),
        ].join(' · '),
        // Tap = read-only detail (the eye); long-press = the actions menu.
        onTap: () => _showDetail(context,
            title: e.title.isEmpty ? Labels.eventType(context, e.eventType) : e.title,
            icon: _eventIcon(e.eventType),
            rows: [
              (l10n.fieldType, Labels.eventType(context, e.eventType)),
              (l10n.eventStart, _dt(context, e.startTime)),
              if (pl != null) (l10n.eventLocation, pl.name),
              if (cost > 0) (l10n.timelineCosts, Money.format(cost, baseCurrency)),
              (l10n.eventNote, e.note ?? ''),
            ],
            onMaps: (pl != null && pl.latitude != null && pl.longitude != null)
                ? () => openInGoogleMaps(context,
                    lat: pl.latitude, lng: pl.longitude, query: pl.name)
                : null),
        onLongPress: () => _eventActions(context, ref, e, pl, canEdit),
      ));
    }
    for (final TransportItem t in transports) {
      final String route = [
        if (t.departurePlace?.isNotEmpty == true) t.departurePlace!,
        if (t.arrivalPlace?.isNotEmpty == true) t.arrivalPlace!,
      ].join(' → ');
      final num cost = costByItem['TRANSPORT:${t.rid}'] ?? 0;
      // Carrier/booking code/seat come from the caller's own ticket for this leg, if any.
      final Ticket? tk = myTicketByLeg[t.rid];
      entries.add(_Entry(
        when: t.departureTime?.toLocal(),
        icon: _transportIcon(t.transportType),
        // The leg shows only what/where/when — the carrier/booking code live on the ticket.
        title: route.isNotEmpty
            ? route
            : Labels.transportType(context, t.transportType),
        subtitle: [
          l10n.navTransport,
          if (cost > 0) Money.format(cost, baseCurrency),
        ].join(' · '),
        onTap: () => _showDetail(context,
            title: route.isNotEmpty
                ? route
                : Labels.transportType(context, t.transportType),
            icon: _transportIcon(t.transportType),
            rows: [
              (l10n.fieldType, Labels.transportType(context, t.transportType)),
              (l10n.transportFrom, t.departurePlace ?? ''),
              (l10n.transportTo, t.arrivalPlace ?? ''),
              (l10n.eventStart, _dt(context, t.departureTime)),
              // Read back from "my ticket" for this leg (carrier, booking code, seat).
              if (tk?.provider?.isNotEmpty == true)
                (l10n.transportProvider, tk!.provider!),
              if (tk?.bookingCode?.isNotEmpty == true)
                (l10n.fieldBookingCode, tk!.bookingCode!),
              if (tk?.seat?.isNotEmpty == true) (l10n.fieldSeat, tk!.seat!),
              if (cost > 0) (l10n.timelineCosts, Money.format(cost, baseCurrency)),
              (l10n.eventNote, t.note ?? ''),
            ]),
        onLongPress: () => _itemActions(context, ref,
            canEdit: canEdit,
            kind: 'TRANSPORT',
            rid: t.rid,
            editPath: '/trips/$tripRid/transports/${t.rid}/edit',
            editExtra: t,
            onDelete: () => ref
                .read(transportControllerProvider(tripRid).notifier)
                .delete(t.rid)),
      ));
    }
    for (final AccommodationItem a in stays) {
      final num cost = costByItem['ACCOMMODATION:${a.rid}'] ?? 0;
      entries.add(_Entry(
        when: a.checkinTime?.toLocal(),
        icon: Icons.hotel_outlined,
        title: a.name,
        subtitle: [
          l10n.accommodationCheckin,
          if (cost > 0) Money.format(cost, baseCurrency),
        ].join(' · '),
        onTap: () => _showDetail(context,
            title: a.name,
            icon: Icons.hotel_outlined,
            rows: [
              (l10n.eventLocation, a.address ?? ''),
              (l10n.accommodationCheckin, _dt(context, a.checkinTime)),
              (l10n.accommodationCheckout, _dt(context, a.checkoutTime)),
              if (cost > 0) (l10n.timelineCosts, Money.format(cost, baseCurrency)),
              (l10n.eventNote, a.note ?? ''),
            ]),
        onLongPress: () => _itemActions(context, ref,
            canEdit: canEdit,
            kind: 'ACCOMMODATION',
            rid: a.rid,
            editPath: '/trips/$tripRid/accommodations/${a.rid}/edit',
            editExtra: a,
            onDelete: () => ref
                .read(accommodationControllerProvider(tripRid).notifier)
                .delete(a.rid)),
      ));
    }

    // Sort by time; undated entries sink to the bottom.
    entries.sort((a, b) {
      if (a.when == null && b.when == null) return 0;
      if (a.when == null) return 1;
      if (b.when == null) return -1;
      return a.when!.compareTo(b.when!);
    });
    return entries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<EventItem>> events =
        ref.watch(eventsControllerProvider(tripRid));
    final List<TransportItem> transports =
        ref.watch(transportControllerProvider(tripRid)).valueOrNull ?? const [];
    final List<AccommodationItem> stays =
        ref.watch(accommodationControllerProvider(tripRid)).valueOrNull ??
            const [];
    final List<PlaceItem> places =
        ref.watch(placeControllerProvider(tripRid)).valueOrNull ?? const [];
    final List<ExpenseItem> expenses =
        ref.watch(expensesControllerProvider(tripRid)).valueOrNull ?? const [];
    final List<Ticket> myTickets =
        ref.watch(myTicketsControllerProvider(tripRid)).valueOrNull ?? const [];
    final trip = ref.watch(tripProvider(tripRid)).valueOrNull;
    final String baseCurrency = trip?.baseCurrency ?? 'VND';
    final bool canEdit = trip?.myRole != 'VIEWER';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTimeline)),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _addToItinerary(context, l10n),
              icon: const Icon(Icons.add),
              label: Text(l10n.eventNew),
            )
          : null,
      body: SafeArea(
        child: ResponsiveCenter(
          child: events.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(eventsControllerProvider(tripRid))),
            data: (list) {
              final List<_Entry> entries = _entries(context, ref, list,
                  transports, stays, places, expenses, myTickets, baseCurrency,
                  canEdit);
              if (entries.isEmpty) {
                return Center(child: Text(l10n.timelineEmpty));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(eventsControllerProvider(tripRid));
                  ref.invalidate(transportControllerProvider(tripRid));
                  ref.invalidate(accommodationControllerProvider(tripRid));
                  ref.invalidate(placeControllerProvider(tripRid));
                  ref.invalidate(expensesControllerProvider(tripRid));
                  ref.invalidate(myTicketsControllerProvider(tripRid));
                },
                child: _DayTimeline(entries: entries),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Renders entries grouped under day headers, each day a connected vertical rail.
class _DayTimeline extends StatefulWidget {
  const _DayTimeline({required this.entries});

  final List<_Entry> entries;

  @override
  State<_DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends State<_DayTimeline> {
  final GlobalKey _targetKey = GlobalKey();
  bool _scrolledToNow = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateFormat dayFmt = DateFormat.yMMMMEEEEd(locale);
    final DateTime now = DateTime.now();

    // Find the entry happening "now" (the last one that has already started
    // today) and the next upcoming one, so we can make them stand out.
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    _Entry? currentEntry;
    _Entry? nextEntry;
    for (final _Entry e in widget.entries) {
      final DateTime? w = e.when;
      if (w == null) {
        continue;
      }
      if (w.isAfter(now)) {
        nextEntry ??= e;
      } else if (sameDay(w, now)) {
        currentEntry = e;
      }
    }
    // On first open, scroll to what's happening now (or the next thing coming up).
    final _Entry? scrollTarget = currentEntry ?? nextEntry;

    // Group consecutive (already time-sorted) entries by calendar day.
    final List<Widget> children = [];
    String? currentKey;
    List<_Entry> bucket = [];

    void flush() {
      if (bucket.isEmpty) {
        return;
      }
      final _Entry head = bucket.first;
      children.add(_header(
        context,
        head.when == null ? l10n.timelineUndated : dayFmt.format(head.when!),
      ));
      for (int i = 0; i < bucket.length; i++) {
        final _Entry e = bucket[i];
        final Widget tile = _TimelineTile(
          entry: e,
          isFirst: i == 0,
          isLast: i == bucket.length - 1,
          isCurrent: identical(e, currentEntry),
          isNext: identical(e, nextEntry),
        );
        children.add(identical(e, scrollTarget)
            ? KeyedSubtree(key: _targetKey, child: tile)
            : tile);
      }
      bucket = [];
    }

    for (final _Entry e in widget.entries) {
      final String key = e.when == null
          ? '_'
          : '${e.when!.year}-${e.when!.month}-${e.when!.day}';
      if (key != currentKey) {
        flush();
        currentKey = key;
      }
      bucket.add(e);
    }
    flush();

    if (!_scrolledToNow && scrollTarget != null) {
      _scrolledToNow = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? c = _targetKey.currentContext;
        if (c != null) {
          Scrollable.ensureVisible(c,
              alignment: 0.15,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut);
        }
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: children,
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      );
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.isCurrent,
    required this.isNext,
  });

  final _Entry entry;
  final bool isFirst;
  final bool isLast;
  final bool isCurrent;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final String time =
        entry.when == null ? '' : DateFormat.Hm(locale).format(entry.when!);
    final Color line = scheme.outlineVariant;
    final bool highlight = isCurrent || isNext;

    // The "now" item uses the primary accent; the next upcoming one the
    // tertiary accent, so the two are visually distinct from each other.
    final Color dotColor = isCurrent
        ? scheme.primary
        : isNext
            ? scheme.tertiary
            : scheme.tertiary.withValues(alpha: 0.55);
    final Color? cardColor = isCurrent
        ? scheme.primaryContainer
        : isNext
            ? scheme.tertiaryContainer
            : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Expanded(
                    child: Container(
                        width: 2, color: isFirst ? Colors.transparent : line)),
                Container(
                  width: highlight ? 16 : 14,
                  height: highlight ? 16 : 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
                Expanded(
                    child: Container(
                        width: 2, color: isLast ? Colors.transparent : line)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Card(
                color: cardColor,
                child: ListTile(
                  leading: Icon(entry.icon),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(entry.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (isCurrent || isNext)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _NowChip(
                            label: isCurrent
                                ? l10n.timelineNow
                                : l10n.timelineUpcoming,
                            current: isCurrent,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    time.isEmpty ? entry.subtitle : '$time · ${entry.subtitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.visibility_outlined),
                  onTap: entry.onTap,
                  onLongPress: entry.onLongPress,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small "Happening now" / "Upcoming" badge on a highlighted timeline tile.
class _NowChip extends StatelessWidget {
  const _NowChip({required this.label, required this.current});

  final String label;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color bg = current ? scheme.primary : scheme.tertiary;
    final Color fg = current ? scheme.onPrimary : scheme.onTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
