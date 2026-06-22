import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/responsive.dart';
import '../application/trips_controller.dart';
import '../domain/trip.dart';
import 'trip_format.dart';

/// Trip overview. Planning / money / fund / settlement / dashboard tabs land in later milestones.
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripRid});

  final String tripRid;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      await ref.read(tripsControllerProvider.notifier).remove(tripRid);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.tripDeleted)));
        context.go('/');
      }
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
    final AsyncValue<Trip> trip = ref.watch(tripProvider(tripRid));
    final Trip? loaded = trip.valueOrNull;
    final bool isOwner = loaded?.myRole == 'OWNER';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(loaded?.name ?? l10n.tripOverview),
        actions: [
          if (isOwner && loaded != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.actionEdit,
              onPressed: () =>
                  context.push('/trips/$tripRid/edit', extra: loaded),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.actionDelete,
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
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
                        onTap: () => context.push('/trips/$tripRid/dashboard'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.qr_code_2,
                            color: Theme.of(context).colorScheme.primary),
                        title: Text(l10n.navTickets),
                        subtitle: Text(l10n.ticketsHubSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/tickets'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.timeline_outlined),
                        title: Text(l10n.navTimeline),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/timeline'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.group_outlined),
                        title: Text(l10n.navMembers),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/members'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(l10n.navExpenses),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/expenses'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading:
                            const Icon(Icons.account_balance_wallet_outlined),
                        title: Text(l10n.navBudget),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/budgets'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.swap_horiz),
                        title: Text(l10n.navSettlement),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/settlement'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.commute_outlined),
                        title: Text(l10n.navTransport),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/transports'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.hotel_outlined),
                        title: Text(l10n.navAccommodation),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push('/trips/$tripRid/accommodations'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(l10n.navPlaces),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/places'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.checklist_outlined),
                        title: Text(l10n.navChecklist),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/checklist'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.savings_outlined),
                        title: Text(l10n.navFund),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/fund'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.summarize_outlined),
                        title: Text(l10n.navReport),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trips/$tripRid/report'),
                      ),
                    ],
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
