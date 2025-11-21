part of 'package:stagess_common/models/enterprises/job.dart';

class Incident extends ItemSerializable {
  String incident;
  String teacherId;
  DateTime date;

  Incident(
    this.incident, {
    required this.date,
    required this.teacherId,
  });

  Incident.fromSerialized(super.map)
      : incident = map?['incident'] ?? '',
        teacherId = map?['teacher_id'] ?? '',
        date = map?['date'] == null
            ? DateTime(0)
            : DateTime.fromMillisecondsSinceEpoch(map!['date']),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'teacher_id': teacherId,
        'incident': incident,
        'date': date.millisecondsSinceEpoch,
      };

  @override
  String toString() => incident;
}

class Incidents extends ItemSerializable {
  List<Incident> severeInjuries;
  List<Incident> verbalAbuses;
  List<Incident> minorInjuries;

  bool get isEmpty => !hasMajorIncident && minorInjuries.isEmpty;
  bool get isNotEmpty => !isEmpty;
  bool get hasMajorIncident =>
      severeInjuries.isNotEmpty || verbalAbuses.isNotEmpty;

  List<Incident> get all =>
      [...severeInjuries, ...verbalAbuses, ...minorInjuries];

  Incidents({
    super.id,
    List<Incident>? severeInjuries,
    List<Incident>? verbalAbuses,
    List<Incident>? minorInjuries,
  })  : severeInjuries = severeInjuries ?? [],
        verbalAbuses = verbalAbuses ?? [],
        minorInjuries = minorInjuries ?? [];

  static Incidents get empty => Incidents();

  Incidents copyWith({
    String? id,
    List<Incident>? severeInjuries,
    List<Incident>? verbalAbuses,
    List<Incident>? minorInjuries,
  }) =>
      Incidents(
        id: id ?? this.id,
        severeInjuries: severeInjuries ?? this.severeInjuries,
        verbalAbuses: verbalAbuses ?? this.verbalAbuses,
        minorInjuries: minorInjuries ?? this.minorInjuries,
      );

  Incidents.fromSerialized(super.map)
      : severeInjuries = (map?['severe_injuries'] as List?)
                ?.map((e) => Incident.fromSerialized(e))
                .toList() ??
            [],
        verbalAbuses = (map?['verbal_abuses'] as List?)
                ?.map((e) => Incident.fromSerialized(e))
                .toList() ??
            [],
        minorInjuries = (map?['minor_injuries'] as List?)
                ?.map((e) => Incident.fromSerialized(e))
                .toList() ??
            [],
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'severe_injuries': severeInjuries.map((e) => e.serialize()).toList(),
        'verbal_abuses': verbalAbuses.map((e) => e.serialize()).toList(),
        'minor_injuries': minorInjuries.map((e) => e.serialize()).toList(),
      };
}
