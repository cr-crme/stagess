import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/extended_item_serializable.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

class EmptyItem extends ExtendedItemSerializable {
  EmptyItem({super.id});

  static EmptyItem? from(Map? map) {
    if (map == null) return null;
    return EmptyItem.fromSerialized(map);
  }

  EmptyItem.fromSerialized(super.map) : super.fromSerialized();

  static FetchableFields get fetchableFields =>
      FetchableFields.reference({'id': FetchableFields.mandatory});

  @override
  Map<String, dynamic> serializedMap() => {'id': id.serialize()};
  EmptyItem copyWith({String? id}) => EmptyItem(id: id ?? this.id);

  @override
  EmptyItem copyWithData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return copyWith();

    if (data.keys.any((key) => !['id'].contains(key))) {
      throw InvalidFieldException('Invalid field data detected');
    }
    return EmptyItem(id: StringExt.from(data['id']) ?? id);
  }
}
