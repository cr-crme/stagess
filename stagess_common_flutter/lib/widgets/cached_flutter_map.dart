import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:stagess_common/models/generic/map_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class CachedFlutterMap extends StatelessWidget {
  const CachedFlutterMap({
    super.key,
    this.options = const fm.MapOptions(
        initialCenter: LatLng(45.508888, -73.561668), initialZoom: 12),
    this.routeOverlayBuilder,
    this.markersOverlayBuilder,
  });

  final fm.MapOptions options;
  final WidgetBuilder? routeOverlayBuilder;
  final WidgetBuilder? markersOverlayBuilder;

  @override
  Widget build(BuildContext context) {
    final tileProvider = TileProvider.instance;
    if (!tileProvider.isInitialized) {
      throw Exception('Tile provider is not initialized');
    }

    return fm.FlutterMap(
      options: options,
      children: [
        fm.TileLayer(
            urlTemplate: tileProvider.urlTile,
            userAgentPackageName: 'org.crcrme.stagess',
            tileProvider: fm.NetworkTileProvider(
              cachingProvider: fm.BuiltInMapCachingProvider.getOrCreateInstance(
                maxCacheSize: 500000000, // ~500 MB
              ),
            )),
        if (routeOverlayBuilder != null) routeOverlayBuilder!(context),
        if (markersOverlayBuilder != null) markersOverlayBuilder!(context),
        _ZoomButtons(),
        if (tileProvider.mapTileProvider == MapTileProvider.openStreetMap)
          fm.RichAttributionWidget(
            attributions: [
              // Suggested attribution for the OpenStreetMap public tile server
              fm.TextSourceAttribution(
                'OpenStreetMap',
                onTap: () =>
                    launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
              ),
            ],
          ),
      ],
    );
  }
}

class _ZoomButtons extends StatelessWidget {
  const _ZoomButtons();
  final double minZoom = 4;
  final double maxZoom = 19;
  final bool mini = true;
  final double padding = 5;
  final Alignment alignment = Alignment.topRight;

  @override
  Widget build(BuildContext context) {
    final controller = fm.MapController.of(context);
    final camera = fm.MapCamera.maybeOf(context)!;

    return Align(
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding:
                EdgeInsets.only(left: padding, top: padding, right: padding),
            child: FloatingActionButton(
              heroTag: 'zoomInButton',
              mini: mini,
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () {
                final zoom = min(camera.zoom + 1, maxZoom);
                controller.move(camera.center, zoom);
              },
              child: Icon(Icons.zoom_in, color: IconTheme.of(context).color),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: FloatingActionButton(
              heroTag: 'zoomOutButton',
              mini: mini,
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () {
                final zoom = max(camera.zoom - 1, minZoom);
                controller.move(camera.center, zoom);
              },
              child: Icon(Icons.zoom_out, color: IconTheme.of(context).color),
            ),
          ),
        ],
      ),
    );
  }
}
