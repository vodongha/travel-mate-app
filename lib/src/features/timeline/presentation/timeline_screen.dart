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

  Future<void> _eventActions(
      BuildContext context, WidgetRef ref, EventItem event) async {
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
    if (action == 'edit') {
      context.push('/trips/$tripRid/timeline/${event.rid}/edit', extra: event);
      return;
    }
    if (action == 'expense') {
      // Pre-attach the new expense to this event.
      context.push('/trips/$tripRid/expenses/new', extra: event.rid);
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

  static IconData _eventIcon(String type) {
    switch (type) {
      case 'TRANSPORT':
        return Icons.commute_outlined;
      case 'HOTEL':
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
    String baseCurrency,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<String, PlaceItem> placeByRid = {
      for (final PlaceItem p in places) p.rid: p
    };
    // Sum each event's attached expenses (already in the trip's base currency).
    final Map<String, num> costByEvent = {};
    for (final ExpenseItem x in expenses) {
      if (x.eventRid != null) {
        costByEvent[x.eventRid!] =
            (costByEvent[x.eventRid!] ?? 0) + x.amountBase;
      }
    }
    final List<_Entry> entries = [];

    for (final EventItem e in events) {
      final PlaceItem? pl = e.placeRid == null ? null : placeByRid[e.placeRid];
      final num cost = costByEvent[e.rid] ?? 0;
      entries.add(_Entry(
        when: e.startTime?.toLocal(),
        icon: _eventIcon(e.eventType),
        title: e.title,
        subtitle: [
          Labels.eventType(context, e.eventType),
          if (pl != null && pl.name.isNotEmpty) pl.name,
          if (cost > 0) Money.format(cost, baseCurrency),
        ].join(' · '),
        onTap: () => _eventActions(context, ref, e),
        // Long-press an event with a place → open it in Google Maps.
        onLongPress: pl == null
            ? null
            : () => openInGoogleMaps(context,
                lat: pl.latitude, lng: pl.longitude, query: pl.name),
      ));
    }
    for (final TransportItem t in transports) {
      final String route = [
        if (t.departurePlace?.isNotEmpty == true) t.departurePlace!,
        if (t.arrivalPlace?.isNotEmpty == true) t.arrivalPlace!,
      ].join(' → ');
      entries.add(_Entry(
        when: t.departureTime?.toLocal(),
        icon: _transportIcon(t.transportType),
        title: route.isNotEmpty
            ? route
            : (t.provider?.isNotEmpty == true
                ? t.provider!
                : Labels.transportType(context, t.transportType)),
        subtitle: l10n.navTransport,
        onTap: () =>
            context.push('/trips/$tripRid/transports/${t.rid}/edit', extra: t),
      ));
    }
    for (final AccommodationItem a in stays) {
      entries.add(_Entry(
        when: a.checkinTime?.toLocal(),
        icon: Icons.hotel_outlined,
        title: a.name,
        subtitle: l10n.accommodationCheckin,
        onTap: () => context
            .push('/trips/$tripRid/accommodations/${a.rid}/edit', extra: a),
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
    final String baseCurrency =
        ref.watch(tripProvider(tripRid)).valueOrNull?.baseCurrency ?? 'VND';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTimeline)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trips/$tripRid/timeline/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.eventNew),
      ),
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
                  transports, stays, places, expenses, baseCurrency);
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
class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.entries});

  final List<_Entry> entries;

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
    for (final _Entry e in entries) {
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
        children.add(_TimelineTile(
          entry: e,
          isFirst: i == 0,
          isLast: i == bucket.length - 1,
          isCurrent: identical(e, currentEntry),
          isNext: identical(e, nextEntry),
        ));
      }
      bucket = [];
    }

    for (final _Entry e in entries) {
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
                  trailing: const Icon(Icons.chevron_right),
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
