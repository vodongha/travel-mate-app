import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/app_error_view.dart';
import '../../../core/labels.dart';
import '../../../core/qr.dart';
import '../../../core/responsive.dart';
import '../application/transport_controller.dart';
import '../data/transport_repository.dart';

class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key, required this.tripRid});

  final String tripRid;

  Future<void> _rowActions(
      BuildContext context, WidgetRef ref, TransportItem item) async {
    final String title = _titleOf(context, item);
    final RowAction? action = await showRowActions(context, title: title);
    if (action == null || !context.mounted) {
      return;
    }
    if (action == RowAction.edit) {
      context.go('/trips/$tripRid/transports/${item.rid}/edit', extra: item);
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(transportControllerProvider(tripRid).notifier)
          .delete(item.rid);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  static String _titleOf(BuildContext context, TransportItem item) {
    final String from = item.departurePlace ?? '';
    final String to = item.arrivalPlace ?? '';
    if (from.isNotEmpty || to.isNotEmpty) {
      return '$from → $to';
    }
    return item.provider?.isNotEmpty == true
        ? item.provider!
        : Labels.transportType(context, item.transportType);
  }

  static IconData _iconOf(String type) {
    switch (type) {
      case 'FLIGHT':
        return Icons.flight;
      case 'TRAIN':
        return Icons.train;
      case 'BUS':
        return Icons.directions_bus;
      case 'FERRY':
        return Icons.directions_boat;
      case 'TAXI':
        return Icons.local_taxi;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<TransportItem>> items =
        ref.watch(transportControllerProvider(tripRid));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTransport)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/trips/$tripRid/transports/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.transportNew),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(transportControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.transportEmpty))
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(transportControllerProvider(tripRid)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _TransportCard(
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

class _TransportCard extends StatelessWidget {
  const _TransportCard({required this.item, required this.onMenu});

  final TransportItem item;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final String when = item.departureTime == null
        ? ''
        : DateFormat.MMMEd(locale)
            .add_Hm()
            .format(item.departureTime!.toLocal());
    final List<String> subParts = [
      Labels.transportType(context, item.transportType),
      if (item.provider?.isNotEmpty == true) item.provider!,
      if (when.isNotEmpty) when,
    ];
    final bool hasQr = item.qrData?.isNotEmpty == true;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          child: Icon(TransportScreen._iconOf(item.transportType)),
        ),
        title: Text(TransportScreen._titleOf(context, item),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subParts.join(' · '),
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
