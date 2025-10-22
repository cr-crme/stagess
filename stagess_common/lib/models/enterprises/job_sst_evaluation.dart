part of 'package:stagess_common/models/enterprises/job.dart';

class JobSstEvaluation extends ItemSerializable {
  final Map<String, List<String>?> questions;
  DateTime date;

  bool get isFilled => questions.isNotEmpty;

  void update({
    required Map<String, List<String>?> questions,
  }) {
    this.questions.clear();
    this.questions.addAll({...questions});
    this.questions.removeWhere((key, value) => value == null);

    date = DateTime.now();
  }

  JobSstEvaluation({
    super.id,
    required this.questions,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  static JobSstEvaluation get empty =>
      JobSstEvaluation(questions: {}, date: DateTime(0));

  JobSstEvaluation copyWith({
    String? id,
    Map<String, List<String>?>? questions,
    DateTime? date,
  }) =>
      JobSstEvaluation(
        id: id ?? this.id,
        questions: questions ?? this.questions,
        date: date ?? this.date,
      );

  JobSstEvaluation.fromSerialized(super.map)
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

  @override
  String toString() => 'JobSstEvaluation($questions, $date)';
}
