import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/app_localizations.dart';
import 'geo_location.dart';
import 'geocoding.dart';

/// Opens the map location picker and returns the chosen place (name + coordinates), or null if the
/// user backs out. Used everywhere a location is entered — so users pick a pin instead of typing
/// latitude/longitude.
Future<GeoResult?> showLocationPicker(
  BuildContext context, {
  LatLng? initialPoint,
  String? initialName,
}) {
  return Navigator.of(context).push<GeoResult>(MaterialPageRoute(
    builder: (_) => LocationPickerScreen(
        initialPoint: initialPoint, initialName: initialName),
    fullscreenDialog: true,
  ));
}

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key, this.initialPoint, this.initialName});

  final LatLng? initialPoint;
  final String? initialName;

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  // Default view: central Vietnam (Đà Nẵng) when there's no initial pin.
  static const LatLng _fallback = LatLng(16.0471, 108.2068);

  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  List<GeoResult> _results = const [];
  GeoResult? _selected;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPoint != null) {
      _selected = GeoResult(
        name: widget.initialName ?? '',
        displayName: widget.initialName ?? '',
        point: widget.initialPoint!,
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    // Debounce to respect Nominatim's ≤1 req/s policy.
    _debounce =
        Timer(const Duration(milliseconds: 600), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    if (value.trim().length < 3) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    final List<GeoResult> found = await ref
        .read(geocodingServiceProvider)
        .search(value, lang: Localizations.localeOf(context).languageCode);
    if (mounted) {
      setState(() {
        _results = found;
        _searching = false;
      });
    }
  }

  void _choose(GeoResult r) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selected = r;
      _results = const [];
    });
    _map.move(r.point, 15);
  }

  Future<void> _myLocation() async {
    final LatLng? here = await currentLatLng();
    if (!mounted) {
      return;
    }
    if (here == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).locationPermissionDenied)));
      return;
    }
    _map.move(here, 16);
    await _onMapTap(here);
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(
        () => _selected = GeoResult(name: '', displayName: '', point: point));
    final GeoResult? labelled = await ref
        .read(geocodingServiceProvider)
        .reverse(point, lang: Localizations.localeOf(context).languageCode);
    if (labelled != null && mounted) {
      setState(() => _selected = labelled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final LatLng center = _selected?.point ?? widget.initialPoint ?? _fallback;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.locationPickTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: _runSearch,
              decoration: InputDecoration(
                hintText: l10n.locationSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: widget.initialPoint != null ? 15 : 12,
                    onTap: (_, point) => _onMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'vn.trippo.mate',
                    ),
                    if (_selected != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _selected!.point,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: Icon(Icons.location_on,
                              color: scheme.error, size: 44),
                        ),
                      ]),
                  ],
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'pickMyLocation',
                    onPressed: _myLocation,
                    tooltip: l10n.locationMyLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
                if (_results.isNotEmpty)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 8,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: _results
                            .map((r) => ListTile(
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(r.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(r.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  onTap: () => _choose(r),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _selected == null
                        ? l10n.locationTapHint
                        : (_selected!.displayName.isEmpty
                            ? '${_selected!.point.latitude.toStringAsFixed(5)}, '
                                '${_selected!.point.longitude.toStringAsFixed(5)}'
                            : _selected!.displayName),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.of(context).pop(_selected),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.locationUse),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
