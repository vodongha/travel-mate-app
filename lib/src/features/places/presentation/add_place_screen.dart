import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/form_buttons.dart';
import '../../../core/labels.dart';
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
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  String _type = 'OTHER';
  bool _submitting = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final PlaceItem? p = widget.existing;
    if (p != null) {
      _name.text = p.name;
      _address.text = p.address ?? '';
      _lat.text = p.latitude?.toString() ?? '';
      _lng.text = p.longitude?.toString() ?? '';
      _type = p.placeType ?? 'OTHER';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  String? _trim(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  String? _coordValidator(String? v, double min, double max) {
    if (v == null || v.trim().isEmpty) {
      return null;
    }
    final double? n = double.tryParse(v.trim());
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (n == null || n < min || n > max) {
      return l10n.validationInvalid;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final controller =
          ref.read(placeControllerProvider(widget.tripRid).notifier);
      final double? lat =
          _lat.text.trim().isEmpty ? null : double.tryParse(_lat.text.trim());
      final double? lng =
          _lng.text.trim().isEmpty ? null : double.tryParse(_lng.text.trim());
      if (_editing) {
        await controller.edit(
          rid: widget.existing!.rid,
          name: _name.text.trim(),
          address: _trim(_address),
          latitude: lat,
          longitude: lng,
          placeType: _type,
        );
      } else {
        await controller.create(
          name: _name.text.trim(),
          address: _trim(_address),
          latitude: lat,
          longitude: lng,
          placeType: _type,
        );
      }
      if (mounted) {
        context.go('/trips/${widget.tripRid}/places');
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
    const TextInputType coordType =
        TextInputType.numberWithOptions(signed: true, decimal: true);
    final List<TextInputFormatter> coordFmt = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
    ];
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
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(
                      labelText: l10n.fieldAddress,
                      prefixIcon: const Icon(Icons.map_outlined)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lat,
                        keyboardType: coordType,
                        inputFormatters: coordFmt,
                        decoration: InputDecoration(labelText: l10n.placeLat),
                        validator: (v) => _coordValidator(v, -90, 90),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lng,
                        keyboardType: coordType,
                        inputFormatters: coordFmt,
                        decoration: InputDecoration(labelText: l10n.placeLng),
                        validator: (v) => _coordValidator(v, -180, 180),
                      ),
                    ),
                  ],
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
