import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/responsive.dart';
import '../../accommodation/application/accommodation_controller.dart';
import '../../accommodation/data/accommodation_repository.dart';
import '../../timeline/application/events_controller.dart';
import '../../timeline/data/event_repository.dart';
import '../../transport/application/transport_controller.dart';
import '../../transport/data/transport_repository.dart';
import '../application/tickets_controller.dart';
import '../data/ticket_repository.dart';
import 'ticket_format.dart';

/// "My tickets" — the caller's own (and group) tickets, ordered by the time of the itinerary item
/// each is for, grouped by day, with the one in use now / next coming up highlighted and scrolled to.
/// Tap a ticket for its full-screen QR; long-press for edit/delete. Search + type filter on top.
class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key, required this.tripRid});

  final String tripRid;

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

/// One ticket plus the resolved time/provider of the itinerary item it's for.
class _DatedTicket {
  _DatedTicket(this.ticket, this.when, this.provider);
  final Ticket ticket;
  final DateTime? when; // local time of the linked itinerary item, or null
  final String? provider; // carrier (transport) shown here, not on the itinerary
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  static const int _pageSize = 15;

  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _targetKey = GlobalKey();
  String _query = '';
  String? _typeFilter; // null = all; else a Category value
  int _visible = _pageSize;
  int _count = 0;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_visible >= _count) {
      return;
    }
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      setState(() => _visible += _pageSize);
    }
  }

  Future<void> _rowActions(BuildContext context, Ticket ticket) async {
    final RowAction? action =
        await showRowActions(context, title: ticket.title, allowMaps: false);
    if (action == null || !context.mounted) {
      return;
    }
    if (action == RowAction.edit) {
      context.push('/trips/${widget.tripRid}/tickets/${ticket.rid}/edit',
          extra: ticket);
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(allTicketsControllerProvider(widget.tripRid).notifier)
          .remove(ticket.rid);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  /// Build the (time, provider) for each ticket from the itinerary item it links to.
  List<_DatedTicket> _decorate(BuildContext context, List<Ticket> tickets) {
    final List<EventItem> events =
        ref.watch(eventsControllerProvider(widget.tripRid)).valueOrNull ??
            const [];
    final List<TransportItem> transports =
        ref.watch(transportControllerProvider(widget.tripRid)).valueOrNull ??
            const [];
    final List<AccommodationItem> stays = ref
            .watch(accommodationControllerProvider(widget.tripRid))
            .valueOrNull ??
        const [];
    final Map<String, DateTime?> eventWhen = {for (final e in events) e.rid: e.startTime};
    final Map<String, DateTime?> stayWhen = {for (final a in stays) a.rid: a.checkinTime};
    final Map<String, DateTime?> transportWhen = {
      for (final t in transports) t.rid: t.departureTime
    };
    final Map<String, String?> transportProvider = {
      for (final t in transports) t.rid: t.provider
    };

    return tickets.map((t) {
      DateTime? when;
      String? provider;
      switch (t.itineraryKind) {
        case 'EVENT':
          when = eventWhen[t.itineraryRid];
        case 'TRANSPORT':
          when = transportWhen[t.itineraryRid];
          provider = transportProvider[t.itineraryRid];
        case 'ACCOMMODATION':
          when = stayWhen[t.itineraryRid];
      }
      return _DatedTicket(t, when?.toLocal(), provider);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Ticket>> tickets =
        ref.watch(myTicketsControllerProvider(widget.tripRid));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTickets),
        actions: [
          IconButton(
            tooltip: l10n.ticketsAll,
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => context.push('/trips/${widget.tripRid}/tickets/all'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trips/${widget.tripRid}/tickets/new'),
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
                    ref.invalidate(myTicketsControllerProvider(widget.tripRid))),
            data: (list) {
              if (list.isEmpty) {
                return Center(child: Text(l10n.ticketsEmpty));
              }
              return _content(context, l10n, _decorate(context, list));
            },
          ),
        ),
      ),
    );
  }

  Widget _content(
      BuildContext context, AppLocalizations l10n, List<_DatedTicket> all) {
    // Filter (search + type), then order chronologically by the linked itinerary time.
    final String q = _query.trim().toLowerCase();
    final List<_DatedTicket> filtered = all.where((d) {
      if (_typeFilter != null && d.ticket.ticketType != _typeFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return d.ticket.title.toLowerCase().contains(q) ||
          d.ticket.ownerLabel.toLowerCase().contains(q) ||
          (d.provider?.toLowerCase().contains(q) ?? false) ||
          ticketTypeLabel(context, d.ticket.ticketType).toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        if (a.when == null && b.when == null) return 0;
        if (a.when == null) return 1;
        if (b.when == null) return -1;
        return a.when!.compareTo(b.when!);
      });
    _count = filtered.length;

    // Highlight the ticket in use now and the next upcoming one.
    final DateTime now = DateTime.now();
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    _DatedTicket? current;
    _DatedTicket? next;
    for (final d in filtered) {
      if (d.when == null) continue;
      if (d.when!.isAfter(now)) {
        next ??= d;
      } else if (sameDay(d.when!, now)) {
        current = d;
      }
    }
    final _DatedTicket? target = current ?? next;
    final int targetIndex = target == null ? -1 : filtered.indexOf(target);
    // Reveal enough to include the auto-scroll target on first open.
    final int visible = (!_scrolled && targetIndex >= 0)
        ? (targetIndex + 3 > _visible ? targetIndex + 3 : _visible)
        : _visible;
    final List<_DatedTicket> shown =
        filtered.take(visible).toList(growable: false);
    final bool hasMore = shown.length < filtered.length;

    if (!_scrolled && target != null) {
      _scrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _targetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              alignment: 0.15,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut);
        }
      });
    }

    // Flatten into day-section headers interleaved with cards.
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateFormat dayFmt = DateFormat.yMMMMEEEEd(locale);
    final List<Widget> rows = [];
    String? lastKey;
    for (final d in shown) {
      final String key = d.when == null
          ? '_'
          : '${d.when!.year}-${d.when!.month}-${d.when!.day}';
      if (key != lastKey) {
        lastKey = key;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Text(
            d.when == null ? l10n.timelineUndated : dayFmt.format(d.when!),
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ));
      }
      final bool isCurrent = identical(d, current);
      final bool isNext = identical(d, next);
      Widget card = Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TicketCard(
          ticket: d.ticket,
          when: d.when,
          provider: d.provider,
          isCurrent: isCurrent,
          isNext: isNext,
          onTap: () => context.push(
              '/trips/${widget.tripRid}/tickets/${d.ticket.rid}/qr',
              extra: d.ticket),
          onLongPress: () => _rowActions(context, d.ticket),
        ),
      );
      if (identical(d, target)) {
        card = KeyedSubtree(key: _targetKey, child: card);
      }
      rows.add(card);
    }

    return Column(
      children: [
        _Toolbar(
          controller: _search,
          type: _typeFilter,
          onQuery: (v) => setState(() {
            _query = v;
            _visible = _pageSize;
          }),
          onType: (t) => setState(() {
            _typeFilter = t;
            _visible = _pageSize;
          }),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(myTicketsControllerProvider(widget.tripRid)),
            child: filtered.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(
                        child: Text(l10n.ticketsNoMatch,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant))),
                  ])
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    children: [
                      ...rows,
                      if (hasMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                              child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4))),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Search field + a horizontally scrollable type filter (All + each ticket category).
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.type,
    required this.onQuery,
    required this.onType,
  });

  final TextEditingController controller;
  final String? type;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onType;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.ticketsSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onQuery('');
                      }),
              filled: true,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l10n.filterAll),
                    selected: type == null,
                    onSelected: (_) => onType(null),
                  ),
                ),
                for (final String c in ticketFilterTypes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(ticketTypeLabel(context, c)),
                      selected: type == c,
                      onSelected: (_) => onType(c),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A ticket list card: title, type + time + owner + carrier; the one in use now / next up is
/// accented. Tap opens the full-screen QR; long-press opens edit/delete.
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
    this.onLongPress,
    this.when,
    this.provider,
    this.isCurrent = false,
    this.isNext = false,
  });

  final Ticket ticket;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final DateTime? when;
  final String? provider;
  final bool isCurrent;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final List<String> subParts = [
      ticketTypeLabel(context, ticket.ticketType),
      if (when != null) DateFormat.Hm(locale).format(when!),
      if (ticket.shared)
        l10n.ticketAssigneeGroup
      else if (ticket.ownerLabel.isNotEmpty)
        ticket.ownerLabel,
      // The carrier lives with the ticket (hidden on the itinerary itself).
      if (provider?.isNotEmpty == true) provider!,
      if (ticket.seat?.isNotEmpty == true) '${l10n.fieldSeat} ${ticket.seat}',
    ];
    final bool highlight = isCurrent || isNext;
    final Color accent = isCurrent ? scheme.primary : scheme.tertiary;
    return Card(
      elevation: highlight ? 1.5 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlight
            ? BorderSide(color: accent, width: 1.6)
            : BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: Icon(ticketTypeIcon(ticket.ticketType)),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                  ticket.title.isEmpty ? l10n.ticketUntitled : ticket.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (highlight)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _Badge(
                  label: isCurrent ? l10n.timelineNow : l10n.timelineUpcoming,
                  color: accent,
                  onColor: isCurrent ? scheme.onPrimary : scheme.onTertiary,
                ),
              ),
          ],
        ),
        subtitle: Text(subParts.join(' · '),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.qr_code_2),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.onColor});

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: onColor, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
