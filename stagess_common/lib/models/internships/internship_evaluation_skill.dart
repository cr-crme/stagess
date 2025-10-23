import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/internships/task_appreciation.dart';

enum SkillAppreciation {
  acquired,
  toPursuit,
  failed,
  notApplicable,
  notSelected;

  String get name {
    switch (this) {
      case SkillAppreciation.acquired:
        return 'Réussie';
      case SkillAppreciation.toPursuit:
        return 'À poursuivre';
      case SkillAppreciation.failed:
        return 'Non réussie';
      case SkillAppreciation.notApplicable:
        return 'Non applicable';
      case SkillAppreciation.notSelected:
        return '';
    }
  }
}

enum SkillEvaluationGranularity {
  global,
  byTask;

  @override
  String toString() {
    switch (this) {
      case SkillEvaluationGranularity.global:
        return 'Évaluation globale de la compétence';
      case SkillEvaluationGranularity.byTask:
        return 'Évaluation tâche par tâche';
    }
  }
}

class SkillEvaluation extends ItemSerializable {
  final String specializationId;
  final String skillName;
  final List<TaskAppreciation> tasks;

  final SkillAppreciation appreciation;
  final String comments;

  SkillEvaluation({
    super.id,
    required this.specializationId,
    required this.skillName,
    required this.tasks,
    required this.appreciation,
    required this.comments,
  });
  SkillEvaluation.fromSerialized(super.map)
      : specializationId = map?['job_id'] ?? '',
        skillName = map?['skill'] ?? '',
        tasks = map?['tasks'] == null
            ? []
            : (map!['tasks'] as List)
                .map((e) => TaskAppreciation.fromSerialized(e))
                .toList(),
        appreciation = map?['appreciation'] == null
            ? SkillAppreciation.notSelected
            : SkillAppreciation.values[map!['appreciation']],
        comments = map?['comments'] ?? '',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'job_id': specializationId,
        'skill': skillName,
        'tasks': tasks.map((e) => e.serialize()).toList(),
        'appreciation': appreciation.index,
        'comments': comments,
      };

  @override
  String toString() {
    return 'SkillEvaluation(specializationId: $specializationId, '
        'skillName: $skillName, '
        'tasks: $tasks, '
        'appreciation: $appreciation, '
        'comments: $comments)';
  }
}

class InternshipEvaluationSkill extends ItemSerializable {
  static const String currentVersion = '1.0.0';

  DateTime date;
  List<String> presentAtEvaluation;
  final SkillEvaluationGranularity skillGranularity;
  List<SkillEvaluation> skills;
  String comments;
  // The version of the evaluation form (so data can be parsed properly)
  String formVersion;

  InternshipEvaluationSkill({
    super.id,
    required this.date,
    required this.presentAtEvaluation,
    required this.skillGranularity,
    required this.skills,
    required this.comments,
    required this.formVersion,
  });
  InternshipEvaluationSkill.fromSerialized(super.map)
      : date = map?['date'] == null
            ? DateTime(0)
            : DateTime.fromMillisecondsSinceEpoch(map!['date']),
        presentAtEvaluation =
            (map?['present'] as List?)?.map((e) => e as String).toList() ?? [],
        skillGranularity = map?['skill_granularity'] == null
            ? SkillEvaluationGranularity.global
            : SkillEvaluationGranularity.values[map!['skill_granularity']],
        skills = (map?['skills'] as List?)
                ?.map((e) => SkillEvaluation.fromSerialized(e))
                .toList() ??
            [],
        comments = map?['comments'] ?? '',
        formVersion = map?['form_version'] ?? currentVersion,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'present': presentAtEvaluation,
      'skill_granularity': skillGranularity.index,
      'skills': skills.map((e) => e.serialize()).toList(),
      'comments': comments,
      'form_version': formVersion,
    };
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'date': FetchableFields.optional,
        'present': FetchableFields.optional,
        'skill_granularity': FetchableFields.optional,
        'skills': FetchableFields.optional,
        'comments': FetchableFields.optional,
        'form_version': FetchableFields.optional,
      });

  @override
  String toString() {
    return 'InternshipEvaluationSkill(date: $date, '
        'presentAtEvaluation: $presentAtEvaluation, '
        'skillGranularity: $skillGranularity, '
        'skills: $skills, '
        'comments: $comments, '
        'form_version: $formVersion)';
  }
}
