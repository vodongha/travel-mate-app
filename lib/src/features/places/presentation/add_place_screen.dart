import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/form_buttons.dart';
import '../../../core/geocoding.dart';
import '../../../core/labels.dart';
import '../../../core/location_picker.dart';
import '../../../core/responsive.dart';
import '../../auth/presentation/auth_validators.dart';
import '../application/place_controller.dart';
import '../data/place_repository.dart';

class AddPlaceScreen extends ConsumerStatefulWidget {
  const AddPlaceScreen({super.key, required this.tripRid, this.existing});

  final String tripRid;
  final PlaceItem? existing;

  @override
  ConsumerState<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends ConsumerState<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  String _type = 'OTHER';
  double? _lat;
  double? _lng;
  bool _submitting = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final PlaceItem? p = widget.existing;
    if (p != null) {
      _name.text = p.name;
      _address.text = p.address ?? '';
      _lat = p.latitude;
      _lng = p.longitude;
      _type = p.placeType ?? 'OTHER';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _trim(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _pickLocation() async {
    final GeoResult? r = await showLocationPicker(
      context,
      initialPoint: _lat != null && _lng != null ? LatLng(_lat!, _lng!) : null,
      initialName: _name.text.trim().isEmpty ? null : _name.text.trim(),
    );
    if (r == null) {
      return;
    }
    setState(() {
      _lat = r.point.latitude;
      _lng = r.point.longitude;
      if (_name.text.trim().isEmpty && r.name.isNotEmpty) {
        _name.text = r.name;
      }
      if (_address.text.trim().isEmpty && r.displayName.isNotEmpty) {
        _address.text = r.displayName;
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
          ref.read(placeControllerProvider(widget.tripRid).notifier);
      if (_editing) {
        await controller.edit(
          rid: widget.existing!.rid,
          name: _name.text.trim(),
          address: _trim(_address),
          latitude: _lat,
          longitude: _lng,
          placeType: _type,
        );
      } else {
        await controller.create(
          name: _name.text.trim(),
          address: _trim(_address),
          latitude: _lat,
          longitude: _lng,
          placeType: _type,
        );
      }
      if (mounted) {
        context.canPop()
            ? context.pop()
            : context.go('/trips/${widget.tripRid}/places');
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool hasPin = _lat != null && _lng != null;
    return Scaffold(
      appBar:
          AppBar(title: Text(_editing ? l10n.placeEditTitle : l10n.placeNew)),
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
                      prefixIcon: const Icon(Icons.place_outlined)),
                  validator: (v) => requiredValidator(context, v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: InputDecoration(
                      labelText: l10n.fieldType,
                      prefixIcon: const Icon(Icons.category_outlined)),
                  items: Labels.placeTypes
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(Labels.placeType(context, t))))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? 'OTHER'),
                ),
                const SizedBox(height: 16),
                // Pick a pin on the map instead of typing latitude/longitude.
                InkWell(
                  onTap: _pickLocation,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.placeLocation,
                      prefixIcon: const Icon(Icons.map_outlined),
                      suffixIcon: const Icon(Icons.chevron_right),
                    ),
                    child: Text(
                      hasPin
                          ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                          : l10n.placePickLocation,
                      style: hasPin
                          ? null
                          : TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(
                      labelText: l10n.fieldAddress,
                      prefixIcon: const Icon(Icons.signpost_outlined)),
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
