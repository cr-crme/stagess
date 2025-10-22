import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

class JobComment extends ItemSerializable {
  final String comment;
  final String teacherId;
  final DateTime date;

  JobComment(
      {super.id,
      required this.comment,
      required this.teacherId,
      required this.date});

  JobComment.fromSerialized(super.map)
      : comment = StringExt.from(map?['comment']) ?? '',
        teacherId = StringExt.from(map?['teacher_id']) ?? '',
        date = DateTimeExt.from(map?['date']) ?? DateTime(0),
        super.fromSerialized();

  JobComment copyWith({
    String? id,
    String? comment,
    String? teacherId,
    DateTime? date,
  }) {
    return JobComment(
      id: id ?? this.id,
      comment: comment ?? this.comment,
      teacherId: teacherId ?? this.teacherId,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id.serialize(),
        'comment': comment.serialize(),
        'teacher_id': teacherId.serialize(),
        'date': date.serialize(),
      };

  @override
  String toString() {
    return 'JobComments{comment: $comment, teacherId: $teacherId, date: $date}';
  }
}
