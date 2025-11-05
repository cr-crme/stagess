import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/assets/jobs_data.dart';

abstract class ActivitySectorsService {
  static ActivitySectorList? _activitySectors =
      ActivitySectorList.fromSerialized(jobData);

  static Future<void> initialize() async => activitySectors;

  static ActivitySectorList get activitySectors {
    _activitySectors ??= ActivitySectorList.fromSerialized(jobData);
    return _activitySectors!;
  }

  static Specialization? specializationOrNull(String? id) {
    if (id == null) return null;
    try {
      return specialization(id);
    } catch (e) {
      return null;
    }
  }

  static Specialization specialization(String id) {
    for (final sector in activitySectors) {
      for (final specialization in sector.specializations) {
        if (specialization.id == id) return specialization;
      }
    }
    throw Exception('Specialization not found');
  }

  static List<Specialization> get allSpecializations {
    final List<Specialization> out = [];
    for (final sector in activitySectors) {
      for (final specialization in sector.specializations) {
        out.add(specialization);
      }
    }
    return out;
  }
}

class ActivitySector extends NamedItemSerializable {
  ActivitySector.fromSerialized(super.map)
      : specializations = SpecializationList.fromSerialized(map?['s']),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() =>
      super.serializedMap()..addAll({'s': specializations.serializeList()});

  final SpecializationList specializations;
}

class ActivitySectorList extends _NamedItemSerializableList<ActivitySector> {
  ActivitySectorList._();

  factory ActivitySectorList.fromSerialized(List? map) {
    final out = ActivitySectorList._();
    for (final activity in (map ?? [])) {
      out.add(ActivitySector.fromSerialized(activity));
    }
    return out;
  }

  @override
  Map<String, dynamic> serialize() {
    throw Exception(
        'This method is not supported for ActivitySectorList, please use serializeList() instead');
  }

  List<Map<String, dynamic>> serializeList() {
    final serialized = super.serialize();
    // Transform the map into a list to fit how the json is constructed
    return serialized.keys
        .map((e) => serialized[e] as Map<String, dynamic>)
        .toList();
  }

  @override
  ActivitySector deserializeItem(data) => ActivitySector.fromSerialized(data);
}

class Specialization extends NamedItemSerializable {
  ActivitySector? _sector;
  ActivitySector get sector {
    _sector ??= _findSector(id);
    return _sector!;
  }

  Specialization.fromSerialized(super.map)
      : skills = SkillList.fromSerialized(map?['s']),
        questions = List.from(map?['q']),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({'s': skills.serializeList(), 'q': questions});

  static ActivitySector _findSector(String id) {
    for (final sector in ActivitySectorsService.activitySectors) {
      for (final specialization in sector.specializations) {
        if (specialization.id == id) return sector;
      }
    }
    throw Exception('Sector could not be found for current specialization');
  }

  final SkillList skills;
  final List<String> questions;

  @override
  String toString() {
    return 'Specialization{id: $id, name: $name, sector: ${sector.name}, skills: $skills, questions: $questions}';
  }
}

class SpecializationList extends _NamedItemSerializableList<Specialization> {
  SpecializationList._();

  factory SpecializationList.fromSerialized(List? map) {
    final out = SpecializationList._();
    for (final specialization in (map ?? [])) {
      out.add(Specialization.fromSerialized(specialization));
    }
    return out;
  }

  @override
  Map<String, dynamic> serialize() {
    throw Exception(
        'This method is not supported for SpecializationList, please use serializeList() instead');
  }

  List<Map<String, dynamic>> serializeList() {
    final serialized = super.serialize();
    // Transform the map into a list to fit how the json is constructed
    return serialized.keys
        .map((e) => serialized[e] as Map<String, dynamic>)
        .toList();
  }

  @override
  Specialization deserializeItem(data) => Specialization.fromSerialized(data);
}

class Skill extends NamedItemSerializable {
  Skill.fromSerialized(super.map)
      : complexity = map?['x'],
        criteria = List.from(map?['c'], growable: false),
        tasks = (map?['t'] as List).map((e) => Task.fromSerialized(e)).toList(),
        risks = List.from(map?['r'], growable: false),
        isOptional = map?['o'],
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'x': complexity,
      'c': criteria,
      't': tasks.map((e) => e.serialize()).toList(),
      'r': risks,
      'o': isOptional
    });

  final String complexity;
  final List<String> criteria;
  final List<Task> tasks;
  final List<String> risks;
  final bool isOptional;
}

class Task extends ItemSerializable {
  Task.fromSerialized(super.map)
      : title = map?['t'],
        isOptional = map?['o'],
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {'t': title, 'o': isOptional};

  final String title;
  final bool isOptional;

  @override
  String toString() => '$title${isOptional ? ' (Facultative)' : ''}';
}

class SkillList extends _NamedItemSerializableList<Skill> {
  SkillList._();

  factory SkillList.empty() {
    return SkillList._();
  }

  factory SkillList.fromSerialized(List? map) {
    final out = SkillList._();
    for (final skill in (map ?? [])) {
      out.add(Skill.fromSerialized(skill));
    }
    return out;
  }

  @override
  Map<String, dynamic> serialize() {
    throw Exception(
        'This method is not supported for SkillList, please use serializeList() instead');
  }

  List<Map<String, dynamic>> serializeList() {
    final serialized = super.serialize();
    // Transform the map into a list to fit how the json is constructed
    return serialized.keys
        .map((e) => serialized[e] as Map<String, dynamic>)
        .toList();
  }

  @override
  Skill deserializeItem(data) => Skill.fromSerialized(data);

  @override
  String toString() {
    return 'SkillList{skills: ${serializeList()}}';
  }
}

abstract class NamedItemSerializable extends ItemSerializable {
  final String name;

  NamedItemSerializable.fromSerialized(super.map)
      : name = map?['n'],
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {'id': id, 'n': name};

  String get idWithName => '${int.tryParse(id)} - $name';
}

abstract class _NamedItemSerializableList<T extends NamedItemSerializable>
    extends ListSerializable<T> {}
