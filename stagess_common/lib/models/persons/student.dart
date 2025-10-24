import 'dart:math';

import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/persons/person.dart';

enum Program {
  fpt,
  fms,
  undefined;

  static List<Program> get allowedValues => [...Program.values]..removeWhere(
      (element) => element == Program.undefined,
    );

  int _toInt(String version) {
    if (version == '1.0.0') {
      return index;
    }
    throw WrongVersionException(version, '1.0.0');
  }

  static Program _fromInt(int index, String version) {
    if (version == '1.0.0') {
      return Program.values[index];
    }
    throw WrongVersionException(version, '1.0.0');
  }

  @override
  String toString() {
    switch (this) {
      case Program.fpt:
        return 'FPT';
      case Program.fms:
        return 'FMS';
      case Program.undefined:
        return 'À déterminer';
    }
  }
}

class Student extends Person {
  static final _currentVersion = '1.0.0';
  static String get currentVersion => _currentVersion;

  final String schoolBoardId;
  final String schoolId;

  final String photo;

  final Program program;
  int get programSerialized => program._toInt(_currentVersion);
  final String group;

  final Person contact;
  final String contactLink;

  static get empty => Student(
        schoolBoardId: '-1',
        schoolId: '-1',
        firstName: '',
        lastName: '',
        dateBirth: null,
        phone: null,
        email: null,
        address: null,
        program: Program.undefined,
        group: '-1',
        contact: Person.empty,
        contactLink: '',
      );

  Student({
    super.id,
    required this.schoolBoardId,
    required this.schoolId,
    required super.firstName,
    super.middleName,
    required super.lastName,
    required super.dateBirth,
    required super.phone,
    required super.email,
    required super.address,
    String? photo,
    required this.program,
    required this.group,
    required this.contact,
    required this.contactLink,
  }) : photo = photo ?? Random().nextInt(0xFFFFFF).toString();

  Student.fromSerialized(super.map)
      : schoolBoardId = StringExt.from(map?['school_board_id']) ?? '-1',
        schoolId = StringExt.from(map?['school_id']) ?? '-1',
        photo = StringExt.from(map?['photo']) ??
            Random().nextInt(0xFFFFFF).toString(),
        program = map?['program'] == null
            ? Program.undefined
            : Program._fromInt(map?['program'] as int, map?['version']),
        group = StringExt.from(map?['group']) ?? '-1',
        contact = Person.fromSerialized(map?['contact'] ?? {}),
        contactLink = StringExt.from(map?['contact_link']) ?? '',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return super.serializedMap()
      ..addAll({
        'version': _currentVersion.serialize(),
        'school_board_id': schoolBoardId.serialize(),
        'school_id': schoolId.serialize(),
        'photo': photo.serialize(),
        'program': programSerialized,
        'group': group.serialize(),
        'contact': contact.serialize(),
        'contact_link': contactLink.serialize(),
      });
  }

  static FetchableFields get fetchableFields => Person.fetchableFields
    ..addAll(FetchableFields.reference({
      'school_board_id': FetchableFields.mandatory,
      'school_id': FetchableFields.mandatory,
      'photo': FetchableFields.optional,
      'program': FetchableFields.optional,
      'group': FetchableFields.mandatory,
      'contact': Person.fetchableFields,
      'contact_link': FetchableFields.optional,
    }));

  Student get limitedInfo => Student(
        id: id,
        schoolBoardId: schoolBoardId,
        schoolId: schoolId,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        group: group,
        program: program,
        address: Address.empty,
        contact: Person.empty,
        phone: PhoneNumber.empty,
        contactLink: '',
        dateBirth: null,
        email: null,
      );

  @override
  Student copyWith({
    String? id,
    String? schoolBoardId,
    String? schoolId,
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateBirth,
    PhoneNumber? phone,
    String? email,
    Address? address,
    String? photo,
    Program? program,
    String? group,
    Person? contact,
    String? contactLink,
  }) =>
      Student(
        id: id ?? this.id,
        schoolBoardId: schoolBoardId ?? this.schoolBoardId,
        schoolId: schoolId ?? this.schoolId,
        firstName: firstName ?? this.firstName,
        middleName: middleName ?? this.middleName,
        lastName: lastName ?? this.lastName,
        dateBirth: dateBirth ?? this.dateBirth,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        program: program ?? this.program,
        group: group ?? this.group,
        contact: contact ?? this.contact,
        contactLink: contactLink ?? this.contactLink,
        photo: photo ?? this.photo,
      );

  @override
  Student copyWithData(Map<String, dynamic> data) {
    // Make sure data does not contain unrecognized fields
    if (data.keys.any((key) => ![
          'id',
          'school_board_id',
          'school_id',
          'version',
          'first_name',
          'middle_name',
          'last_name',
          'date_birth',
          'phone',
          'email',
          'address',
          'photo',
          'program',
          'group',
          'contact',
          'contact_link',
        ].contains(key))) {
      throw InvalidFieldException('Invalid field data detected');
    }
    return Student(
      id: StringExt.from(data['id']) ?? id,
      schoolBoardId: StringExt.from(data['school_board_id']) ?? schoolBoardId,
      schoolId: StringExt.from(data['school_id']) ?? schoolId,
      firstName: StringExt.from(data['first_name']) ?? firstName,
      middleName: StringExt.from(data['middle_name']) ?? middleName,
      lastName: StringExt.from(data['last_name']) ?? lastName,
      dateBirth: DateTimeExt.from(data['date_birth']) ?? dateBirth,
      phone: PhoneNumber.from(data['phone']) ?? phone,
      email: StringExt.from(data['email']) ?? email,
      address: Address.from(data['address']) ?? address,
      photo: StringExt.from(data['photo']) ?? photo,
      program: data['program'] == null
          ? program
          : Program._fromInt(data['program'] as int, _currentVersion),
      group: StringExt.from(data['group']) ?? group,
      contact: contact.copyWithData(data['contact']),
      contactLink: StringExt.from(data['contact_link']) ?? contactLink,
    );
  }

  @override
  String toString() {
    return 'Student{${super.toString()}, photo: $photo, program: $program, group: $group, contact: $contact, contactLink: $contactLink}';
  }
}
