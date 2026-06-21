import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_error.dart';
import '../../../core/geocoding.dart';
import '../../../core/location_picker.dart';
import '../application/place_controller.dart';
import '../data/place_repository.dart';
import 'places_screen.dart' show placeIcon;

/// Lets the user attach a location to something (an event, an expense): pick one of the trip's
/// existing places, or search a new one on the map (which creates a place). Returns the chosen
/// [PlaceItem], or null if dismissed.
Future<PlaceItem?> showTripPlacePicker(BuildContext context, String tripRid) {
  return showModalBottomSheet<PlaceItem>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _TripPlacePicker(tripRid: tripRid),
  );
}

class _TripPlacePicker extends ConsumerStatefulWidget {
  const _TripPlacePicker({required this.tripRid});

  final String tripRid;

  @override
  ConsumerState<_TripPlacePicker> createState() => _TripPlacePickerState();
}

class _TripPlacePickerState extends ConsumerState<_TripPlacePicker> {
  bool _creating = false;

  Future<void> _searchNew() async {
    final GeoResult? r = await showLocationPicker(context);
    if (r == null || !mounted) {
      return;
    }
    setState(() => _creating = true);
    try {
      final PlaceItem created = await ref
          .read(placeControllerProvider(widget.tripRid).notifier)
          .create(
            name: r.name.isEmpty ? r.displayName : r.name,
            address: r.displayName.isEmpty ? null : r.displayName,
            latitude: r.point.latitude,
            longitude: r.point.longitude,
            placeType: 'OTHER',
          );
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(context, error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<PlaceItem>> places =
        ref.watch(placeControllerProvider(widget.tripRid));
    final double maxH = MediaQuery.of(context).size.height * 0.6;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _creating
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4))
                  : const Icon(Icons.add_location_alt_outlined),
              title: Text(l10n.placePickNew),
              onTap: _creating ? null : _searchNew,
            ),
            const Divider(height: 1),
            Flexible(
              child: places.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
                data: (list) {
                  if (list.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final PlaceItem p in list)
                        ListTile(
                          leading: Icon(placeIcon(p.placeType)),
                          title: Text(p.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: p.address?.isNotEmpty == true
                              ? Text(p.address!,
                                  maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          onTap: () => Navigator.of(context).pop(p),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
