import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class CachedFlutterMap extends StatelessWidget {
  const CachedFlutterMap({
    super.key,
    this.options = const MapOptions(
        initialCenter: LatLng(45.508888, -73.561668), initialZoom: 12),
    this.routeOverlayBuilder,
    this.markersOverlayBuilder,
  });

  final MapOptions options;
  final WidgetBuilder? routeOverlayBuilder;
  final WidgetBuilder? markersOverlayBuilder;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: options,
      children: [
        TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'org.crcrme.stagess',
            tileProvider: NetworkTileProvider(
              cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
                maxCacheSize: 500000000, // ~500 MB
              ),
            )),
        if (routeOverlayBuilder != null) routeOverlayBuilder!(context),
        if (markersOverlayBuilder != null) markersOverlayBuilder!(context),
        _ZoomButtons(),
        RichAttributionWidget(
          attributions: [
            // Suggested attribution for the OpenStreetMap public tile server
            TextSourceAttribution(
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
    final controller = MapController.of(context);
    final camera = MapCamera.maybeOf(context)!;

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
