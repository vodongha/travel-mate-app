import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/currency_picker.dart';
import '../../../core/form_buttons.dart';
import '../../../core/labels.dart';
import '../../../core/responsive.dart';
import '../../members/application/members_controller.dart';
import '../../members/domain/member.dart';
import '../../timeline/application/events_controller.dart';
import '../../timeline/data/event_repository.dart';
import '../../trips/application/trips_controller.dart';
import '../application/expenses_controller.dart';
import '../data/expense_repository.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.tripRid, this.eventRid});

  final String tripRid;

  /// When opened from a timeline event, the expense is pre-attached to it.
  final String? eventRid;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final Map<String, TextEditingController> _shareCtrls = {};

  String _category = 'FOOD';
  String _expenseType = 'PLANNED';
  String _splitType = 'EQUAL';
  String? _currency;
  String? _payerRid;
  String? _eventRid;
  final Set<String> _selected = {};
  bool _initialized = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _eventRid = widget.eventRid;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    for (final TextEditingController c in _shareCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initOnce(List<Member> members, String baseCurrency) {
    if (_initialized || members.isEmpty) {
      return;
    }
    _currency = baseCurrency;
    _payerRid = members.first.rid;
    _selected.addAll(members.map((m) => m.rid));
    _initialized = true;
  }

  TextEditingController _shareCtrl(String rid) =>
      _shareCtrls.putIfAbsent(rid, () => TextEditingController());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.expenseSplitBetween)));
      return;
    }
    final List<ParticipantInput> participants = [];
    for (final String rid in _selected) {
      if (_splitType == 'EQUAL') {
        participants.add(ParticipantInput(rid));
      } else {
        final num? v = num.tryParse(_shareCtrl(rid).text.trim());
        if (v == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.expenseSplitMismatch)));
          return;
        }
        participants.add(ParticipantInput(rid, v));
      }
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(expensesControllerProvider(widget.tripRid).notifier)
          .create(
            title: _title.text.trim(),
            category: _category,
            expenseType: _expenseType,
            currency: _currency ?? 'VND',
            amount: num.parse(_amount.text.trim()),
            payerRid: _payerRid!,
            splitType: _splitType,
            participants: participants,
            spentAtIso: DateTime.now().toUtc().toIso8601String(),
            eventRid: _eventRid,
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
    final AsyncValue<List<Member>> members =
        ref.watch(membersControllerProvider(widget.tripRid));
    final String baseCurrency =
        ref.watch(tripProvider(widget.tripRid)).valueOrNull?.baseCurrency ??
            'VND';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseNew)),
      body: SafeArea(
        child: members.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorView(
              error: e,
              onRetry: () =>
                  ref.invalidate(membersControllerProvider(widget.tripRid))),
          data: (list) {
            _initOnce(list, baseCurrency);
            if (list.isEmpty) {
              return Center(child: Text(l10n.expenseNoMembers));
            }
            return _form(context, l10n, list, baseCurrency);
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context, AppLocalizations l10n,
      List<Member> members, String base) {
    return ResponsiveCenter(
      maxWidth: 560,
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
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    decoration: InputDecoration(labelText: l10n.expenseAmount),
                    validator: (v) {
                      final num? n = num.tryParse((v ?? '').trim());
                      return (n == null || n <= 0)
                          ? l10n.validationRequired
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: InkWell(
                    onTap: () async {
                      final String? c =
                          await showCurrencyPicker(context, _currency ?? base);
                      if (c != null) {
                        setState(() => _currency = c);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration:
                          InputDecoration(labelText: l10n.expenseCurrency),
                      child: Text(_currency ?? base),
                    ),
                  ),
                ),
              ],
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
            DropdownButtonFormField<String>(
              initialValue: _payerRid,
              decoration: InputDecoration(labelText: l10n.expensePaidBy),
              items: members
                  .map((m) => DropdownMenuItem(
                      value: m.rid, child: Text(m.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => _payerRid = v),
            ),
            const SizedBox(height: 16),
            _attachEventField(context, l10n),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'PLANNED', label: Text(l10n.typePLANNED)),
                ButtonSegment(
                    value: 'UNEXPECTED', label: Text(l10n.typeUNEXPECTED)),
              ],
              selected: {_expenseType},
              onSelectionChanged: (s) => setState(() => _expenseType = s.first),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _splitType,
              decoration: InputDecoration(labelText: l10n.expenseSplitType),
              items: ['EQUAL', 'EXACT', 'PERCENT', 'SHARES']
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(Labels.splitType(context, s))))
                  .toList(),
              onChanged: (v) => setState(() => _splitType = v ?? 'EQUAL'),
            ),
            const SizedBox(height: 8),
            Text(l10n.expenseSplitBetween,
                style: Theme.of(context).textTheme.labelLarge),
            ...members.map((m) => _participantRow(m)),
            const SizedBox(height: 24),
            FormButtons(
              primaryLabel: l10n.actionSave,
              loading: _submitting,
              onPrimary: _submit,
              onCancel: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachEventField(BuildContext context, AppLocalizations l10n) {
    final List<EventItem> events =
        ref.watch(eventsControllerProvider(widget.tripRid)).valueOrNull ??
            const [];
    String? title;
    if (_eventRid != null) {
      for (final EventItem e in events) {
        if (e.rid == _eventRid) {
          title = e.title;
          break;
        }
      }
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _pickEvent(events),
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.expenseAttachEvent,
          prefixIcon: const Icon(Icons.timeline_outlined),
          suffixIcon: _eventRid == null
              ? const Icon(Icons.chevron_right)
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.actionRemove,
                  onPressed: () => setState(() => _eventRid = null),
                ),
        ),
        child: Text(
          title ?? l10n.expenseNoEvent,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              title == null ? TextStyle(color: scheme.onSurfaceVariant) : null,
        ),
      ),
    );
  }

  Future<void> _pickEvent(List<EventItem> events) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: Text(l10n.expenseNoEvent),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            const Divider(height: 1),
            for (final EventItem e in events)
              ListTile(
                leading: const Icon(Icons.event_note_outlined),
                title:
                    Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(ctx, e.rid),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() => _eventRid = picked.isEmpty ? null : picked);
    }
  }

  Widget _participantRow(Member m) {
    final bool checked = _selected.contains(m.rid);
    return Row(
      children: [
        Expanded(
          child: CheckboxListTile(
            value: checked,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(m.displayName),
            onChanged: (v) => setState(() {
              if (v == true) {
                _selected.add(m.rid);
              } else {
                _selected.remove(m.rid);
              }
            }),
          ),
        ),
        if (checked && _splitType != 'EQUAL')
          SizedBox(
            width: 96,
            child: TextField(
              controller: _shareCtrl(m.rid),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              decoration: InputDecoration(
                isDense: true,
                hintText: _splitType == 'PERCENT' ? '%' : null,
              ),
            ),
          ),
      ],
    );
  }
}
