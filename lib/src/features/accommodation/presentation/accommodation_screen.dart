import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/qr.dart';
import '../../../core/responsive.dart';
import '../application/accommodation_controller.dart';
import '../data/accommodation_repository.dart';

class AccommodationScreen extends ConsumerWidget {
  const AccommodationScreen({super.key, required this.tripRid});

  final String tripRid;

  Future<void> _rowActions(
      BuildContext context, WidgetRef ref, AccommodationItem item) async {
    final RowAction? action = await showRowActions(context, title: item.name);
    if (action == null || !context.mounted) {
      return;
    }
    if (action == RowAction.edit) {
      context.push('/trips/$tripRid/accommodations/${item.rid}/edit',
          extra: item);
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(accommodationControllerProvider(tripRid).notifier)
          .delete(item.rid);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<AccommodationItem>> items =
        ref.watch(accommodationControllerProvider(tripRid));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccommodation)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trips/$tripRid/accommodations/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.accommodationNew),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(accommodationControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.accommodationEmpty))
                : RefreshIndicator(
                    onRefresh: () async => ref
                        .invalidate(accommodationControllerProvider(tripRid)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _AccommodationCard(
                        item: list[i],
                        onMenu: () => _rowActions(context, ref, list[i]),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AccommodationCard extends StatelessWidget {
  const _AccommodationCard({required this.item, required this.onMenu});

  final AccommodationItem item;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateFormat fmt = DateFormat.MMMd(locale);
    final List<String> subParts = [
      if (item.address?.isNotEmpty == true) item.address!,
      if (item.checkinTime != null && item.checkoutTime != null)
        '${fmt.format(item.checkinTime!.toLocal())} – '
            '${fmt.format(item.checkoutTime!.toLocal())}'
      else if (item.checkinTime != null)
        fmt.format(item.checkinTime!.toLocal()),
    ];
    final bool hasQr = item.qrData?.isNotEmpty == true;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: const Icon(Icons.hotel_outlined),
        ),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subParts.isEmpty
            ? null
            : Text(subParts.join(' · '),
                maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasQr)
              IconButton(
                icon: const Icon(Icons.qr_code_2),
                tooltip: AppLocalizations.of(context).qrView,
                onPressed: () => showQrDialog(context, item.qrData!),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: AppLocalizations.of(context).actionEdit,
              onPressed: onMenu,
            ),
          ],
        ),
        onTap: onMenu,
      ),
    );
  }
}
