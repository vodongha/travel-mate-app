import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/actions.dart';
import '../../../core/app_error.dart';
import '../../../core/maps.dart';
import '../../../core/app_error_view.dart';
import '../../../core/labels.dart';
import '../../../core/responsive.dart';
import '../../trips/application/trips_controller.dart';
import '../application/place_controller.dart';
import '../data/place_repository.dart';

/// Icon for a place type — shared with the places map.
IconData placeIcon(String? type) {
  switch (type) {
    case 'HOTEL':
      return Icons.hotel_outlined;
    case 'RESTAURANT':
      return Icons.restaurant_outlined;
    case 'ATTRACTION':
      return Icons.attractions_outlined;
    case 'AIRPORT':
      return Icons.local_airport_outlined;
    case 'STATION':
      return Icons.directions_transit_outlined;
    case 'SHOPPING':
      return Icons.shopping_bag_outlined;
    default:
      return Icons.place_outlined;
  }
}

class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key, required this.tripRid});

  final String tripRid;

  /// Open this place in Google Maps — the row's primary tap action.
  Future<void> _openMaps(BuildContext context, PlaceItem item) async {
    await openInGoogleMaps(
      context,
      lat: item.latitude,
      lng: item.longitude,
      query: item.address ?? item.name,
    );
  }

  Future<void> _rowActions(BuildContext context, WidgetRef ref, PlaceItem item,
      {required bool canEdit}) async {
    // Maps is now the row's primary tap; the long-press menu is just edit/delete.
    final RowAction? action = await showRowActions(context,
        title: item.name,
        allowMaps: false,
        allowEdit: canEdit,
        allowDelete: canEdit);
    if (action == null || !context.mounted) {
      return;
    }
    if (action == RowAction.edit) {
      context.push('/trips/$tripRid/places/${item.rid}/edit', extra: item);
      return;
    }
    if (!await confirmDelete(context) || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(placeControllerProvider(tripRid).notifier)
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
    final AsyncValue<List<PlaceItem>> items =
        ref.watch(placeControllerProvider(tripRid));
    final bool canEdit =
        ref.watch(tripProvider(tripRid)).valueOrNull?.myRole != 'VIEWER';
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPlaces),
        actions: [
          IconButton(
            tooltip: l10n.placesMapAction,
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.push('/trips/$tripRid/places/map'),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/trips/$tripRid/places/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.placeNew),
            )
          : null,
      body: SafeArea(
        child: ResponsiveCenter(
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
                error: e,
                onRetry: () =>
                    ref.invalidate(placeControllerProvider(tripRid))),
            data: (list) => list.isEmpty
                ? Center(child: Text(l10n.placeEmpty))
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(placeControllerProvider(tripRid)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final PlaceItem p = list[i];
                        final ColorScheme scheme =
                            Theme.of(context).colorScheme;
                        final List<String> sub = [
                          if (p.placeType != null)
                            Labels.placeType(context, p.placeType!),
                          if (p.address?.isNotEmpty == true) p.address!,
                        ];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: scheme.secondaryContainer,
                              foregroundColor: scheme.onSecondaryContainer,
                              child: Icon(placeIcon(p.placeType)),
                            ),
                            title: Text(p.name,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: sub.isEmpty
                                ? null
                                : Text(sub.join(' · '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                            // Primary action is now "open in Google Maps"; edit/delete moved to the
                            // long-press menu (so the map is one tap, per the design).
                            trailing: IconButton(
                              icon: const Icon(Icons.map_outlined),
                              tooltip: l10n.openInMaps,
                              onPressed: () => _openMaps(context, p),
                            ),
                            onTap: () => _openMaps(context, p),
                            onLongPress: canEdit
                                ? () => _rowActions(context, ref, p, canEdit: canEdit)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
