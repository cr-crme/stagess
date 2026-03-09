import 'dart:convert';

import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation.dart';

class SstEvaluation extends InternshipEvaluation {
  final List<String> presentAtEvaluation;
  final Map<String, List<String>?> questions;

  @override
  DateTime date;

  SstEvaluation({
    super.id,
    DateTime? date,
    required this.presentAtEvaluation,
    required this.questions,
  }) : date = date ?? DateTime.now();

  static SstEvaluation get empty => SstEvaluation(
      presentAtEvaluation: [], questions: {}, date: DateTime.now());

  SstEvaluation copyWith({
    String? id,
    List<String>? presentAtEvaluation,
    Map<String, List<String>?>? questions,
    DateTime? date,
  }) =>
      SstEvaluation(
        id: id ?? this.id,
        presentAtEvaluation: presentAtEvaluation ?? this.presentAtEvaluation,
        questions: questions ?? this.questions,
        date: date ?? this.date,
      );

  SstEvaluation copyWithData(Map<String, dynamic>? serialized) {
    if (serialized == null || serialized.isEmpty) return copyWith();

    return SstEvaluation(
      id: serialized['id'] ?? id,
      presentAtEvaluation: ListExt.from(serialized['present_at_evaluation'],
              deserializer: (e) => e as String)?.toList() ??
          presentAtEvaluation,
      questions: serialized['questions'] == null
          ? questions
          : {
              for (final entry
                  in (serialized['questions'] as Map? ?? {}).entries)
                entry.key:
                    (entry.value as List?)?.map((e) => e as String).toList()
            },
      date: DateTimeExt.from(serialized['date']) ?? date,
    );
  }

  SstEvaluation.fromSerialized(super.map)
      : date = DateTimeExt.from(map?['date']) ?? DateTime(0),
        presentAtEvaluation = ListExt.from(map?['present_at_evaluation'],
                deserializer: (e) => e as String)?.toList() ??
            [],
        questions = {
          for (final entry
              in (jsonDecode(map?['questions'] ?? '{}') as Map).entries)
            entry.key: (entry.value as List?)?.map((e) => e as String).toList()
        },
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id.serialize(),
        'date': date.serialize(),
        'present_at_evaluation': presentAtEvaluation.serialize(),
        'questions': jsonEncode(questions),
      };
  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'date': FetchableFields.optional,
        'present_at_evaluation': FetchableFields.optional,
        'questions': FetchableFields.optional,
      });

  @override
  String toString() => 'JobSstEvaluation($questions, $date)';
}
