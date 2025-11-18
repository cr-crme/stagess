import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/internships/internship.dart';

class SstEvaluation extends ItemSerializable {
  final Map<String, List<String>?> questions;
  DateTime date;

  void update({
    required Map<String, List<String>?> questions,
  }) {
    this.questions.clear();
    this.questions.addAll({...questions});
    this.questions.removeWhere((key, value) => value == null);

    date = DateTime.now();
  }

  SstEvaluation({
    super.id,
    required this.questions,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  static SstEvaluation get empty =>
      SstEvaluation(questions: {}, date: DateTime(0));

  SstEvaluation copyWith({
    String? id,
    Map<String, List<String>?>? questions,
    DateTime? date,
  }) =>
      SstEvaluation(
        id: id ?? this.id,
        questions: questions ?? this.questions,
        date: date ?? this.date,
      );

  SstEvaluation.fromSerialized(super.map)
      : questions = {
          for (final entry in (map?['questions'] as Map? ?? {}).entries)
            entry.key: (entry.value as List?)?.map((e) => e as String).toList()
        },
        date = DateTimeExt.from(map?['date']) ?? DateTime(0),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id.serialize(),
        'questions': questions,
        'date': date.serialize(),
      };
  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'questions': FetchableFields.optional,
        'date': FetchableFields.mandatory,
      });

  @override
  String toString() => 'JobSstEvaluation($questions, $date)';
}
