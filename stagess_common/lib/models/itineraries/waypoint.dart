import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:routing_client_dart/routing_client_dart.dart' as routing_client;
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/geographic_coordinate_system.dart';
import 'package:stagess_common/models/itineraries/visiting_priority.dart';

class Waypoint extends ItemSerializable {
  final String title;
  final String? subtitle;
  final double latitude;
  final double longitude;
  final Address address;
  final VisitingPriority priority;
  final bool showTitle;

  LatLng toLatLng() => LatLng(latitude, longitude);
  routing_client.LngLat toLngLat() =>
      routing_client.LngLat(lng: longitude, lat: latitude);

  Waypoint({
    super.id,
    required this.title,
    this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.priority = VisitingPriority.notApplicable,
    this.showTitle = true,
  });

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'latitude': latitude,
      'longitude': longitude,
      'address': address.serialize(),
      'priority': priority.index,
    };
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'title': FetchableFields.mandatory,
        'subtitle': FetchableFields.mandatory,
        'latitude': FetchableFields.mandatory,
        'longitude': FetchableFields.mandatory,
        'address': Address.mandatoryFetchableFields,
        'priority': FetchableFields.mandatory,
      });

  static Waypoint fromSerialized(data) {
    return Waypoint(
      id: data['id'],
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      address: Address.fromSerialized(data['address'] ?? {}),
      priority: data['priority'] == null
          ? VisitingPriority.notApplicable
          : VisitingPriority.values[data['priority']],
    );
  }

  static Future<Waypoint> fromCoordinates({
    required String title,
    String? subtitle,
    required double latitude,
    required double longitude,
    priority = VisitingPriority.notApplicable,
    showTitle = true,
  }) async {
    return Waypoint(
      title: title,
      subtitle: subtitle,
      latitude: latitude,
      longitude: longitude,
      address: (await Address.fromCoordinates(GeographicCoordinateSystem(
              latitude: latitude, longitude: longitude))) ??
          Address.empty,
      priority: priority,
      showTitle: showTitle,
    );
  }

  static Future<Waypoint> fromAddress({
    required String title,
    String? subtitle,
    required Address address,
    priority = VisitingPriority.notApplicable,
    showTitle = true,
  }) async {
    final gcs =
        await GeographicCoordinateSystem.fromAddress(address.toString());
    return Waypoint(
      title: title,
      subtitle: subtitle,
      latitude: gcs.latitude,
      longitude: gcs.longitude,
      address: address,
      priority: priority,
      showTitle: showTitle,
    );
  }

  static Future<Waypoint> fromLatLng({
    required String title,
    String? subtitle,
    required LatLng point,
    priority = VisitingPriority.notApplicable,
    showTitle = true,
  }) async {
    return Waypoint.fromCoordinates(
      title: title,
      subtitle: subtitle,
      latitude: point.latitude,
      longitude: point.longitude,
      priority: priority,
      showTitle: showTitle,
    );
  }

  static Future<Waypoint> fromLngLat({
    required String title,
    String? subtitle,
    required routing_client.LngLat point,
    priority = VisitingPriority.notApplicable,
    showTitle = true,
  }) {
    return Waypoint.fromCoordinates(
      title: title,
      subtitle: subtitle,
      latitude: point.lat,
      longitude: point.lng,
      priority: priority,
      showTitle: showTitle,
    );
  }

  Waypoint copyWith({
    bool forceNewId = false,
    String? id,
    String? title,
    String? subtitle,
    double? latitude,
    double? longitude,
    Address? address,
    VisitingPriority? priority,
    bool? showTitle,
  }) {
    return Waypoint(
      id: forceNewId ? null : id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      priority: priority ?? this.priority,
      showTitle: showTitle ?? this.showTitle,
    );
  }

  Waypoint copyWithData(data) {
    return Waypoint(
      id: data['id'] ?? id,
      title: data['title'] ?? title,
      subtitle: data['subtitle'] ?? subtitle,
      latitude: (data['latitude'] as num?)?.toDouble() ?? latitude,
      longitude: (data['longitude'] as num?)?.toDouble() ?? longitude,
      address: data['address'] != null
          ? Address.fromSerialized(data['address'])
          : address,
      priority: data['priority'] != null
          ? VisitingPriority.values[data['priority']]
          : priority,
      showTitle: data['showTitle'] ?? showTitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Waypoint) return false;

    return other.title == title &&
        other.subtitle == subtitle &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address &&
        other.priority == priority;
  }

  @override
  String toString() {
    return '${subtitle == null ? '' : '$subtitle\n'}'
        '${address.isValid ? '${address.civicNumber} ${address.street}\n${address.city} ${address.postalCode}' : ''}';
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      subtitle.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      address.hashCode ^
      priority.hashCode;
}
