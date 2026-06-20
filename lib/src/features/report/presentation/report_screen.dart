import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error_view.dart';
import '../../../core/labels.dart';
import '../../../core/money.dart';
import '../../../core/responsive.dart';
import '../data/report_repository.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key, required this.tripRid});

  final String tripRid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Report> report = ref.watch(reportProvider(tripRid));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navReport)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: report.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () => ref.invalidate(reportProvider(tripRid))),
            data: (r) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(reportProvider(tripRid)),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _summaryRow(context, l10n.reportBudget,
                              Money.format(r.totalBudget, r.baseCurrency)),
                          const Divider(height: 20),
                          _summaryRow(context, l10n.reportActual,
                              Money.format(r.totalActual, r.baseCurrency)),
                          const Divider(height: 20),
                          _summaryRow(
                            context,
                            l10n.reportDifference,
                            '${r.overUnder > 0 ? '+' : ''}${Money.format(r.overUnder, r.baseCurrency)}',
                            color: r.overUnder > 0
                                ? Theme.of(context).colorScheme.error
                                : Colors.green.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (r.byCategory.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(l10n.reportByCategory,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...r.byCategory.map((c) => Card(
                          child: ListTile(
                            title: Text(Labels.category(context, c.category)),
                            subtitle: Text(
                                '${l10n.reportBudget}: ${Money.format(c.budget, r.baseCurrency)}'),
                            trailing: Text(
                                Money.format(c.actual, r.baseCurrency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                        )),
                  ],
                  if (r.unexpected.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(l10n.reportUnexpected,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...r.unexpected.map((u) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.warning_amber_outlined),
                          title: Text(u.title),
                          subtitle: Text(Labels.category(context, u.category)),
                          trailing:
                              Text(Money.format(u.amountBase, r.baseCurrency)),
                        )),
                  ],
                  const SizedBox(height: 20),
                  Text(l10n.reportDebts,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (r.debts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(l10n.reportNoDebts),
                    )
                  else
                    ...r.debts.map((d) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.arrow_forward),
                            title: Text('${d.fromName}  →  ${d.toName}'),
                            trailing: Text(
                                Money.format(d.amount, r.baseCurrency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                        )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value,
      {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
