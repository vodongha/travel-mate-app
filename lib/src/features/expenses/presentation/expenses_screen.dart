import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error_view.dart';
import '../../../core/labels.dart';
import '../../../core/money.dart';
import '../../../core/responsive.dart';
import '../../trips/application/trips_controller.dart';
import '../application/expenses_controller.dart';
import '../data/expense_repository.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key, required this.tripRid});

  final String tripRid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<ExpenseItem>> expenses =
        ref.watch(expensesControllerProvider(tripRid));
    final String baseCurrency =
        ref.watch(tripProvider(tripRid)).valueOrNull?.baseCurrency ?? 'VND';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navExpenses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/trips/$tripRid/expenses/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.expenseNew),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: expenses.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(expensesControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.expensesEmpty))
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(expensesControllerProvider(tripRid)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) => _ExpenseTile(
                          item: list[i], baseCurrency: baseCurrency),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.item, required this.baseCurrency});

  final ExpenseItem item;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    final bool foreign = item.currency != baseCurrency;
    final String subtitle = foreign
        ? '${Labels.category(context, item.category)} · ${Money.format(item.amount, item.currency)}'
        : Labels.category(context, item.category);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: Text(Labels.category(context, item.category).characters.first),
      ),
      title: Text(item.title),
      subtitle: Text(subtitle),
      trailing: Text(
        Money.format(item.amountBase, baseCurrency),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
