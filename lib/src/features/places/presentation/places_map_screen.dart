import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error_view.dart';
import '../../../core/labels.dart';
import '../application/place_controller.dart';
import '../data/place_repository.dart';
import 'places_screen.dart' show placeIcon;

/// An OpenStreetMap overview of every trip place that has coordinates — the whole itinerary on one
/// map. Tapping a pin shows its details and a shortcut to edit it.
class PlacesMapScreen extends ConsumerWidget {
  const PlacesMapScreen({super.key, required this.tripRid});

  final String tripRid;

  void _showPlace(BuildContext context, PlaceItem p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(placeIcon(p.placeType)),
              title: Text(p.name),
              subtitle: Text([
                if (p.placeType != null)
                  Labels.placeType(context, p.placeType!),
                if (p.address?.isNotEmpty == true) p.address!,
              ].join(' · ')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/trips/$tripRid/places/${p.rid}/edit',
                      extra: p);
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(AppLocalizations.of(context).actionEdit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<List<PlaceItem>> items =
        ref.watch(placeControllerProvider(tripRid));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.placesMapTitle)),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorView(
            error: e,
            onRetry: () => ref.invalidate(placeControllerProvider(tripRid))),
        data: (list) {
          final List<PlaceItem> pinned = list
              .where((p) => p.latitude != null && p.longitude != null)
              .toList();
          if (pinned.isEmpty) {
            return Center(child: Text(l10n.placesMapEmpty));
          }
          final List<LatLng> points =
              pinned.map((p) => LatLng(p.latitude!, p.longitude!)).toList();
          return FlutterMap(
            options: MapOptions(
              initialCenter: points.first,
              initialZoom: 13,
              initialCameraFit: points.length > 1
                  ? CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(points),
                      padding: const EdgeInsets.all(56),
                    )
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'vn.trippo.mate',
              ),
              MarkerLayer(
                markers: [
                  for (final PlaceItem p in pinned)
                    Marker(
                      point: LatLng(p.latitude!, p.longitude!),
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _showPlace(context, p),
                        child: Icon(Icons.location_on,
                            color: scheme.error, size: 44),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
