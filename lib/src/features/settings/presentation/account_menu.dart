import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/config.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/avatar.dart';
import 'account_dialogs.dart';

/// The AppBar avatar. Tapping it opens the account menu as a bottom sheet (rises from the bottom),
/// matching family-budget-app.
class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthUser? user = ref.watch(authControllerProvider).value;
    final String name = (user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()
        : (user?.email ?? '?');
    return IconButton(
      tooltip: l10n.settingsAccount,
      padding: EdgeInsets.zero,
      icon: UserAvatar(name: name, radius: 16),
      onPressed: () => showAccountSheet(context, ref),
    );
  }
}

/// Opens the account menu sheet: edit profile, settings, privacy, community, about, sign out, and
/// (separated) delete account.
Future<void> showAccountSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _AccountSheet(parentContext: context),
  );
}

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet({required this.parentContext});

  /// The screen context (outlives the sheet) used for navigation + snackbars.
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AuthUser? user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final String name =
        user.name.trim().isNotEmpty ? user.name.trim() : user.email;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                UserAvatar(name: name, radius: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                      Text(user.email,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Tile(
              icon: Icons.person_outline,
              label: l10n.settingsEditProfile,
              onTap: () {
                Navigator.pop(context);
                parentContext.push('/profile');
              },
            ),
            _Tile(
              icon: Icons.settings_outlined,
              label: l10n.navSettings,
              onTap: () {
                Navigator.pop(context);
                parentContext.push('/settings');
              },
            ),
            _Tile(
              icon: Icons.privacy_tip_outlined,
              label: l10n.settingsPrivacy,
              onTap: () {
                Navigator.pop(context);
                // In-app WebView on mobile; a new browser tab on web.
                openWebPage(
                    parentContext,
                    l10n.settingsPrivacy,
                    AppConfig.privacyUrl(
                        Localizations.localeOf(parentContext).languageCode));
              },
            ),
            _Tile(
              icon: Icons.forum_outlined,
              label: l10n.settingsCommunity,
              onTap: () {
                Navigator.pop(context);
                openWebPage(parentContext, l10n.settingsCommunity,
                    AppConfig.communityUrl);
              },
            ),
            _Tile(
              icon: Icons.logout,
              label: l10n.actionLogout,
              onTap: () {
                Navigator.pop(context);
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _Tile(
              icon: Icons.delete_forever_outlined,
              label: l10n.settingsDeleteAccount,
              danger: true,
              onTap: () {
                Navigator.pop(context);
                confirmDeleteAccount(parentContext, ref);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: danger ? cs.error : cs.primary),
      title: Text(label,
          style: TextStyle(
              color: danger ? cs.error : cs.onSurface,
              fontWeight: FontWeight.w500)),
      trailing:
          danger ? null : Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
