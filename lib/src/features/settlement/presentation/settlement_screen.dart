import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error_view.dart';
import '../../../core/money.dart';
import '../../../core/responsive.dart';
import '../data/settlement_repository.dart';

class SettlementScreen extends ConsumerWidget {
  const SettlementScreen({super.key, required this.tripRid});

  final String tripRid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Settlement> settlement =
        ref.watch(settlementProvider(tripRid));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettlement)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: settlement.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () => ref.invalidate(settlementProvider(tripRid))),
            data: (s) => RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(settlementProvider(tripRid)),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (s.transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text(l10n.settlementAllSettled)),
                    )
                  else ...[
                    Text(l10n.settlementTransactions,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...s.transactions.map((t) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.arrow_forward),
                            title: Text('${t.fromName}  →  ${t.toName}'),
                            trailing: Text(
                              Money.format(t.amount, s.baseCurrency),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        )),
                  ],
                  if (s.balances.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(l10n.settlementBalances,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...s.balances.map((b) =>
                        _BalanceTile(balance: b, currency: s.baseCurrency)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.balance, required this.currency});

  final Balance balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool positive = balance.net >= 0;
    final Color color = positive ? Colors.green.shade700 : scheme.error;
    final String sign = positive ? '+' : '';
    return ListTile(
      dense: true,
      title: Text(balance.displayName),
      trailing: Text(
        '$sign${Money.format(balance.net, currency)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
