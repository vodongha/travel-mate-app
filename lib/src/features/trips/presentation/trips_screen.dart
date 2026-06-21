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
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => context.go('/join'),
          ),
          const AccountMenu(),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/trips/new'),
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

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => context.go('/trips/${trip.rid}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: const Icon(Icons.luggage),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      trip.destination?.isNotEmpty == true
                          ? trip.destination!
                          : l10n.tripDestinationUnset,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(tripDateRange(context, trip),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(roleLabel(context, trip.myRole)),
                visualDensity: VisualDensity.compact,
                backgroundColor: scheme.secondaryContainer,
              ),
            ],
          ),
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
    // A scrollable so RefreshIndicator works even when empty.
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.map_outlined,
            size: 72, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(l10n.tripsEmptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l10n.tripsEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
