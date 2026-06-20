import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/responsive.dart';
import '../../auth/presentation/auth_validators.dart';
import '../application/trips_controller.dart';
import '../domain/trip.dart';

const List<String> _currencies = [
  'VND',
  'USD',
  'EUR',
  'JPY',
  'GBP',
  'CNY',
  'KRW',
  'THB',
  'SGD'
];

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key, this.existing});

  /// When non-null the screen edits this trip instead of creating a new one.
  final Trip? existing;

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _destination = TextEditingController();
  String _currency = 'VND';
  DateTime? _start;
  DateTime? _end;
  bool _submitting = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Trip? t = widget.existing;
    if (t != null) {
      _name.text = t.name;
      _destination.text = t.destination ?? '';
      _currency = t.baseCurrency;
      _start = t.startDate;
      _end = t.endDate;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) {
          _end = null;
        }
      });
    }
  }

  Future<void> _pickEnd() async {
    final DateTime base = _start ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _end ?? base,
      firstDate: _start ?? DateTime(base.year - 1),
      lastDate: DateTime(base.year + 5),
    );
    if (picked != null) {
      setState(() => _end = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final Trip trip;
      if (_editing) {
        trip = await ref.read(tripsControllerProvider.notifier).edit(
              widget.existing!.rid,
              name: _name.text,
              baseCurrency: _currency,
              destination: _destination.text,
              startDate: _start,
              endDate: _end,
            );
      } else {
        trip = await ref.read(tripsControllerProvider.notifier).create(
              name: _name.text,
              baseCurrency: _currency,
              destination: _destination.text,
              startDate: _start,
              endDate: _end,
            );
      }
      if (mounted) {
        context.go('/trips/${trip.rid}');
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
        DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    final List<String> currencies = {_currency, ..._currencies}.toList();
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? l10n.tripEditTitle : l10n.tripNew)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 520,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                        labelText: l10n.tripName,
                        prefixIcon: const Icon(Icons.edit_outlined)),
                    validator: (v) => requiredValidator(context, v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destination,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                        labelText: l10n.tripDestination,
                        prefixIcon: const Icon(Icons.place_outlined)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: InputDecoration(
                        labelText: l10n.tripBaseCurrency,
                        prefixIcon: const Icon(Icons.payments_outlined)),
                    items: currencies
                        .map((c) =>
                            DropdownMenuItem<String>(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v ?? 'VND'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: l10n.tripStartDate,
                          value: _start == null ? null : fmt.format(_start!),
                          onTap: _pickStart,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: l10n.tripEndDate,
                          value: _end == null ? null : fmt.format(_end!),
                          onTap: _pickEnd,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4))
                        : Text(_editing ? l10n.actionSave : l10n.actionCreate),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField(
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
            labelText: label, prefixIcon: const Icon(Icons.event_outlined)),
        child: Text(value ?? '—',
            style: value == null
                ? TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)
                : null),
      ),
    );
  }
}
