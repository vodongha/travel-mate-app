import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/phone_field.dart';
import '../../../core/responsive.dart';
import '../application/auth_controller.dart';
import '../domain/auth_user.dart';
import 'avatar.dart';

/// Edit-profile screen (matches family-budget-app): a large avatar, editable name + phone, and a
/// read-only email card. Currency is set in Settings, not here.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  String? _phone;
  bool _saving = false;
  bool _initialised = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String savedMsg = AppLocalizations.of(context).settingsSaved;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .saveProfile(name: name, phone: _phone ?? '');
      messenger.showSnackBar(SnackBar(content: Text(savedMsg)));
    } catch (e) {
      if (mounted) {
        messenger
            .showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AuthUser? user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_initialised) {
      _name.text = user.name;
      _phone = user.phone;
      _initialised = true;
    }
    final String display = user.name.trim().isNotEmpty ? user.name : user.email;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsEditProfile)),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 520,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    UserAvatar(name: display, radius: 44),
                    const SizedBox(height: 12),
                    Text(user.email,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.badge_outlined),
                  labelText: l10n.authName,
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              AppPhoneField(
                initialE164: user.phone,
                label: l10n.settingsPhone,
                invalidMessage: l10n.validationInvalid,
                onChanged: (e164) => _phone = e164,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(l10n.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
