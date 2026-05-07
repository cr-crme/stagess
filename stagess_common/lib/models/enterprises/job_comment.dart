import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

class JobComment extends ItemSerializable {
  final String comment;
  final String userId;
  final DateTime date;

  JobComment(
      {super.id,
      required this.comment,
      required this.userId,
      required this.date});

  JobComment.fromSerialized(super.map)
      : comment = StringExt.from(map?['comment']) ?? '',
        userId = StringExt.from(map?['user_id']) ?? '',
        date = DateTimeExt.from(map?['date']) ?? DateTime(0),
        super.fromSerialized();

  JobComment copyWith({
    String? id,
    String? comment,
    String? userId,
    DateTime? date,
  }) {
    return JobComment(
      id: id ?? this.id,
      comment: comment ?? this.comment,
      userId: userId ?? this.userId,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id.serialize(),
        'comment': comment.serialize(),
        'user_id': userId.serialize(),
        'date': date.serialize(),
      };

  @override
  String toString() {
    return 'JobComments{comment: $comment, userId: $userId, date: $date}';
  }
}
