import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/config.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import 'account_dialogs.dart';

/// A two-letter avatar in the AppBar that opens the account menu (edit profile, settings, privacy,
/// community, log out, delete account).
class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthUser? user = ref.watch(authControllerProvider).valueOrNull;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: l10n.settingsAccount,
      offset: const Offset(0, 48),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: Text(_initials(user),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            showEditProfile(context, ref);
          case 'settings':
            context.push('/settings');
          case 'about':
            context.push('/about');
          case 'privacy':
            openExternal(
                context,
                AppConfig.privacyUrl(
                    Localizations.localeOf(context).languageCode));
          case 'community':
            openWebPage(
                context, l10n.settingsCommunity, AppConfig.communityUrl);
          case 'logout':
            ref.read(authControllerProvider.notifier).logout();
          case 'delete':
            confirmDeleteAccount(context, ref);
        }
      },
      itemBuilder: (context) => [
        _item('profile', Icons.person_outline, l10n.settingsEditProfile),
        _item('settings', Icons.settings_outlined, l10n.navSettings),
        _item('about', Icons.info_outline, l10n.about),
        _item('privacy', Icons.privacy_tip_outlined, l10n.settingsPrivacy),
        _item('community', Icons.forum_outlined, l10n.settingsCommunity),
        const PopupMenuDivider(),
        _item('logout', Icons.logout, l10n.actionLogout),
        _item(
            'delete', Icons.delete_forever_outlined, l10n.settingsDeleteAccount,
            color: scheme.error),
      ],
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label,
      {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  static String _initials(AuthUser? user) {
    final String src = (user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()
        : (user?.email ?? '?');
    final List<String> parts =
        src.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return src.substring(0, src.length >= 2 ? 2 : 1).toUpperCase();
  }
}
