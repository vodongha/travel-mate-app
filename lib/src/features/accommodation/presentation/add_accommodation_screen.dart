import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/snackbars.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/form_buttons.dart';
import '../../../core/geocoding.dart';
import '../../../core/location_picker.dart';
import '../../../core/responsive.dart';
import '../../../core/trip_dates.dart';
import '../../auth/presentation/auth_validators.dart';
import '../../trips/application/trips_controller.dart';
import '../application/accommodation_controller.dart';
import '../data/accommodation_repository.dart';

class AddAccommodationScreen extends ConsumerStatefulWidget {
  const AddAccommodationScreen(
      {super.key, required this.tripRid, this.existing});

  final String tripRid;
  final AccommodationItem? existing;

  @override
  ConsumerState<AddAccommodationScreen> createState() =>
      _AddAccommodationScreenState();
}

class _AddAccommodationScreenState
    extends ConsumerState<AddAccommodationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  DateTime? _checkin;
  DateTime? _checkout;
  bool _submitting = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final AccommodationItem? a = widget.existing;
    if (a != null) {
      _name.text = a.name;
      _address.text = a.address ?? '';
      _note.text = a.note ?? '';
      _checkin = a.checkinTime?.toLocal();
      _checkout = a.checkoutTime?.toLocal();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    // Constrain the picker to the trip's date range (and open on it).
    final trip = ref.read(tripProvider(widget.tripRid)).valueOrNull;
    final bounds = tripPickerBounds(
      tripStart: trip?.startDate,
      tripEnd: trip?.endDate,
      current: initial,
    );
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: bounds.initial,
      firstDate: bounds.first,
      lastDate: bounds.last,
    );
    if (date == null || !mounted) {
      return null;
    }
    final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial ?? bounds.initial));
    if (time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String? _trim(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _pickAddress() async {
    final GeoResult? r = await showLocationPicker(context,
        initialName: _name.text.trim().isEmpty ? null : _name.text.trim());
    if (r == null) {
      return;
    }
    setState(() {
      _address.text = r.displayName.isEmpty ? r.name : r.displayName;
      if (_name.text.trim().isEmpty && r.name.isNotEmpty) {
        _name.text = r.name;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final controller =
          ref.read(accommodationControllerProvider(widget.tripRid).notifier);
      if (_editing) {
        await controller.edit(
          rid: widget.existing!.rid,
          name: _name.text.trim(),
          address: _trim(_address),
          checkinTimeUtc: _checkin?.toUtc(),
          checkoutTimeUtc: _checkout?.toUtc(),
          note: _trim(_note),
        );
      } else {
        await controller.create(
          name: _name.text.trim(),
          address: _trim(_address),
          checkinTimeUtc: _checkin?.toUtc(),
          checkoutTimeUtc: _checkout?.toUtc(),
          note: _trim(_note),
        );
      }
      if (mounted) {
        showOkSnack(context, AppLocalizations.of(context).msgSaved);
        context.canPop()
            ? context.pop()
            : context.go('/trips/${widget.tripRid}/accommodations');
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
          title: Text(
              _editing ? l10n.accommodationEditTitle : l10n.accommodationNew)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 520,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                      labelText: l10n.fieldName,
                      prefixIcon: const Icon(Icons.hotel_outlined)),
                  validator: (v) => requiredValidator(context, v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(
                    labelText: l10n.fieldAddress,
                    prefixIcon: const Icon(Icons.place_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map_outlined),
                      tooltip: l10n.placePickLocation,
                      onPressed: _pickAddress,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DateTimeField(
                  label: l10n.accommodationCheckin,
                  value: _checkin == null ? null : fmt.format(_checkin!),
                  onTap: () async {
                    final DateTime? d = await _pickDateTime(_checkin);
                    if (d != null) {
                      setState(() => _checkin = d);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DateTimeField(
                  label: l10n.accommodationCheckout,
                  value: _checkout == null ? null : fmt.format(_checkout!),
                  onTap: () async {
                    final DateTime? d =
                        await _pickDateTime(_checkout ?? _checkin);
                    if (d != null) {
                      setState(() => _checkout = d);
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
