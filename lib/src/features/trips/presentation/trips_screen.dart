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

/// The signed-in landing screen: the user's trips, with a button to create one.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Trip>> trips = ref.watch(tripsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navMyTrips),
        actions: [
          IconButton(
            tooltip: l10n.inviteJoinTitle,
            icon: const Icon(Icons.airplane_ticket_outlined),
            onPressed: () => context.push('/join'),
          ),
          const AccountMenu(),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trips/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.tripNew),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: trips.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
              error: e,
              onRetry: () => ref.invalidate(tripsControllerProvider),
            ),
            data: (list) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(tripsControllerProvider),
              child: list.isEmpty
                  ? _EmptyState(l10n: l10n)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _TripCard(trip: list[i]),
                    ),
            ),
          ),
        ),
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
    final ({Color bg, Color fg}) statusColors =
        tripStatusColors(context, trip.status);
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
                    label: tripStatusLabel(context, trip.status),
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
