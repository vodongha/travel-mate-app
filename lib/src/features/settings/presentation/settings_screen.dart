import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/config.dart';
import '../../../core/currencies.dart';
import '../../../core/prefs.dart';
import '../../../core/responsive.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthUser? user = ref.watch(authControllerProvider).valueOrNull;
    final ThemeMode themeMode = ref.watch(themeControllerProvider);
    final Locale? locale = ref.watch(localeControllerProvider);
    final String displayCurrency = ref.watch(displayCurrencyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 32),
            children: [
              if (user != null) _Header(user: user),
              _sectionLabel(context, l10n.settingsProfile),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.settingsEditProfile),
                subtitle: Text(
                    [user?.name, user?.phone].whereType<String>().join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: user == null
                    ? null
                    : () => _editProfile(context, ref, user),
              ),
              _sectionLabel(context, l10n.settingsAppearance),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(l10n.settingsTheme),
                subtitle: Text(_themeLabel(l10n, themeMode)),
                onTap: () => _pickTheme(context, ref, themeMode),
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(l10n.settingsLanguage),
                subtitle: Text(_localeLabel(l10n, locale)),
                onTap: () => _pickLanguage(context, ref, locale),
              ),
              ListTile(
                leading: const Icon(Icons.attach_money_outlined),
                title: Text(l10n.settingsDisplayCurrency),
                subtitle: Text(Currencies.label(displayCurrency)),
                onTap: () =>
                    _pickDisplayCurrency(context, ref, displayCurrency),
              ),
              _sectionLabel(context, l10n.settingsSecurity),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(user?.hasPassword == false
                    ? l10n.settingsSetPassword
                    : l10n.settingsChangePassword),
                onTap: user == null
                    ? null
                    : () => _changePassword(context, ref, user.hasPassword),
              ),
              _sectionLabel(context, l10n.settingsAbout),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.settingsPrivacy),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(
                    context,
                    AppConfig.privacyUrl(
                        Localizations.localeOf(context).languageCode)),
              ),
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: Text(l10n.settingsCommunity),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(context, AppConfig.communityUrl),
              ),
              const _VersionTile(),
              _sectionLabel(context, l10n.settingsAccount),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.actionLogout),
                onTap: () => ref.read(authControllerProvider.notifier).logout(),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error),
                title: Text(l10n.settingsDeleteAccount,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => _deleteAccount(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      );

  static String _themeLabel(AppLocalizations l, ThemeMode m) => switch (m) {
        ThemeMode.light => l.themeLight,
        ThemeMode.dark => l.themeDark,
        ThemeMode.system => l.themeSystem,
      };

  static String _localeLabel(AppLocalizations l, Locale? locale) =>
      switch (locale?.languageCode) {
        'en' => l.langEnglish,
        'vi' => l.langVietnamese,
        _ => l.langSystem,
      };

  Future<void> _open(BuildContext context, String url) async {
    final bool ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).settingsOpenFailed)));
    }
  }

  Future<void> _pickTheme(
      BuildContext context, WidgetRef ref, ThemeMode current) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeMode? picked = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsTheme),
        children: ThemeMode.values
            .map((m) => ListTile(
                  title: Text(_themeLabel(l10n, m)),
                  trailing: m == current ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(ctx, m),
                ))
            .toList(),
      ),
    );
    if (picked != null) {
      await ref.read(themeControllerProvider.notifier).setMode(picked);
    }
  }

  Future<void> _pickLanguage(
      BuildContext context, WidgetRef ref, Locale? current) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String currentCode = current?.languageCode ?? 'system';
    final String? code = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          for (final entry in {
            'system': l10n.langSystem,
            'en': l10n.langEnglish,
            'vi': l10n.langVietnamese,
          }.entries)
            ListTile(
              title: Text(entry.value),
              trailing:
                  entry.key == currentCode ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, entry.key),
            ),
        ],
      ),
    );
    if (code != null) {
      await ref
          .read(localeControllerProvider.notifier)
          .setLocale(code == 'system' ? null : Locale(code));
    }
  }

  Future<void> _pickDisplayCurrency(
      BuildContext context, WidgetRef ref, String current) async {
    final String? picked = await _currencyPicker(context, current);
    if (picked != null) {
      await ref
          .read(displayCurrencyControllerProvider.notifier)
          .setCurrency(picked);
    }
  }

  Future<void> _editProfile(
      BuildContext context, WidgetRef ref, AuthUser user) async {
    final _ProfileInput? input = await showDialog<_ProfileInput>(
      context: context,
      builder: (_) => _EditProfileDialog(user: user),
    );
    if (input == null) {
      return;
    }
    try {
      await ref.read(authControllerProvider.notifier).saveProfile(
            name: input.name,
            phone: input.phone,
            defaultCurrency: input.defaultCurrency,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).settingsSaved)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  Future<void> _changePassword(
      BuildContext context, WidgetRef ref, bool hasPassword) async {
    final _PasswordInput? input = await showDialog<_PasswordInput>(
      context: context,
      builder: (_) => _ChangePasswordDialog(hasPassword: hasPassword),
    );
    if (input == null) {
      return;
    }
    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            currentPassword: input.currentPassword,
            newPassword: input.newPassword,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context).settingsPasswordChanged)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!await confirmDelete(context, message: l10n.settingsDeleteConfirm) ||
        !context.mounted) {
      return;
    }
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      // Signed out → the router redirects to /login.
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }
}

/// A scrollable currency picker over the full supported set.
Future<String?> _currencyPicker(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.7,
      child: ListView(
        children: Currencies.supported
            .map((c) => ListTile(
                  title: Text(Currencies.label(c)),
                  trailing: c == current ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(ctx, c),
                ))
            .toList(),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text(
              (user.name.isNotEmpty ? user.name : user.email)
                  .characters
                  .first
                  .toUpperCase(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(user.email,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) => ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l10n.settingsVersion),
        trailing: Text(
          snapshot.hasData
              ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
              : '—',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _ProfileInput {
  const _ProfileInput(this.name, this.phone, this.defaultCurrency);
  final String name;
  final String phone;
  final String defaultCurrency;
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.user});
  final AuthUser user;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.phone ?? '');
  late String _currency = widget.user.defaultCurrency;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.settingsEditProfile),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.authName),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.settingsPhone),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              isExpanded: true,
              decoration:
                  InputDecoration(labelText: l10n.settingsDefaultCurrency),
              items: Currencies.supported
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(Currencies.label(c))))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? _currency),
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
              Navigator.pop(
                  context,
                  _ProfileInput(
                      _name.text.trim(), _phone.text.trim(), _currency));
            }
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

class _PasswordInput {
  const _PasswordInput(this.currentPassword, this.newPassword);
  final String? currentPassword;
  final String newPassword;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.hasPassword});
  final bool hasPassword;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.hasPassword
          ? l10n.settingsChangePassword
          : l10n.settingsSetPassword),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.hasPassword) ...[
              TextFormField(
                controller: _current,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: l10n.settingsCurrentPassword),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.validationRequired : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.settingsNewPassword),
              validator: (v) => (v == null || v.length < 8)
                  ? l10n.validationPasswordShort
                  : null,
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
              Navigator.pop(
                context,
                _PasswordInput(
                    widget.hasPassword ? _current.text : null, _next.text),
              );
            }
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
