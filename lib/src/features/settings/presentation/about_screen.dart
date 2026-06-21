import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/config.dart';
import '../../../core/responsive.dart';
import 'account_dialogs.dart';

/// About / publisher screen: app identity + version, a short blurb, the
/// publisher website, a community & support link, and the MIT license note.
/// External links open in an in-app WebView on mobile and a new tab on web
/// (see [openWebPage]).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 88,
                      width: 88,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [scheme.primary, scheme.tertiary],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.luggage_outlined,
                          color: scheme.onPrimary, size: 44),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appTitle,
                      style: text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const _VersionText(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.aboutBlurb,
                textAlign: TextAlign.center,
                style: text.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 28),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          Icon(Icons.person_outline, color: scheme.primary),
                      title: Text(l10n.aboutPublisher),
                      subtitle: Text(AppConfig.publisherName),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.public, color: scheme.primary),
                      title: Text(l10n.aboutWebsite),
                      subtitle: Text(AppConfig.publisherWebsite),
                      trailing: Icon(
                        kIsWeb ? Icons.open_in_new : Icons.chevron_right,
                        size: 18,
                      ),
                      onTap: () => openWebPage(context, l10n.aboutWebsite,
                          AppConfig.publisherWebsite),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.aboutLicense,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionText extends StatelessWidget {
  const _VersionText();

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.onSurfaceVariant;
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) => Text(
        snapshot.hasData
            ? 'v${snapshot.data!.version}+${snapshot.data!.buildNumber}'
            : '',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
      ),
    );
  }
}
