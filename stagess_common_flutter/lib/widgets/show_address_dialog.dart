import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/itineraries/waypoint.dart';

// coverage:ignore-file
class ShowAddressDialog extends StatelessWidget {
  const ShowAddressDialog(this.address, {super.key});

  final Address address;

  @override
  Widget build(BuildContext context) {
    final waypoint = Waypoint(title: '', address: address);

    return FlutterMap(
      options: MapOptions(
        initialCenter: waypoint.toLatLng(),
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: waypoint.toLatLng(),
              child: const Icon(
                Icons.location_on_sharp,
                size: 45,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
