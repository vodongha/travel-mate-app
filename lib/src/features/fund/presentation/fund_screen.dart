import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/form_buttons.dart';
import '../../../core/labels.dart';
import '../../../core/money.dart';
import '../../../core/responsive.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../members/application/members_controller.dart';
import '../../members/domain/member.dart';
import '../../trips/application/trips_controller.dart';
import '../data/fund_repository.dart';

class FundScreen extends ConsumerWidget {
  const FundScreen({super.key, required this.tripRid});

  final String tripRid;

  void _refresh(WidgetRef ref) {
    ref.invalidate(fundBalanceProvider(tripRid));
    ref.invalidate(contributionsProvider(tripRid));
    ref.invalidate(fundExpensesProvider(tripRid));
    ref.invalidate(dashboardProvider(tripRid));
  }

  Future<void> _addContribution(
      BuildContext context, WidgetRef ref, String base) async {
    final List<Member> members =
        ref.read(membersControllerProvider(tripRid)).valueOrNull ?? const [];
    if (members.isEmpty) {
      return;
    }
    final _ContributionInput? input = await showDialog<_ContributionInput>(
      context: context,
      builder: (_) => _AddContributionDialog(members: members),
    );
    if (input == null) {
      return;
    }
    try {
      await ref
          .read(fundRepositoryProvider)
          .addContribution(tripRid, input.memberRid, base, input.amount);
      _refresh(ref);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  Future<void> _addFundExpense(
      BuildContext context, WidgetRef ref, String base) async {
    final _FundExpenseInput? input = await showDialog<_FundExpenseInput>(
      context: context,
      builder: (_) => const _AddFundExpenseDialog(),
    );
    if (input == null) {
      return;
    }
    try {
      await ref.read(fundRepositoryProvider).addFundExpense(
          tripRid, input.title, input.category, base, input.amount);
      _refresh(ref);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Future<void> Function() op) async {
    final RowAction? action = await showRowActions(context, allowEdit: false);
    if (action != RowAction.delete || !context.mounted) {
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await op();
      _refresh(ref);
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
    final bool canEdit =
        ref.watch(tripProvider(tripRid)).valueOrNull?.myRole != 'VIEWER';
    final AsyncValue<FundBalance> balance =
        ref.watch(fundBalanceProvider(tripRid));
    final AsyncValue<List<Contribution>> contributions =
        ref.watch(contributionsProvider(tripRid));
    final AsyncValue<List<FundExpense>> expenses =
        ref.watch(fundExpensesProvider(tripRid));
    final Map<String, String> memberNames = {
      for (final Member m
          in ref.watch(membersControllerProvider(tripRid)).valueOrNull ??
              const [])
        m.rid: m.displayName
    };
    final String base =
        ref.watch(tripProvider(tripRid)).valueOrNull?.baseCurrency ?? 'VND';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navFund),
        actions: [
          if (canEdit) ...[
            IconButton(
              tooltip: l10n.fundAddContribution,
              icon: const Icon(Icons.volunteer_activism_outlined),
              onPressed: () => _addContribution(context, ref, base),
            ),
            IconButton(
              tooltip: l10n.fundAddExpense,
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => _addFundExpense(context, ref, base),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: balance.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                AppErrorView(error: e, onRetry: () => _refresh(ref)),
            data: (b) => RefreshIndicator(
              onRefresh: () async => _refresh(ref),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(l10n.fundBalanceLabel,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer)),
                          const SizedBox(height: 6),
                          Text(Money.format(b.balance, b.baseCurrency),
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.fundContributions,
                      style: Theme.of(context).textTheme.titleMedium),
                  _section<Contribution>(
                    context,
                    ref,
                    contributions,
                    base,
                    (c) => memberNames[c.memberRid] ?? '—',
                    (c) => c.amountBase,
                    l10n.fundEmpty,
                    canEdit
                        ? (c) => ref
                            .read(fundRepositoryProvider)
                            .deleteContribution(tripRid, c.rid)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.fundExpensesLabel,
                      style: Theme.of(context).textTheme.titleMedium),
                  _section<FundExpense>(
                    context,
                    ref,
                    expenses,
                    base,
                    (e) => e.title,
                    (e) => e.amountBase,
                    l10n.fundEmpty,
                    canEdit
                        ? (e) => ref
                            .read(fundRepositoryProvider)
                            .deleteFundExpense(tripRid, e.rid)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section<T>(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<T>> async,
    String currency,
    String Function(T) label,
    num Function(T) amount,
    String emptyText,
    Future<void> Function(T)? onDelete,
  ) {
    return async.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(friendlyError(context, e))),
      data: (list) => list.isEmpty
          ? Padding(padding: const EdgeInsets.all(12), child: Text(emptyText))
          : Column(
              children: list.map((item) {
                final VoidCallback? onMenu = onDelete == null
                    ? null
                    : () => _delete(context, ref, () => onDelete(item));
                return GestureDetector(
                  onLongPress: onMenu,
                  child: ListTile(
                    dense: true,
                    title: Text(label(item)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(Money.format(amount(item), currency),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        if (onMenu != null)
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            tooltip: AppLocalizations.of(context).actionDelete,
                            onPressed: onMenu,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ContributionInput {
  const _ContributionInput(this.memberRid, this.amount);
  final String memberRid;
  final num amount;
}

class _AddContributionDialog extends StatefulWidget {
  const _AddContributionDialog({required this.members});
  final List<Member> members;

  @override
  State<_AddContributionDialog> createState() => _AddContributionDialogState();
}

class _AddContributionDialogState extends State<_AddContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late String _memberRid = widget.members.first.rid;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.fundAddContribution),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _memberRid,
              decoration: InputDecoration(labelText: l10n.fundContributor),
              items: widget.members
                  .map((m) => DropdownMenuItem(
                      value: m.rid, child: Text(m.displayName)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _memberRid = v ?? widget.members.first.rid),
            ),
            const SizedBox(height: 12),
            _amountField(context, _amount),
            const SizedBox(height: 20),
            FormButtons(
              primaryLabel: l10n.actionSave,
              onPrimary: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(
                      context,
                      _ContributionInput(
                          _memberRid, num.parse(_amount.text.trim())));
                }
              },
              onCancel: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundExpenseInput {
  const _FundExpenseInput(this.title, this.category, this.amount);
  final String title;
  final String category;
  final num amount;
}

class _AddFundExpenseDialog extends StatefulWidget {
  const _AddFundExpenseDialog();

  @override
  State<_AddFundExpenseDialog> createState() => _AddFundExpenseDialogState();
}

class _AddFundExpenseDialogState extends State<_AddFundExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String _category = 'FOOD';

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.fundAddExpense),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.expenseTitle),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(labelText: l10n.budgetCategory),
              items: Labels.categories
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(Labels.category(context, c))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'OTHER'),
            ),
            const SizedBox(height: 12),
            _amountField(context, _amount),
            const SizedBox(height: 20),
            FormButtons(
              primaryLabel: l10n.actionSave,
              onPrimary: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(
                      context,
                      _FundExpenseInput(_title.text.trim(), _category,
                          num.parse(_amount.text.trim())));
                }
              },
              onCancel: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _amountField(BuildContext context, TextEditingController controller) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  return TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    decoration: InputDecoration(labelText: l10n.expenseAmount),
    validator: (v) {
      final num? n = num.tryParse((v ?? '').trim());
      return (n == null || n <= 0) ? l10n.validationRequired : null;
    },
  );
}
