import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/labels.dart';
import '../../../core/money.dart';
import '../../../core/responsive.dart';
import '../../auth/presentation/auth_validators.dart';
import '../application/expenses_controller.dart';
import '../data/expense_repository.dart';

/// Edits an expense's metadata only — title, category, type. The amount, currency
/// and split are immutable on the backend (`PATCH /expenses/{rid}`); to change those
/// the expense must be deleted and re-created. The money is shown read-only for context.
class EditExpenseScreen extends ConsumerStatefulWidget {
  const EditExpenseScreen(
      {super.key, required this.tripRid, required this.expense});

  final String tripRid;
  final ExpenseItem expense;

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.expense.title);
  late String _category = widget.expense.category;
  late String _expenseType = widget.expense.expenseType;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(expensesControllerProvider(widget.tripRid).notifier).edit(
            expenseRid: widget.expense.rid,
            title: _title.text.trim(),
            category: _category,
            expenseType: _expenseType,
          );
      if (mounted) {
        context.canPop()
            ? context.pop()
            : context.go('/trips/${widget.tripRid}/expenses');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseEditTitle)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 520,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                      labelText: l10n.expenseTitle,
                      prefixIcon: const Icon(Icons.edit_outlined)),
                  validator: (v) => requiredValidator(context, v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(labelText: l10n.budgetCategory),
                  items: Labels.categories
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(Labels.category(context, c))))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? 'OTHER'),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'PLANNED', label: Text(l10n.typePLANNED)),
                    ButtonSegment(
                        value: 'UNEXPECTED', label: Text(l10n.typeUNEXPECTED)),
                  ],
                  selected: {_expenseType},
                  onSelectionChanged: (s) =>
                      setState(() => _expenseType = s.first),
                ),
                const SizedBox(height: 24),
                InputDecorator(
                  decoration: InputDecoration(
                      labelText: l10n.expenseAmount,
                      prefixIcon: const Icon(Icons.payments_outlined)),
                  child: Text(Money.format(
                      widget.expense.amount, widget.expense.currency)),
                ),
                const SizedBox(height: 8),
                Text(l10n.expenseEditMoneyHint,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4))
                      : Text(l10n.actionSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
