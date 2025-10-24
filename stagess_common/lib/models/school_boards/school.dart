import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

class School extends ItemSerializable {
  final String name;
  final Address address;
  final PhoneNumber phone;

  School({
    super.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  static School get empty => School(
        name: '',
        id: null,
        address: Address.empty,
        phone: PhoneNumber.empty,
      );

  School.fromSerialized(super.map)
      : name = StringExt.from(map?['name']) ?? 'Unnamed school',
        address = Address.fromSerialized(map?['address'] ?? {}),
        phone = PhoneNumber.fromSerialized(map?['phone'] ?? {}),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'name': name.serialize(),
      'address': address.serialize(),
      'phone': phone.serialize(),
    };
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'name': FetchableFields.mandatory,
        'address': Address.fetchableFields,
        'phone': PhoneNumber.fetchableFields,
      });

  School copyWith(
          {String? id, String? name, Address? address, PhoneNumber? phone}) =>
      School(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
      );

  School copyWithData(Map<String, dynamic> data) {
    return School(
      id: StringExt.from(data['id']) ?? id,
      name: data['name'] ?? name,
      address: Address.fromSerialized(data['address'] ?? {}),
      phone: PhoneNumber.fromSerialized(data['phone'] ?? {}),
    );
  }
}
