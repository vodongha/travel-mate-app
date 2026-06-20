import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error_view.dart';
import '../../../core/responsive.dart';
import '../application/trips_controller.dart';
import '../domain/trip.dart';
import 'trip_format.dart';

/// Trip overview. Planning / money / fund / settlement / dashboard tabs land in later milestones.
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripRid});

  final String tripRid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Trip> trip = ref.watch(tripProvider(tripRid));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(trip.valueOrNull?.name ?? l10n.tripOverview),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: trip.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e, onRetry: () => ref.invalidate(tripProvider(tripRid))),
            data: (t) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Row(
                          icon: Icons.place_outlined,
                          label: l10n.tripDestination,
                          value: t.destination?.isNotEmpty == true
                              ? t.destination!
                              : l10n.tripDestinationUnset,
                        ),
                        const Divider(height: 24),
                        _Row(
                          icon: Icons.event_outlined,
                          label: l10n.tripDates,
                          value: tripDateRange(context, t),
                        ),
                        const Divider(height: 24),
                        _Row(
                          icon: Icons.payments_outlined,
                          label: l10n.tripBaseCurrency,
                          value: t.baseCurrency,
                        ),
                        const Divider(height: 24),
                        _Row(
                          icon: Icons.badge_outlined,
                          label: l10n.tripYourRole,
                          value: roleLabel(context, t.myRole),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dashboard_outlined),
                        title: Text(l10n.navDashboard),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/trips/$tripRid/dashboard'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.group_outlined),
                        title: Text(l10n.navMembers),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/trips/$tripRid/members'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    l10n.comingSoon,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
