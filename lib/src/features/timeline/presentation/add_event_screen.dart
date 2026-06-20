import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/form_buttons.dart';
import '../../../core/labels.dart';
import '../../../core/responsive.dart';
import '../../auth/presentation/auth_validators.dart';
import '../application/events_controller.dart';
import '../data/event_repository.dart';

class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key, required this.tripRid, this.existing});

  final String tripRid;
  final EventItem? existing;

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _note = TextEditingController();
  String _eventType = 'ACTIVITY';
  DateTime? _start;
  DateTime? _end;
  bool _submitting = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final EventItem? e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _note.text = e.note ?? '';
      _eventType = e.eventType;
      _start = e.startTime?.toLocal();
      _end = e.endTime?.toLocal();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final DateTime base = initial ?? DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 1),
      lastDate: DateTime(base.year + 5),
    );
    if (date == null || !mounted) {
      return null;
    }
    final TimeOfDay? time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(base));
    if (time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (_start == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.eventStart}: ${l10n.validationRequired}')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final controller =
          ref.read(eventsControllerProvider(widget.tripRid).notifier);
      if (_editing) {
        await controller.edit(
          eventRid: widget.existing!.rid,
          title: _title.text.trim(),
          eventType: _eventType,
          startTimeUtc: _start!.toUtc(),
          endTimeUtc: _end?.toUtc(),
          note: _note.text.trim(),
        );
      } else {
        await controller.create(
          title: _title.text.trim(),
          eventType: _eventType,
          startTimeUtc: _start!.toUtc(),
          endTimeUtc: _end?.toUtc(),
          note: _note.text.trim(),
        );
      }
      if (mounted) {
        context.go('/trips/${widget.tripRid}/timeline');
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
    final DateFormat fmt =
        DateFormat.MMMEd(Localizations.localeOf(context).toLanguageTag())
            .add_Hm();
    return Scaffold(
      appBar:
          AppBar(title: Text(_editing ? l10n.eventEditTitle : l10n.eventNew)),
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
                  initialValue: _eventType,
                  decoration: InputDecoration(labelText: l10n.expenseType),
                  items: Labels.eventTypes
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(Labels.eventType(context, t))))
                      .toList(),
                  onChanged: (v) => setState(() => _eventType = v ?? 'OTHER'),
                ),
                const SizedBox(height: 16),
                _DateTimeField(
                  label: l10n.eventStart,
                  value: _start == null ? null : fmt.format(_start!),
                  onTap: () async {
                    final DateTime? d = await _pickDateTime(_start);
                    if (d != null) {
                      setState(() => _start = d);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DateTimeField(
                  label: l10n.eventEnd,
                  value: _end == null ? null : fmt.format(_end!),
                  onTap: () async {
                    final DateTime? d = await _pickDateTime(_end ?? _start);
                    if (d != null) {
                      setState(() => _end = d);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _note,
                  maxLines: 2,
                  decoration: InputDecoration(
                      labelText: l10n.eventNote,
                      prefixIcon: const Icon(Icons.notes_outlined)),
                ),
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
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField(
      {required this.label, required this.value, required this.onTap});

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label, prefixIcon: const Icon(Icons.schedule_outlined)),
        child: Text(value ?? '—',
            style: value == null
                ? TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)
                : null),
      ),
    );
  }
}
