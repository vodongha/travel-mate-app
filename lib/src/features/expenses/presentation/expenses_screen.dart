import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
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

  Future<void> _rowActions(
      BuildContext context, WidgetRef ref, ExpenseItem item) async {
    final RowAction? action = await showRowActions(context, title: item.title);
    if (action == null || !context.mounted) {
      return;
    }
    if (action == RowAction.edit) {
      context.push('/trips/$tripRid/expenses/${item.rid}/edit', extra: item);
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(expensesControllerProvider(tripRid).notifier)
          .remove(item.rid);
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
    final AsyncValue<List<ExpenseItem>> expenses =
        ref.watch(expensesControllerProvider(tripRid));
    final String? myRole = ref.watch(tripProvider(tripRid)).value?.myRole;
    final bool canEdit = myRole != 'VIEWER';
    final String baseCurrency =
        ref.watch(tripProvider(tripRid)).value?.baseCurrency ?? 'VND';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navExpenses)),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/trips/$tripRid/expenses/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.expenseNew),
            )
          : null,
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
                        item: list[i],
                        baseCurrency: baseCurrency,
                        onMenu: canEdit
                            ? () => _rowActions(context, ref, list[i])
                            : null,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile(
      {required this.item, required this.baseCurrency, this.onMenu});

  final ExpenseItem item;
  final String baseCurrency;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final bool foreign = item.currency != baseCurrency;
    final String subtitle = foreign
        ? '${Labels.category(context, item.category)} · ${Money.format(item.amount, item.currency)}'
        : Labels.category(context, item.category);
    return GestureDetector(
      onLongPress: onMenu,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          child: Text(Labels.category(context, item.category).characters.first),
        ),
        title: Text(item.title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Money.format(item.amountBase, baseCurrency),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (onMenu != null)
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: AppLocalizations.of(context).actionEdit,
                onPressed: onMenu,
              ),
          ],
        ),
      ),
    );
  }
}
