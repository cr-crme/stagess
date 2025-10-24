import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:routing_client_dart/routing_client_dart.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/itineraries/waypoint.dart';
import 'package:stagess_common/utils.dart';
import 'package:uuid/uuid.dart';

final _uuid = const Uuid();

class Itinerary extends ListSerializable<Waypoint>
    implements Iterator<Waypoint>, ItemSerializable {
  final String _id;
  @override
  late final String id = _id;

  // Iterator implementation
  int _currentIndex = 0;

  @override
  Waypoint get current => this[_currentIndex];

  final DateTime date;

  Itinerary({String? id, required this.date, List<Waypoint>? waypoints})
      : _id = id ?? _uuid.v4() {
    if (waypoints != null) {
      for (final waypoint in waypoints) {
        add(waypoint);
      }
    }
  }

  List<LatLng> toLatLng() {
    List<LatLng> out = [];
    for (final address in this) {
      out.add(LatLng(address.latitude, address.longitude));
    }
    return out;
  }

  List<LngLat> toLngLat() {
    List<LngLat> out = [];
    for (final address in this) {
      out.add(LngLat(lng: address.longitude, lat: address.latitude));
    }
    return out;
  }

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
    DateTime? date,
    List<Waypoint>? waypoints,
  }) {
    final itinerary = Itinerary(id: id ?? this.id, date: date ?? this.date);
    for (final waypoint in waypoints ?? this) {
      itinerary.add(waypoint.copyWith());
    }
    return itinerary;
  }

  static Itinerary fromSerialized(map) {
    final out = Itinerary(
      id: map['id'],
      date: map['date'] == null
          ? DateTime(0)
          : DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
    for (final waypoint in map['waypoints'] ?? []) {
      out.add(Waypoint.fromSerialized(waypoint));
    }
    return out;
  }

  @override
  Map<String, dynamic> serialize() => serializedMap();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'waypoints': super.map((e) => e.serialize()).toList()
      };

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'date': FetchableFields.mandatory,
        'waypoints': Waypoint.fetchableFields,
      });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Itinerary) return false;
    return id == other.id &&
        date == other.date &&
        areListsEqual(toList(), other.toList());
  }

  @override
  String toString() {
    return 'Itinerary{id: $id, date: $date, waypoints: ${[
      for (final e in this) e
    ]}}';
  }

  @override
  int get hashCode => id.hashCode ^ date.hashCode;
}
