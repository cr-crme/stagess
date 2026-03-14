import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

class SelectableTextItem extends ItemSerializable {
  final int index;
  final String text;
  final bool isSelected;

  SelectableTextItem({
    super.id,
    this.index = -1,
    this.text = '',
    this.isSelected = false,
  });

  SelectableTextItem.fromSerialized(super.map)
      : index = IntExt.from(map?['index']) ?? -1,
        text = StringExt.from(map?['text']) ?? '',
        isSelected = BoolExt.from(map?['is_selected']) ?? false,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id.serialize(),
      'index': index.serialize(),
      'text': text.serialize(),
      'is_selected': isSelected.serialize(),
    };
  }

  @override
  String toString() {
    return 'SelectableTextBoxesItem(index: $index, text: $text, isSelected: $isSelected)';
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'index': FetchableFields.optional,
        'text': FetchableFields.optional,
        'is_selected': FetchableFields.optional,
      });

  SelectableTextItem copyWith({
    String? text,
    bool? isSelected,
  }) {
    return SelectableTextItem(
      id: id,
      index: index,
      text: text ?? this.text,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
