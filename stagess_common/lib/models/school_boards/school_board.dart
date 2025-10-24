import 'dart:typed_data';

import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/extended_item_serializable.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/school_boards/school.dart';

class SchoolBoard extends ExtendedItemSerializable {
  static final String _currentVersion = '1.0.0';
  final String name;
  final Uint8List logo;
  final List<School> schools;
  final String cnesstNumber;

  SchoolBoard({
    super.id,
    required this.name,
    required Uint8List? logo,
    required this.schools,
    required this.cnesstNumber,
  }) : logo = (logo != null && logo.length > 2) ? logo : Uint8List(0);

  static SchoolBoard get empty =>
      SchoolBoard(name: '', logo: Uint8List(0), schools: [], cnesstNumber: '');

  SchoolBoard.fromSerialized(super.map)
      : name = StringExt.from(map?['name']) ?? 'Unnamed',
        logo = map?['logo'] is List && (map?['logo'] as List).length > 2
            ? Uint8List.fromList((map?['logo'] as List).cast<int>())
            : Uint8List(0),
        schools = ListExt.from(
              map?['schools'],
              deserializer: (e) => School.fromSerialized(e),
            ) ??
            [],
        cnesstNumber = StringExt.from(map?['cnesst_number']) ?? '',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'name': name.serialize(),
        'logo': logo,
        'schools': schools.serialize(),
        'cnesst_number': cnesstNumber.serialize(),
      };

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'name': FetchableFields.mandatory,
        'logo': FetchableFields.optional,
        'schools': School.fetchableFields,
        'cnesst_number': FetchableFields.optional,
      });

  SchoolBoard copyWith({
    String? id,
    String? name,
    Uint8List? logo,
    List<School>? schools,
    String? cnesstNumber,
  }) =>
      SchoolBoard(
        id: id ?? this.id,
        name: name ?? this.name,
        logo: logo != null && logo.length > 2 ? logo : this.logo,
        schools: schools ?? this.schools,
        cnesstNumber: cnesstNumber ?? this.cnesstNumber,
      );

  @override
  SchoolBoard copyWithData(Map<String, dynamic> data) {
    final availableFields = [
      'id',
      'name',
      'logo',
      'version',
      'schools',
      'cnesst_number',
    ];
    // Make sure data does not contain unrecognized fields
    if (data.keys.any((key) => !availableFields.contains(key))) {
      throw InvalidFieldException('Invalid field data detected');
    }

    final version = data['version'] ?? _currentVersion;
    if (version == null) {
      throw InvalidFieldException('Version field is required');
    } else if (version != '1.0.0') {
      throw WrongVersionException(version, _currentVersion);
    }

    final schoolsToKeep = data['schools'].map((e) => e['id']).toSet();
    return SchoolBoard(
      id: StringExt.from(data['id']) ?? id,
      name: data['name'] ?? name,
      logo: (data['logo'] is List && (data['logo'] as List).length > 2)
          ? Uint8List.fromList((data['logo'] as List).cast<int>())
          : logo,
      schools: ListExt.mergeWithData(
        schools.where((e) => schoolsToKeep.contains(e.id)).toList(),
        data['schools'],
        copyWithData: (school, serialized) => school.copyWithData(serialized),
        deserializer: (serialized) => School.fromSerialized(serialized),
      ),
      cnesstNumber: StringExt.from(data['cnesst_number']) ?? cnesstNumber,
    );
  }

  @override
  String toString() => name;
}
