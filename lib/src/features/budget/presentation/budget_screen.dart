import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/labels.dart';
import '../../../core/money.dart';
import '../../../core/responsive.dart';
import '../../trips/application/trips_controller.dart';
import '../application/budget_controller.dart';
import '../data/budget_repository.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key, required this.tripRid});

  final String tripRid;

  Future<void> _add(
      BuildContext context, WidgetRef ref, String currency) async {
    final _BudgetInput? input = await showDialog<_BudgetInput>(
      context: context,
      builder: (_) => const _AddBudgetDialog(),
    );
    if (input == null) {
      return;
    }
    try {
      await ref
          .read(budgetControllerProvider(tripRid).notifier)
          .add(input.category, input.amount);
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
    final AsyncValue<List<Budget>> budgets =
        ref.watch(budgetControllerProvider(tripRid));
    final String currency =
        ref.watch(tripProvider(tripRid)).valueOrNull?.baseCurrency ?? 'VND';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navBudget)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref, currency),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAdd),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: budgets.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(budgetControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.budgetEmpty))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final Budget b = list[i];
                      return ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: Text(Labels.category(context, b.category)),
                        trailing: Text(Money.format(b.plannedAmount, currency),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _BudgetInput {
  const _BudgetInput(this.category, this.amount);
  final String category;
  final num amount;
}

class _AddBudgetDialog extends StatefulWidget {
  const _AddBudgetDialog();

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  String _category = 'FOOD';

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.budgetAddTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            TextFormField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              decoration: InputDecoration(labelText: l10n.budgetPlanned),
              validator: (v) {
                final num? n = num.tryParse((v ?? '').trim());
                return (n == null || n < 0) ? l10n.validationRequired : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel)),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context,
                  _BudgetInput(_category, num.parse(_amount.text.trim())));
            }
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
