import 'dart:convert';

import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:http/http.dart' as http;

class GeographicCoordinateSystem extends ItemSerializable {
  final double latitude;
  final double longitude;

  GeographicCoordinateSystem({this.latitude = 0.0, this.longitude = 0.0});

  @override
  Map<String, dynamic> serializedMap() =>
      {'latitude': latitude, 'longitude': longitude};

  static GeographicCoordinateSystem fromSerialized(Map? data) =>
      GeographicCoordinateSystem(
        latitude: data?['latitude'],
        longitude: data?['longitude'],
      );

  static Future<GeographicCoordinateSystem> fromAddress(String address) async {
    final String url =
        'https://nominatim.openstreetmap.org/search?format=json&q=$address';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return GeographicCoordinateSystem();

    try {
      final data = json.decode(response.body) as List<dynamic>;
      return GeographicCoordinateSystem(
          latitude: double.parse(data.first['lat']),
          longitude: double.parse(data.first['lon']));
    } catch (e) {
      return GeographicCoordinateSystem();
    }
  }
}
