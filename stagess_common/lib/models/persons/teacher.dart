import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/itineraries/itinerary.dart';
import 'package:stagess_common/models/itineraries/visiting_priority.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/school_member.dart';

class Teacher extends Person with SchoolMember {
  @override
  final String schoolBoardId;
  @override
  final String schoolId;

  final AccessLevel accessLevel;
  final bool hasRegisteredAccount;
  bool get hasNotRegisteredAccount => !hasRegisteredAccount;
  final List<String> groups;
  final List<Itinerary> itineraries;
  final Map<String, VisitingPriority> _visitingPriorities;

  Teacher({
    super.id,
    required super.firstName,
    required super.lastName,
    required this.schoolBoardId,
    required this.schoolId,
    required this.accessLevel,
    required this.hasRegisteredAccount,
    required this.groups,
    required super.email,
    required super.phone,
    required super.address,
    required super.dateBirth,
    required this.itineraries,
    required Map<String, VisitingPriority> visitingPriorities,
  })  : _visitingPriorities = visitingPriorities,
        super() {
    if (dateBirth != null) {
      throw ArgumentError('Date of birth should not be set for a teacher');
    }
  }

  static Teacher get empty => Teacher(
        firstName: '',
        lastName: '',
        schoolBoardId: '-1',
        schoolId: '-1',
        accessLevel: AccessLevel.teacher,
        hasRegisteredAccount: false,
        groups: [],
        email: '',
        phone: PhoneNumber.empty,
        address: Address.empty,
        dateBirth: null,
        itineraries: [],
        visitingPriorities: {},
      );

  bool get isEmpty => firstName.isEmpty && lastName.isEmpty;

  List<String> get internshipsWithPriorities =>
      _visitingPriorities.keys.toList(growable: false);
  VisitingPriority visitingPriority(String internshipId) =>
      _visitingPriorities[internshipId] ?? VisitingPriority.low;
  void setVisitingPriority(String internshipId, VisitingPriority priority) {
    _visitingPriorities[internshipId] = priority;
  }

  Teacher.fromSerialized(super.map)
      : schoolBoardId = StringExt.from(map?['school_board_id']) ?? '-1',
        schoolId = StringExt.from(map?['school_id']) ?? '-1',
        accessLevel = AccessLevel.fromSerialized(map?['access_level']),
        hasRegisteredAccount =
            BoolExt.from(map?['has_registered_account']) ?? false,
        groups = ListExt.from(map?['groups'],
                deserializer: (e) => StringExt.from(e) ?? '-1') ??
            [],
        itineraries = ListExt.from(map?['itineraries'],
                deserializer: Itinerary.fromSerialized) ??
            [],
        _visitingPriorities = MapExt.from(map?['visiting_priorities'],
                deserializer: (e) =>
                    VisitingPriority.deserialize(e) ??
                    VisitingPriority.notApplicable) ??
            {},
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'school_board_id': schoolBoardId.serialize(),
      'school_id': schoolId.serialize(),
      'access_level': accessLevel.serialize(),
      'has_registered_account': hasRegisteredAccount.serialize(),
      'groups': groups.serialize(),
      'itineraries': itineraries.serialize(),
      'visiting_priorities': _visitingPriorities
          .map((key, value) => MapEntry(key, value.serialize())),
    });

  static FetchableFields get fetchableFields => Person.fetchableFields
    ..addAll(FetchableFields.reference({
      'school_board_id': FetchableFields.mandatory,
      'school_id': FetchableFields.mandatory,
      'access_level': FetchableFields.optional,
      'email': FetchableFields.mandatory,
      'has_registered_account': FetchableFields.optional,
      'groups': FetchableFields.mandatory,
      'itineraries': FetchableFields.optional,
      'visiting_priorities': FetchableFields.optional,
    }));

  @override
  Teacher copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? schoolBoardId,
    String? schoolId,
    AccessLevel? accessLevel,
    bool? hasRegisteredAccount,
    List<String>? groups,
    String? email,
    PhoneNumber? phone,
    Address? address,
    DateTime? dateBirth,
    List<Itinerary>? itineraries,
    Map<String, VisitingPriority>? visitingPriorities,
  }) =>
      Teacher(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        schoolBoardId: schoolBoardId ?? this.schoolBoardId,
        schoolId: schoolId ?? this.schoolId,
        accessLevel: accessLevel ?? this.accessLevel,
        hasRegisteredAccount: hasRegisteredAccount ?? this.hasRegisteredAccount,
        groups: groups ?? this.groups,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        dateBirth: dateBirth ?? this.dateBirth,
        address: address ?? this.address,
        itineraries: itineraries ?? this.itineraries,
        visitingPriorities: visitingPriorities ?? _visitingPriorities,
      );

  @override
  Teacher copyWithData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return copyWith();

    // Make sure data does not contain unrecognized fields
    if (data.keys.any((key) => ![
          'id',
          'first_name',
          'last_name',
          'school_board_id',
          'school_id',
          'access_level',
          'has_registered_account',
          'groups',
          'phone',
          'email',
          'date_birth',
          'address',
          'itineraries',
          'visiting_priorities',
        ].contains(key))) {
      throw InvalidFieldException('Invalid field data detected');
    }
    return Teacher(
      id: StringExt.from(data['id']) ?? id,
      firstName: StringExt.from(data['first_name']) ?? firstName,
      lastName: StringExt.from(data['last_name']) ?? lastName,
      schoolBoardId: StringExt.from(data['school_board_id']) ?? schoolBoardId,
      schoolId: StringExt.from(data['school_id']) ?? schoolId,
      accessLevel: data['access_level'] == null
          ? accessLevel
          : AccessLevel.fromSerialized(data['access_level']),
      hasRegisteredAccount: data['has_registered_account'] ?? false,
      groups: ListExt.from(data['groups'],
              deserializer: (e) => StringExt.from(e) ?? '-1') ??
          groups,
      phone: PhoneNumber.from(data['phone']) ?? phone,
      email: StringExt.from(data['email']) ?? email,
      dateBirth: null,
      address: Address.from(data['address']) ?? address,
      itineraries: ListExt.from(data['itineraries'],
              deserializer: Itinerary.fromSerialized) ??
          itineraries,
      visitingPriorities: MapExt.from(data['visiting_priorities'],
              deserializer: (e) => VisitingPriority
                  .values[IntExt.from(e) ?? VisitingPriority.low.index]) ??
          _visitingPriorities,
    );
  }

  @override
  String toString() {
    return 'Teacher{${super.toString()}, schoolId: $schoolId, groups: $groups}';
  }
}
