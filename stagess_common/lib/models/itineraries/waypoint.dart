import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:routing_client_dart/routing_client_dart.dart' as routing_client;
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/itineraries/visiting_priority.dart';

class Waypoint extends ItemSerializable {
  final String title;
  final String? subtitle;
  final Address address;
  final VisitingPriority priority;
  final bool showTitle;

  LatLng toLatLng() =>
      LatLng(address.latitude ?? 0.0, address.longitude ?? 0.0);
  routing_client.LngLat toLngLat() => routing_client.LngLat(
      lng: address.longitude ?? 0.0, lat: address.latitude ?? 0.0);

  Waypoint({
    super.id,
    required this.title,
    this.subtitle,
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
      'address': address.serialize(),
      'priority': priority.index,
    };
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'title': FetchableFields.mandatory,
        'subtitle': FetchableFields.mandatory,
        'address': Address.mandatoryFetchableFields,
        'priority': FetchableFields.mandatory,
      });

  static Waypoint fromSerialized(dynamic data) {
    return Waypoint(
      id: data?['id'],
      title: data?['title'] ?? '',
      subtitle: data?['subtitle'] ?? '',
      address: Address.fromSerialized(data?['address'] ?? {}),
      priority: data?['priority'] == null
          ? VisitingPriority.notApplicable
          : VisitingPriority.values[data!['priority']],
    );
  }

  Waypoint copyWith({
    bool forceNewId = false,
    String? id,
    String? title,
    String? subtitle,
    Address? address,
    VisitingPriority? priority,
    bool? showTitle,
  }) {
    return Waypoint(
      id: forceNewId ? null : id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      address: address ?? this.address,
      priority: priority ?? this.priority,
      showTitle: showTitle ?? this.showTitle,
    );
  }

  Waypoint copyWithData(Map? data) {
    return Waypoint(
      id: data?['id'] ?? id,
      title: data?['title'] ?? title,
      subtitle: data?['subtitle'] ?? subtitle,
      address: data?['address'] != null
          ? Address.fromSerialized(data!['address'])
          : address,
      priority: data?['priority'] != null
          ? VisitingPriority.values[data!['priority']]
          : priority,
      showTitle: data?['showTitle'] ?? showTitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Waypoint) return false;

    return other.title == title &&
        other.subtitle == subtitle &&
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
      address.hashCode ^
      priority.hashCode;
}
