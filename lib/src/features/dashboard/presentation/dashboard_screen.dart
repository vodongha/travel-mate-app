import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error_view.dart';
import '../../../core/money.dart';
import '../../../core/responsive.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.tripRid});

  final String tripRid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Dashboard> dashboard =
        ref.watch(dashboardProvider(tripRid));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navDashboard)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: dashboard.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () => ref.invalidate(dashboardProvider(tripRid))),
            data: (d) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(dashboardProvider(tripRid)),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CountdownCard(days: d.countdownDays, l10n: l10n),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              icon: Icons.account_balance_wallet_outlined,
                              label: l10n.dashBudget,
                              value:
                                  Money.format(d.totalBudget, d.baseCurrency))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              icon: Icons.receipt_long_outlined,
                              label: l10n.dashSpent,
                              value:
                                  Money.format(d.totalSpent, d.baseCurrency))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.savings_outlined,
                    label: l10n.dashFund,
                    value: Money.format(d.fundBalance, d.baseCurrency),
                  ),
                  const SizedBox(height: 12),
                  _NextEventCard(event: d.nextEvent, l10n: l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.days, required this.l10n});

  final int? days;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String big;
    final String label;
    if (days == null) {
      big = '—';
      label = l10n.tripNoDates;
    } else if (days! < 0) {
      big = '✈';
      label = l10n.dashInProgress;
    } else {
      big = '${days!}';
      label = l10n.dashDaysToGo;
    }
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Text(big,
                style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: scheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 2),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _NextEventCard extends StatelessWidget {
  const _NextEventCard({required this.event, required this.l10n});

  final NextEvent? event;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final NextEvent? e = event;
    return Card(
      child: ListTile(
        leading: Icon(Icons.event_outlined, color: scheme.primary),
        title: Text(l10n.dashNextEvent,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
        subtitle: Text(
          e == null ? l10n.dashNoEvents : e.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        trailing: e?.startTime == null
            ? null
            : Text(
                DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
                    .add_Hm()
                    .format(e!.startTime!.toLocal())),
      ),
    );
  }
}
