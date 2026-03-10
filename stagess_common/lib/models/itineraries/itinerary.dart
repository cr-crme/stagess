import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:routing_client_dart/routing_client_dart.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/itineraries/waypoint.dart';
import 'package:stagess_common/utils.dart';
import 'package:uuid/uuid.dart';

final _uuid = const Uuid();

class Itinerary extends ListSerializable<Waypoint>
    implements Iterator<Waypoint>, ItemSerializable {
  final String _id;
  @override
  late final String id = _id;
  final String name;

  // Iterator implementation
  int _currentIndex = 0;

  @override
  Waypoint get current => this[_currentIndex];

  Itinerary({
    String? id,
    required this.name,
    List<Waypoint>? waypoints,
  }) : _id = id ?? _uuid.v4() {
    if (waypoints != null) {
      for (final waypoint in waypoints) {
        add(waypoint);
      }
    }
  }

  List<LatLng> toLatLng() => [for (final waypoint in this) waypoint.toLatLng()];
  List<LngLat> toLngLat() => [for (final waypoint in this) waypoint.toLngLat()];

  @override
  bool moveNext() {
    _currentIndex++;
    return _currentIndex < length;
  }

  @override
  Waypoint deserializeItem(data) {
    return Waypoint.fromSerialized(data);
  }

  Itinerary copyWith({
    String? id,
    String? name,
    List<Waypoint>? waypoints,
  }) {
    final itinerary = Itinerary(id: id ?? this.id, name: name ?? this.name);
    for (final waypoint in waypoints ?? this) {
      itinerary.add(waypoint.copyWith());
    }
    return itinerary;
  }

  Itinerary copyWithData(Map? data) {
    if (data == null || data.isEmpty) return copyWith();
    return Itinerary(
      id: data['id'] ?? id,
      name: data['name'] ?? name,
      waypoints: ListExt.from(data['waypoints'],
              deserializer: Waypoint.fromSerialized) ??
          toList(),
    );
  }

  static Itinerary fromSerialized(dynamic map) {
    final out = Itinerary(id: map?['id'], name: map?['name'] ?? 'empty');
    for (final waypoint in map?['waypoints'] ?? []) {
      out.add(Waypoint.fromSerialized(waypoint));
    }
    return out;
  }

  @override
  Map<String, dynamic> serialize() => serializedMap();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'name': name,
        'waypoints': super.map((e) => e.serialize()).toList()
      };

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'name': FetchableFields.optional,
        'waypoints': Waypoint.fetchableFields,
      });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Itinerary) return false;
    return id == other.id &&
        name == other.name &&
        areListsEqual(toList(), other.toList());
  }

  @override
  String toString() {
    return 'Itinerary{id: $id, name: $name, waypoints: ${[
      for (final e in this) e
    ]}}';
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ toList().hashCode;
}
