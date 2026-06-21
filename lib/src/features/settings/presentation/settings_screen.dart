import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/config.dart';
import '../../../core/currencies.dart';
import '../../../core/currency_picker.dart';
import '../../../core/prefs.dart';
import '../../../core/responsive.dart';
import '../data/rates_repository.dart';
import 'account_dialogs.dart';

/// Settings = the preferences that don't live in the account menu: appearance (theme/language),
/// currency (main display currency + exchange-rate refresh), security (password), and the version.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
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
              _label(context, l10n.settingsAppearance),
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
              _label(context, l10n.settingsDisplayCurrency),
              ListTile(
                leading: const Icon(Icons.attach_money_outlined),
                title: Text(l10n.settingsMainCurrency),
                subtitle: Text(Currencies.label(displayCurrency)),
                onTap: () =>
                    _pickDisplayCurrency(context, ref, displayCurrency),
              ),
              _RatesTile(),
              _label(context, l10n.settingsSecurity),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.settingsChangePassword),
                onTap: () => showChangePassword(context, ref),
              ),
              const _VersionTile(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
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
    final String? picked = await showCurrencyPicker(context, current);
    if (picked != null) {
      await ref
          .read(displayCurrencyControllerProvider.notifier)
          .setCurrency(picked);
    }
  }
}

/// Exchange-rate snapshot tile: shows when rates were last updated; tap to force a refresh.
class _RatesTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RatesTile> createState() => _RatesTileState();
}

class _RatesTileState extends ConsumerState<_RatesTile> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(ratesRepositoryProvider).refresh();
      ref.invalidate(ratesInfoProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context).settingsRatesRefreshed)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<RatesInfo> info = ref.watch(ratesInfoProvider);
    final String subtitle = info.maybeWhen(
      data: (r) => r.updatedAt == null
          ? '—'
          : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
              .add_Hm()
              .format(r.updatedAt!.toLocal()),
      orElse: () => '…',
    );
    return ListTile(
      leading: const Icon(Icons.currency_exchange_outlined),
      title: Text(l10n.settingsRates),
      subtitle: Text(subtitle),
      trailing: _refreshing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2))
          : const Icon(Icons.refresh),
      onTap: _refreshing ? null : _refresh,
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
          snapshot.hasData ? snapshot.data!.version : '—',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        // Tap → open the Play Store listing.
        onTap: () => openExternal(context, AppConfig.playStoreUrl),
      ),
    );
  }
}
