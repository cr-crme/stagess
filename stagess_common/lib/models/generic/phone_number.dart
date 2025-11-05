import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';

const _regExp =
    r'^(?:\+\(d{1,3})?\s?\(?(\d{3})(?:[-.\)\s]|\)\s)?(\d{3})[-.\s]?(\d{4})(?:\s(?:poste)?\s(\d{1,6}))?$';

class PhoneNumber extends ItemSerializable {
  final String? areaCode;
  final String? cityCode;
  final String? number;
  final String? extension;

  static bool isValid(String number) => RegExp(_regExp).hasMatch(number);

  PhoneNumber(
      {super.id, this.areaCode, this.cityCode, this.number, this.extension});

  static PhoneNumber get empty => PhoneNumber();

  PhoneNumber copyWith({
    String? id,
    String? areaCode,
    String? cityCode,
    String? number,
    String? extension,
  }) {
    return PhoneNumber(
      id: id ?? this.id,
      areaCode: areaCode ?? this.areaCode,
      cityCode: cityCode ?? this.cityCode,
      number: number ?? this.number,
      extension: extension ?? this.extension,
    );
  }

  factory PhoneNumber.fromString(String number, {String? id}) {
    final reg = RegExp(_regExp);
    if (!reg.hasMatch(number)) return PhoneNumber.empty.copyWith(id: id);

    final result = RegExp(_regExp).firstMatch(number)!;
    if (result.groupCount != 4) {
      throw 'Invalid number if PhoneNumber constructor';
    }

    return PhoneNumber(
        id: id,
        areaCode: result.group(1),
        cityCode: result.group(2),
        number: result.group(3),
        extension: result.group(4));
  }

  @override
  Map<String, dynamic> serializedMap() => {'phone_number': toString()};

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'phone_number': FetchableFields.optional,
      });

  static PhoneNumber? from(Map? map) {
    if (map == null) return null;
    return PhoneNumber.fromSerialized(map);
  }

  static PhoneNumber fromSerialized(Map? map) =>
      PhoneNumber.fromString(map?['phone_number'] ?? '', id: map?['id']);

  @override
  String toString() {
    return areaCode == null || cityCode == null || number == null
        ? ''
        : '($areaCode) $cityCode-$number${extension != null ? ' poste $extension' : ''}';
  }
}
