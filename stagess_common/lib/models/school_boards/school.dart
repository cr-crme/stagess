import 'dart:typed_data';

import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

class School extends ItemSerializable {
  final String name;
  final Address address;
  final PhoneNumber phone;
  final Uint8List logo;

  School({
    super.id,
    required this.name,
    required this.address,
    required this.phone,
    required Uint8List? logo,
  }) : logo = (logo != null && logo.length > 2) ? logo : Uint8List(0);

  static School get empty => School(
        name: '',
        id: null,
        address: Address.empty,
        phone: PhoneNumber.empty,
        logo: Uint8List(0),
      );

  School.fromSerialized(super.map)
      : name = StringExt.from(map?['name']) ?? 'Unnamed school',
        address = Address.fromSerialized(map?['address'] ?? {}),
        phone = PhoneNumber.fromSerialized(map?['phone'] ?? {}),
        logo = _deserializeLogo(map?['logo']),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'name': name.serialize(),
      'address': address.serialize(),
      'phone': phone.serialize(),
      'logo': _serializeLogo(logo),
    };
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'name': FetchableFields.mandatory,
        'address': Address.fetchableFields,
        'phone': PhoneNumber.fetchableFields,
        'logo': FetchableFields.optional
          ..addAll(FetchableFields.reference({'*': FetchableFields.mandatory})),
      });

  School copyWith(
          {String? id,
          String? name,
          Address? address,
          PhoneNumber? phone,
          Uint8List? logo}) =>
      School(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        logo: logo ?? this.logo,
      );

  School copyWithData(Map? data) {
    if (data == null) return copyWith();

    return School(
      id: StringExt.from(data['id']) ?? id,
      name: StringExt.from(data['name']) ?? name,
      address: Address.from(data['address']) ?? address,
      phone: PhoneNumber.from(data['phone']) ?? phone,
      logo: _deserializeLogo(data['logo']),
    );
  }
}

dynamic _serializeLogo(Uint8List logo) {
  // [logo] needs to be a map to prevent backend to skip the check on field to be skipped by the backend
  return {'data': logo};
}

Uint8List _deserializeLogo(dynamic logoData) {
  if (logoData is List && logoData.length > 2) {
    return Uint8List.fromList(logoData.cast<int>());
  }
  if (logoData is Map &&
      logoData['data'] is List &&
      (logoData['data'] as List).length > 2) {
    return _deserializeLogo(logoData['data']);
  }
  return Uint8List(0);
}
