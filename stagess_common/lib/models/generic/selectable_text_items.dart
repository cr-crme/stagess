import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';

class SelectableTextItem extends ItemSerializable {
  final String text;
  final bool isSelected;

  SelectableTextItem({
    super.id,
    this.text = '',
    this.isSelected = false,
  });

  SelectableTextItem.fromSerialized(super.map)
      : text = map?['text'] ?? '',
        isSelected = map?['is_selected'] ?? false,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'text': text,
      'is_selected': isSelected,
    };
  }

  @override
  String toString() {
    return 'SelectableTextBoxesItem(text: $text, isSelected: $isSelected)';
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'text': FetchableFields.optional,
        'is_selected': FetchableFields.optional,
      });

  SelectableTextItem copyWith({
    String? text,
    bool? isSelected,
  }) {
    return SelectableTextItem(
      id: id,
      text: text ?? this.text,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
