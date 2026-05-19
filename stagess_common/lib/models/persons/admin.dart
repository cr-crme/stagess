import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/persons/person.dart';

class Admin extends Person {
  final String schoolBoardId;
  final String schoolId;
  final bool hasRegisteredAccount;
  bool get hasNotRegisteredAccount => !hasRegisteredAccount;
  final AccessLevel accessLevel;

  Admin({
    super.id,
    required super.firstName,
    required super.lastName,
    required this.schoolBoardId,
    required this.schoolId,
    required this.hasRegisteredAccount,
    required super.email,
    required super.phone,
    required super.address,
    required this.accessLevel,
  }) : super(dateBirth: null);

  static Admin get empty => Admin(
        firstName: '',
        lastName: '',
        schoolBoardId: '',
        schoolId: '',
        hasRegisteredAccount: false,
        email: '',
        phone: PhoneNumber.empty,
        address: Address.empty,
        accessLevel: AccessLevel.teacher,
      );

  bool get isEmpty => firstName.isEmpty && lastName.isEmpty;

  Admin.fromSerialized(super.map)
      : schoolBoardId = StringExt.from(map?['school_board_id']) ?? '',
        schoolId = StringExt.from(map?['school_id']) ?? '',
        hasRegisteredAccount =
            BoolExt.from(map?['has_registered_account']) ?? false,
        accessLevel = AccessLevel.fromSerialized(map?['access_level']),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'school_board_id': schoolBoardId.serialize(),
      'school_id': schoolId.serialize(),
      'has_registered_account': hasRegisteredAccount.serialize(),
      'access_level': accessLevel.serialize(),
    });

  static FetchableFields get fetchableFields => Person.fetchableFields
    ..addAll(FetchableFields.reference({
      'school_board_id': FetchableFields.mandatory,
      'school_id': FetchableFields.mandatory,
      'email': FetchableFields.mandatory,
      'has_registered_account': FetchableFields.mandatory,
      'access_level': FetchableFields.mandatory,
    }));

  @override
  Admin copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? schoolBoardId,
    String? schoolId,
    bool? hasRegisteredAccount,
    String? email,
    PhoneNumber? phone,
    Address? address,
    DateTime? dateBirth,
    AccessLevel? accessLevel,
  }) =>
      Admin(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        schoolBoardId: schoolBoardId ?? this.schoolBoardId,
        schoolId: schoolId ?? this.schoolId,
        hasRegisteredAccount: hasRegisteredAccount ?? this.hasRegisteredAccount,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        accessLevel: accessLevel ?? this.accessLevel,
      );

  @override
  Admin copyWithData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return copyWith();

    // Make sure data does not contain unrecognized fields
    if (data.keys.any((key) => ![
          'id',
          'school_board_id',
          'school_id',
          'has_registered_account',
          'first_name',
          'last_name',
          'date_birth',
          'address',
          'phone',
          'email',
          'access_level',
        ].contains(key))) {
      throw InvalidFieldException('Invalid field data detected');
    }
    return Admin(
      id: StringExt.from(data['id']) ?? id,
      firstName: StringExt.from(data['first_name']) ?? firstName,
      lastName: StringExt.from(data['last_name']) ?? lastName,
      schoolBoardId: StringExt.from(data['school_board_id']) ?? schoolBoardId,
      schoolId: StringExt.from(data['school_id']) ?? schoolId,
      hasRegisteredAccount:
          BoolExt.from(data['has_registered_account']) ?? hasRegisteredAccount,
      email: StringExt.from(data['email']) ?? email,
      accessLevel: data['access_level'] == null
          ? accessLevel
          : AccessLevel.fromSerialized(data['access_level']),
      phone: PhoneNumber.from(data['phone']) ?? phone,
      address: Address.from(data['address']) ?? address,
    );
  }

  @override
  String toString() {
    return 'Admin{${super.toString()}, schoolBoardId: $schoolBoardId, schoolId: $schoolId}';
  }
}
