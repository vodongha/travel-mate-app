import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error_view.dart';
import '../../../core/responsive.dart';
import '../../settings/presentation/account_menu.dart';
import '../application/trips_controller.dart';
import '../domain/trip.dart';
import 'trip_format.dart';

/// The signed-in landing screen: the user's trips, with search, a status filter
/// and a button to create one.
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

/// null = "All"; otherwise a derived trip status (see [tripEffectiveStatus]).
const List<String> _statusFilters = [
  'PLANNING',
  'UPCOMING',
  'ONGOING',
  'COMPLETED',
];

class _TripsScreenState extends ConsumerState<TripsScreen> {
  static const int _pageSize = 12;

  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _query = '';
  String? _status;
  // How many trips are currently revealed; grows as the user scrolls (client-side
  // pagination over the already-fetched, filtered + date-sorted list).
  int _visible = _pageSize;
  // Count of currently-filtered trips, captured in build so _onScroll knows when to stop.
  int _filteredCount = 0;

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
    if (_visible >= _filteredCount) {
      return; // everything is already shown
    }
    // Reveal the next page when the user nears the bottom.
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      setState(() => _visible += _pageSize);
    }
  }

  // Any filter change resets pagination to the first page.
  void _resetPaging() => _visible = _pageSize;

  List<Trip> _filter(List<Trip> list) {
    final String q = _query.trim().toLowerCase();
    return list.where((t) {
      if (_status != null && tripEffectiveStatus(t) != _status) {
        return false;
      }
      if (q.isEmpty) {
        return true;
      }
      return t.name.toLowerCase().contains(q) ||
          (t.destination?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// Sort newest-first by start (or end) date; trips with no date sink to the bottom.
  List<Trip> _sortByDate(List<Trip> trips) {
    DateTime? dateOf(Trip t) => t.startDate ?? t.endDate;
    return [...trips]..sort((a, b) {
        final DateTime? da = dateOf(a);
        final DateTime? db = dateOf(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
  }

  /// Flatten an already date-sorted list into year-header strings interleaved with that year's
  /// trips; trips with no date fall under [undatedLabel].
  List<Object> _groupByYear(List<Trip> trips, String undatedLabel) {
    final List<Object> rows = [];
    String? currentHeader;
    for (final Trip t in trips) {
      final DateTime? d = t.startDate ?? t.endDate;
      final String header = d == null ? undatedLabel : '${d.year}';
      if (header != currentHeader) {
        currentHeader = header;
        rows.add(header);
      }
      rows.add(t);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Trip>> trips = ref.watch(tripsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navMyTrips),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/join'),
            icon: const Icon(Icons.group_add_outlined, size: 20),
            label: Text(l10n.actionJoin),
          ),
          const AccountMenu(),
          const SizedBox(width: 8),
        ],
      ),
      // Only show the FAB once at least one trip exists — the empty state has
      // its own "create trip" button, so showing both would be redundant.
      floatingActionButton: (trips.valueOrNull?.isNotEmpty ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/trips/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.tripNew),
            )
          : null,
      body: SafeArea(
        child: ResponsiveCenter(
          child: trips.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
              error: e,
              onRetry: () => ref.invalidate(tripsControllerProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return _EmptyState(l10n: l10n);
              }
              final List<Trip> filtered = _sortByDate(_filter(list));
              _filteredCount = filtered.length;
              // Reveal only the first _visible trips (client-side scroll pagination).
              final List<Trip> visible =
                  filtered.take(_visible).toList(growable: false);
              final bool hasMore = visible.length < filtered.length;
              // Group the revealed trips into year sections (newest first).
              final List<Object> rows = _groupByYear(visible, l10n.tripNoDates);
              return Column(
                children: [
                  _TripsToolbar(
                    controller: _search,
                    status: _status,
                    onQuery: (v) => setState(() {
                      _query = v;
                      _resetPaging();
                    }),
                    onStatus: (s) => setState(() {
                      _status = s;
                      _resetPaging();
                    }),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(tripsControllerProvider),
                      child: filtered.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 80),
                                Center(
                                    child: Text(l10n.tripsNoMatch,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant))),
                              ],
                            )
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                              // +1 trailing row for the "loading more" indicator.
                              itemCount: rows.length + (hasMore ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i >= rows.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                        child: SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.4))),
                                  );
                                }
                                final Object row = rows[i];
                                if (row is String) {
                                  return _YearHeader(label: row, first: i == 0);
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TripCard(trip: row as Trip),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Search field + horizontally scrollable status filter chips.
class _TripsToolbar extends StatelessWidget {
  const _TripsToolbar({
    required this.controller,
    required this.status,
    required this.onQuery,
    required this.onStatus,
  });

  final TextEditingController controller;
  final String? status;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onStatus;

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
              hintText: l10n.tripsSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onQuery('');
                      },
                    ),
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
                _Chip(
                  label: l10n.filterAll,
                  selected: status == null,
                  onTap: () => onStatus(null),
                ),
                for (final String s in _statusFilters)
                  _Chip(
                    label: tripStatusLabel(context, s),
                    selected: status == s,
                    onTap: () => onStatus(s),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A year section header in the trips list (e.g. "2026").
class _YearHeader extends StatelessWidget {
  const _YearHeader({required this.label, required this.first});

  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, first ? 4 : 16, 4, 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: scheme.outlineVariant, height: 1)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// A polished Material 3 trip card: tonal avatar, prominent name/destination,
/// date range, a colour-coded status chip and a relative countdown.
class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool hasDestination = trip.destination?.isNotEmpty == true;
    // Status shown to the user is derived from the trip's dates (auto-updates).
    final String effectiveStatus = tripEffectiveStatus(trip);
    final ({Color bg, Color fg}) statusColors =
        tripStatusColors(context, effectiveStatus);
    final String? countdown = tripCountdown(context, trip);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.push('/trips/${trip.rid}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.luggage_outlined,
                        color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 15, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hasDestination
                                    ? trip.destination!
                                    : l10n.tripDestinationUnset,
                                style: text.bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: tripStatusLabel(context, effectiveStatus),
                    bg: statusColors.bg,
                    fg: statusColors.fg,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.event_outlined,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tripDateRange(context, trip),
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (countdown != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      countdown,
                      style: text.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.badge_outlined,
                      size: 15, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    roleLabel(context, trip.myRole),
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // A scrollable so RefreshIndicator works even when empty.
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 72),
        Center(
          child: Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.map_outlined,
                size: 48, color: scheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n.tripsEmptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l10n.tripsEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: () => context.push('/trips/new'),
            icon: const Icon(Icons.add),
            label: Text(l10n.tripNew),
          ),
        ),
      ],
    );
  }
}
