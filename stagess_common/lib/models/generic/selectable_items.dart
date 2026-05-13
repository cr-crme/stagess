import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

class SelectableItem extends ItemSerializable {
  final int index;
  final bool isSelected;
  bool get isNotSelected => !isSelected;

  SelectableItem({
    super.id,
    this.index = -1,
    this.isSelected = false,
  });

  SelectableItem.fromSerialized(super.map)
      : index = IntExt.from(map?['index']) ?? -1,
        isSelected = BoolExt.from(map?['is_selected']) ?? false,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id.serialize(),
      'index': index.serialize(),
      'is_selected': isSelected.serialize(),
    };
  }

  @override
  String toString() {
    return 'SelectableBoxesItem(index: $index, isSelected: $isSelected)';
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'index': FetchableFields.optional,
        'is_selected': FetchableFields.optional,
      });

  SelectableItem copyWith({
    int? index,
    bool? isSelected,
  }) {
    return SelectableItem(
      id: id,
      index: index ?? this.index,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
