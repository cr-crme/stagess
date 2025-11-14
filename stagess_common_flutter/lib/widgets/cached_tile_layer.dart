import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:hive/hive.dart';

Box? _box;
String _makeCoordinatesKey(TileCoordinates coordinates) {
  final s = '${coordinates.x},${coordinates.y},${coordinates.z}';
  return sha1.convert(utf8.encode(s)).toString();
}

base class _CachedNetworkTileProvider extends CancellableNetworkTileProvider {
  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
    if (_box == null) {
      throw Exception(
          'Cache not initialized, please call CachedTileLayer.initializeCache() first');
    }
    final key = _makeCoordinatesKey(coordinates);

    final cachedImage = _box!.get(key);
    if (cachedImage != null) {
      return cachedImage;
    }

    final out = super.getImageWithCancelLoadingSupport(
      coordinates,
      options,
      cancelLoading,
    );

    // Implement your caching logic here
    // TODO make it a json
    // TODO Add credits
    _box!.put(key, out);

    return out;
  }
}

class CachedTileLayer extends StatefulWidget {
  const CachedTileLayer({super.key});

  static Future<void> initializeCache() async {
    WidgetsFlutterBinding.ensureInitialized();
    _box = await Hive.openBox('stagess_map_cache');
  }

  @override
  State<CachedTileLayer> createState() => _CachedTileLayerState();
}

class _CachedTileLayerState extends State<CachedTileLayer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // return TileLayer(
    //   urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    //   tileProvider: _tileProvider,
    //   userAgentPackageName:
    //       'Stagess (https://github.com/cr-crme/stagess; contact: benjamin.michaud.phq@gmail.com)',
    // );

    return TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        tileProvider: _CachedNetworkTileProvider());
  }
}
