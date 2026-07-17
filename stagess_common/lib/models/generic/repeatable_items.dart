import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:meta/meta.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

class RepeatableItem extends ItemSerializable {
  final int index;
  final bool isSelected;
  bool get isNotSelected => !isSelected;

  RepeatableItem({
    super.id,
    this.index = -1,
    this.isSelected = false,
  });

  RepeatableItem.fromSerialized(super.map)
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
    return 'RepeatableItem(index: $index, isSelected: $isSelected)';
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'index': FetchableFields.optional,
        'is_selected': FetchableFields.optional,
      });

  ///
  /// This method must be overloaded if the class is extended,
  /// to return an instance of the extended class.
  @mustBeOverridden
  RepeatableItem copyWith({int? index, bool? isSelected}) {
    return RepeatableItem(
      id: id,
      index: index ?? this.index,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  ///
  /// Dispose is called right before the object is removed from the list.
  /// It can be overloaded in the extended class to perform any necessary cleanup.
  void dispose() {}
}
