import 'dart:async';

import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/map_providers.dart';
import 'package:stagess_common/models/internships/internship.dart';

class Address extends ItemSerializable {
  Address({
    super.id,
    this.civicNumber,
    this.street,
    this.apartment,
    this.city,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  static Address get empty => Address();

  final int? civicNumber;
  final String? street;
  final String? apartment;
  final String? city;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  // coverage:ignore-start
  static Future<Address?> fromString(String value, {String? id}) async {
    return await ReverseGeocodingProvider.instance.find(value, id: id);
  }
  // coverage:ignore-end

  @override
  Map<String, dynamic> serializedMap() => {
        'civic': civicNumber?.serialize(),
        'street': street?.serialize(),
        'apartment': apartment?.serialize(),
        'city': city?.serialize(),
        'postal_code': postalCode?.serialize(),
        'latitude': latitude?.serialize(),
        'longitude': longitude?.serialize(),
      };

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'civic': FetchableFields.optional,
        'street': FetchableFields.optional,
        'apartment': FetchableFields.optional,
        'city': FetchableFields.optional,
        'postal_code': FetchableFields.optional,
        'latitude': FetchableFields.optional,
        'longitude': FetchableFields.optional,
      });
  static FetchableFields get mandatoryFetchableFields =>
      FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'civic': FetchableFields.mandatory,
        'street': FetchableFields.mandatory,
        'city': FetchableFields.mandatory,
        'postal_code': FetchableFields.mandatory,
        'latitude': FetchableFields.mandatory,
        'longitude': FetchableFields.mandatory,
      });

  static Address? from(Map? map) {
    if (map == null) return null;
    return Address.fromSerialized(map);
  }

  static Address fromSerialized(Map? map) => Address(
        id: StringExt.from(map?['id']),
        civicNumber: IntExt.from(map?['civic']),
        street: StringExt.from(map?['street']),
        apartment: StringExt.from(map?['apartment']),
        city: StringExt.from(map?['city']),
        postalCode: StringExt.from(map?['postal_code']),
        latitude: DoubleExt.from(map?['latitude']),
        longitude: DoubleExt.from(map?['longitude']),
      );

  Address copyWith({
    String? id,
    int? civicNumber,
    String? street,
    String? apartment,
    String? city,
    String? postalCode,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      id: id ?? this.id,
      civicNumber: civicNumber ?? this.civicNumber,
      street: street ?? this.street,
      apartment: apartment ?? this.apartment,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Address copyWithData(Map<String, dynamic>? data) {
    if (data == null) return copyWith();
    return Address(
      id: StringExt.from(data['id']) ?? id,
      civicNumber: IntExt.from(data['civic']) ?? civicNumber,
      street: StringExt.from(data['street']) ?? street,
      apartment: StringExt.from(data['apartment']) ?? apartment,
      city: StringExt.from(data['city']) ?? city,
      postalCode: StringExt.from(data['postal_code']) ?? postalCode,
      latitude: DoubleExt.from(data['latitude']) ?? latitude,
      longitude: DoubleExt.from(data['longitude']) ?? longitude,
    );
  }

  bool get isEmpty =>
      civicNumber == null &&
      street == null &&
      apartment == null &&
      city == null &&
      postalCode == null;
  bool get isNotEmpty => !isEmpty;

  bool get isValid =>
      civicNumber != null &&
      street != null &&
      city != null &&
      postalCode != null;
  bool get isNotValid => !isValid;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Address) return false;
    return civicNumber == other.civicNumber &&
        street == other.street &&
        apartment == other.apartment &&
        city == other.city &&
        postalCode == other.postalCode;
  }

  @override
  String toString() {
    return isValid
        ? '$civicNumber $street${apartment == null ? '' : ' #$apartment'}, $city, $postalCode'
        : '';
  }

  @override
  int get hashCode =>
      civicNumber.hashCode ^
      street.hashCode ^
      apartment.hashCode ^
      city.hashCode ^
      postalCode.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;
}
