import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/extended_item_serializable.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

class Person extends ExtendedItemSerializable {
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime? dateBirth;

  final PhoneNumber? phone;
  final String? email;
  final Address? address;

  Person({
    super.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.dateBirth,
    required this.phone,
    required this.email,
    required this.address,
  });

  static Person get empty => Person(
      firstName: '',
      middleName: null,
      lastName: '',
      address: null,
      dateBirth: null,
      email: null,
      id: null,
      phone: null);

  static Person? from(map) {
    if (map == null) return null;
    return Person.fromSerialized(map);
  }

  Person.fromSerialized(super.map)
      : firstName = StringExt.from(map?['first_name']) ?? '',
        middleName = StringExt.from(map?['middle_name']),
        lastName = StringExt.from(map?['last_name']) ?? '',
        dateBirth = DateTimeExt.from(map?['date_birth']),
        phone = PhoneNumber.from(map?['phone']),
        email = StringExt.from(map?['email']),
        address = Address.from(map?['address']),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'first_name': firstName.serialize(),
        'middle_name': middleName?.serialize(),
        'last_name': lastName.serialize(),
        'date_birth': dateBirth?.serialize(),
        'phone': phone?.serialize(),
        'email': email?.serialize(),
        'address': address?.serialize(),
      };

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'first_name': FetchableFields.mandatory,
        'middle_name': FetchableFields.mandatory,
        'last_name': FetchableFields.mandatory,
        'date_birth': FetchableFields.optional,
        'phone': PhoneNumber.fetchableFields,
        'email': FetchableFields.optional,
        'address': Address.fetchableFields,
      });

  Person copyWith({
    String? id,
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateBirth,
    PhoneNumber? phone,
    String? email,
    Address? address,
  }) =>
      Person(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        middleName: middleName ?? this.middleName,
        lastName: lastName ?? this.lastName,
        dateBirth: dateBirth ?? this.dateBirth,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
      );

  @override
  Person copyWithData(Map<String, dynamic> data) {
    // Make sure data does not contain unrecognized fields
    if (data.keys.any((key) => ![
          'id',
          'first_name',
          'middle_name',
          'last_name',
          'date_birth',
          'phone',
          'email',
          'address',
        ].contains(key))) {
      throw InvalidFieldException('Invalid field data detected');
    }
    return Person(
      id: StringExt.from(data['id']) ?? id,
      firstName: StringExt.from(data['first_name']) ?? firstName,
      middleName: StringExt.from(data['middle_name']) ?? middleName,
      lastName: StringExt.from(data['last_name']) ?? lastName,
      dateBirth: DateTimeExt.from(data['date_birth']) ?? dateBirth,
      phone: PhoneNumber.from(data['phone']) ?? phone,
      email: StringExt.from(data['email']) ?? email,
      address: Address.from(data['address']) ?? address,
    );
  }

  ///
  /// Full name without the middle name
  String get fullName => '$firstName${lastName.isEmpty ? '' : ' $lastName'}';

  ///
  /// Initials of the first and last name
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  @override
  String toString() =>
      '$firstName${middleName == null ? '' : ' $middleName'}${lastName.isEmpty ? '' : ' $lastName'}';
}
