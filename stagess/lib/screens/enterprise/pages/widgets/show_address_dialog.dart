import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/itineraries/waypoint.dart';
import 'package:stagess_common_flutter/widgets/cached_tile_layer.dart';

// coverage:ignore-file
class ShowAddressDialog extends StatelessWidget {
  const ShowAddressDialog(this.address, {super.key});

  final Address address;

  @override
  Widget build(BuildContext context) {
    final waypoint = Waypoint(title: '', address: address);
    return FlutterMap(
      options: MapOptions(initialCenter: waypoint.toLatLng(), initialZoom: 16),
      children: [
        const CachedTileLayer(),
        MarkerLayer(markers: [
          Marker(
              point: waypoint.toLatLng(),
              child: const Icon(
                Icons.location_on_sharp,
                size: 45,
                color: Colors.purple,
              )),
        ]),
      ],
    );
  }
}
