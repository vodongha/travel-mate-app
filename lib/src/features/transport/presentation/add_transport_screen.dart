import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/form_buttons.dart';
import '../../../core/labels.dart';
import '../../../core/qr.dart';
import '../../../core/responsive.dart';
import '../application/transport_controller.dart';
import '../data/transport_repository.dart';

class AddTransportScreen extends ConsumerStatefulWidget {
  const AddTransportScreen({super.key, required this.tripRid, this.existing});

  final String tripRid;
  final TransportItem? existing;

  @override
  ConsumerState<AddTransportScreen> createState() => _AddTransportScreenState();
}

class _AddTransportScreenState extends ConsumerState<AddTransportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _provider = TextEditingController();
  final _bookingCode = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _note = TextEditingController();
  String _type = 'FLIGHT';
  DateTime? _departure;
  DateTime? _arrival;
  String? _qrData;
  bool _submitting = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final TransportItem? t = widget.existing;
    if (t != null) {
      _type = t.transportType;
      _provider.text = t.provider ?? '';
      _bookingCode.text = t.bookingCode ?? '';
      _from.text = t.departurePlace ?? '';
      _to.text = t.arrivalPlace ?? '';
      _note.text = t.note ?? '';
      _departure = t.departureTime?.toLocal();
      _arrival = t.arrivalTime?.toLocal();
      _qrData = t.qrData;
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    _bookingCode.dispose();
    _from.dispose();
    _to.dispose();
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

  String? _trim(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final controller =
          ref.read(transportControllerProvider(widget.tripRid).notifier);
      if (_editing) {
        await controller.edit(
          rid: widget.existing!.rid,
          transportType: _type,
          provider: _trim(_provider),
          bookingCode: _trim(_bookingCode),
          departurePlace: _trim(_from),
          arrivalPlace: _trim(_to),
          departureTimeUtc: _departure?.toUtc(),
          arrivalTimeUtc: _arrival?.toUtc(),
          qrData: _qrData,
          note: _trim(_note),
        );
      } else {
        await controller.create(
          transportType: _type,
          provider: _trim(_provider),
          bookingCode: _trim(_bookingCode),
          departurePlace: _trim(_from),
          arrivalPlace: _trim(_to),
          departureTimeUtc: _departure?.toUtc(),
          arrivalTimeUtc: _arrival?.toUtc(),
          qrData: _qrData,
          note: _trim(_note),
        );
      }
      if (mounted) {
        context.go('/trips/${widget.tripRid}/transports');
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
      appBar: AppBar(
          title: Text(_editing ? l10n.transportEditTitle : l10n.transportNew)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 520,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: InputDecoration(
                      labelText: l10n.fieldType,
                      prefixIcon: const Icon(Icons.commute_outlined)),
                  items: Labels.transportTypes
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(Labels.transportType(context, t))))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? 'FLIGHT'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _from,
                  decoration: InputDecoration(
                      labelText: l10n.transportFrom,
                      prefixIcon: const Icon(Icons.trip_origin)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _to,
                  decoration: InputDecoration(
                      labelText: l10n.transportTo,
                      prefixIcon: const Icon(Icons.place_outlined)),
                ),
                const SizedBox(height: 16),
                _DateTimeField(
                  label: l10n.transportDeparture,
                  value: _departure == null ? null : fmt.format(_departure!),
                  onTap: () async {
                    final DateTime? d = await _pickDateTime(_departure);
                    if (d != null) {
                      setState(() => _departure = d);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DateTimeField(
                  label: l10n.transportArrival,
                  value: _arrival == null ? null : fmt.format(_arrival!),
                  onTap: () async {
                    final DateTime? d =
                        await _pickDateTime(_arrival ?? _departure);
                    if (d != null) {
                      setState(() => _arrival = d);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _provider,
                  decoration: InputDecoration(
                      labelText: l10n.transportProvider,
                      prefixIcon: const Icon(Icons.business_outlined)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bookingCode,
                  decoration: InputDecoration(
                      labelText: l10n.fieldBookingCode,
                      prefixIcon:
                          const Icon(Icons.confirmation_number_outlined)),
                ),
                const SizedBox(height: 16),
                QrField(
                  value: _qrData,
                  onChanged: (v) => setState(() => _qrData = v),
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
