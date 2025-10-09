import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/internships/task_appreciation.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';

class SkillEvaluationFormController {
  static const _formVersion = '1.0.0';

  SkillEvaluationFormController(
    BuildContext context, {
    required this.internshipId,
    required this.canModify,
  }) {
    clearForm(context);
  }
  int? _previousEvaluationIndex; // -1 is the last, null is not from evaluation
  bool get isFilledUsingPreviousEvaluation => _previousEvaluationIndex != null;

  final bool canModify;
  SkillEvaluationGranularity evaluationGranularity =
      SkillEvaluationGranularity.global;

  final String internshipId;
  Internship internship(context, {listen = true}) =>
      InternshipsProvider.of(context, listen: listen)[internshipId];

  final Map<String, Skill> _idToSkill = {};

  factory SkillEvaluationFormController.fromInternshipId(
    context, {
    required String internshipId,
    required int evaluationIndex,
    required bool canModify,
  }) {
    final controller = SkillEvaluationFormController(
      context,
      internshipId: internshipId,
      canModify: canModify,
    );
    controller.fillFromPreviousEvaluation(context, evaluationIndex);
    return controller;
  }

  void dispose() {
    try {
      for (final skillId in skillCommentsControllers.keys) {
        skillCommentsControllers[skillId]!.dispose();
      }
      commentsController.dispose();
    } catch (e) {
      // Do nothing
    }
  }

  void addSkill(String skillId) {
    _evaluatedSkills[skillId] = 1;

    appreciations[skillId] = SkillAppreciation.notSelected;
    skillCommentsControllers[skillId] = TextEditingController();

    taskCompleted[skillId] = {};
    final skill = _idToSkill[skillId]!;
    for (final task in skill.tasks) {
      taskCompleted[skillId]![task.title] = TaskAppreciationLevel.notEvaluated;
    }
  }

  void removeSkill(context, String skillId) {
    _evaluatedSkills[skillId] = 0;
    if (isFilledUsingPreviousEvaluation) {
      final evaluation = _previousEvaluation(context);
      final skill = _idToSkill[skillId]!;
      if (evaluation!.skills.any((e) => e.skillName == skill.idWithName)) {
        _evaluatedSkills[skillId] = -1;
      }
    }

    if (_evaluatedSkills[skillId] == 0) {
      appreciations.remove(skillId);
      skillCommentsControllers[skillId]!.dispose();
      skillCommentsControllers.remove(skillId);
      taskCompleted.remove(skillId);
    }
  }

  void clearForm(context) {
    _resetForm(context);

    final internshipTp = internship(context, listen: false);
    final enterprise =
        EnterprisesProvider.of(context, listen: false)[internshipTp
            .enterpriseId];
    final specialization = enterprise.jobs[internshipTp.jobId].specialization;

    for (final skill in specialization.skills) {
      addSkill(skill.id);
    }
  }

  InternshipEvaluationSkill? _previousEvaluation(context) {
    if (!isFilledUsingPreviousEvaluation) return null;

    final internshipTp = internship(context, listen: false);
    if (internshipTp.skillEvaluations.isEmpty) return null;

    return _previousEvaluationIndex! < 0
        ? internshipTp.skillEvaluations.last
        : internshipTp.skillEvaluations[_previousEvaluationIndex!];
  }

  void fillFromPreviousEvaluation(context, int previousEvaluationIndex) {
    // Reset the form to fresh
    _resetForm(context);
    _previousEvaluationIndex = previousEvaluationIndex;

    final evaluation = _previousEvaluation(context);
    if (evaluation == null) return;

    if (!canModify) evaluationDate = evaluation.date;

    evaluationGranularity = evaluation.skillGranularity;

    // Fill skill to evaluated as if it was all false
    wereAtMeeting.addAll(evaluation.presentAtEvaluation);

    // Now fill the structures from the evaluation
    for (final skillEvaluation in evaluation.skills) {
      final skillId = _evaluatedSkills.keys.firstWhere((skillId) {
        final skill = _idToSkill[skillId]!;
        return skill.idWithName == skillEvaluation.skillName;
      });

      addSkill(skillId);
      // Set the actual values to add (but empty) skill
      appreciations[skillId] = skillEvaluation.appreciation;
      skillCommentsControllers[skillId]!.text = skillEvaluation.comments;

      final skill = _idToSkill[skillId]!;
      for (final task in skill.tasks) {
        taskCompleted[skillId]![task.title] =
            skillEvaluation.tasks
                .firstWhereOrNull((e) => e.title == task.title)
                ?.level ??
            TaskAppreciationLevel.notEvaluated;
      }
    }

    commentsController.text = evaluation.comments;
  }

  InternshipEvaluationSkill toInternshipEvaluation() {
    final List<SkillEvaluation> skillEvaluation = [];
    for (final skillId in taskCompleted.keys) {
      final List<TaskAppreciation> tasks =
          taskCompleted[skillId]!.keys
              .map(
                (task) => TaskAppreciation(
                  title: task,
                  level: taskCompleted[skillId]![task]!,
                ),
              )
              .toList();

      final skill = _idToSkill[skillId]!;
      skillEvaluation.add(
        SkillEvaluation(
          specializationId: _skillsAreFromSpecializationId[skillId]!,
          skillName: skill.idWithName,
          tasks: tasks,
          appreciation: appreciations[skillId]!,
          comments: skillCommentsControllers[skillId]!.text,
        ),
      );
    }
    return InternshipEvaluationSkill(
      date: evaluationDate,
      presentAtEvaluation: wereAtMeeting,
      skillGranularity: evaluationGranularity,
      skills: skillEvaluation,
      comments: commentsController.text,
      formVersion: _formVersion,
    );
  }

  DateTime evaluationDate = DateTime.now();

  late final wereAtMeetingController = CheckboxWithOtherController(
    elements: wereAtMeetingOptions,
    initialValues: wereAtMeeting,
  );
  final List<String> wereAtMeetingOptions = [
    'Stagiaire',
    'Responsable en milieu de stage',
  ];
  final List<String> wereAtMeeting = [];
  void setWereAtMeeting() {
    wereAtMeeting.clear();
    wereAtMeeting.addAll(wereAtMeetingController.values);
  }

  ///
  /// _evaluatedSkill is set to 1 if it is evaluated, 0 or -1 if it is not
  /// evaluated. The negative value indicateds that it is not evaluated, but it
  /// should still be added to the results as it is a previous result from a
  /// previous evaluation
  final Map<String, int> _evaluatedSkills = {};
  bool isSkillToEvaluate(String skillId) =>
      (_evaluatedSkills[skillId] ?? 0) > 0;
  bool isNotEvaluatedButWasPreviously(String skillId) =>
      (_evaluatedSkills[skillId] ?? 0) < 0;

  ///
  /// This returns the values for all results, if [activeOnly] is set to false
  /// then it also include the one from previous evaluation which are not
  /// currently evaluated
  List<Skill> skillResults({bool activeOnly = false}) {
    List<Skill> out = [];
    for (final skillId in _evaluatedSkills.keys) {
      if (_evaluatedSkills[skillId]! > 0) {
        final skill = _idToSkill[skillId]!;
        out.add(skill);
      }
      // If the skill was not evaluated, but the evaluation continues a previous
      // one, we must keep the previous values
      if (!activeOnly && _evaluatedSkills[skillId]! < 0) {
        final skill = _idToSkill[skillId]!;
        out.add(skill);
      }
    }
    return out;
  }

  final Map<String, String> _skillsAreFromSpecializationId = {};

  void _initializeSkills(context) {
    _idToSkill.clear();

    final internshipTp = internship(context, listen: false);
    final enterprise =
        EnterprisesProvider.of(context, listen: false)[internshipTp
            .enterpriseId];

    final specialization = enterprise.jobs[internshipTp.jobId].specialization;
    for (final skill in specialization.skills) {
      _idToSkill[skill.id] = skill;
      _evaluatedSkills[skill.id] = 0;
      _skillsAreFromSpecializationId[skill.id] = specialization.id;
    }

    for (final extraSpecializationId in internshipTp.extraSpecializationIds) {
      for (final skill
          in ActivitySectorsService.specialization(
            extraSpecializationId,
          ).skills) {
        // Do not override main specializations
        if (!_idToSkill.containsKey(skill.id)) _idToSkill[skill.id] = skill;
        _evaluatedSkills[skill.id] = 0;
        _skillsAreFromSpecializationId[skill.id] = extraSpecializationId;
      }
    }
  }

  Map<String, Map<String, TaskAppreciationLevel>> taskCompleted = {};
  void _initializeTaskCompleted() {
    taskCompleted.clear();
    for (final skillId in _evaluatedSkills.keys) {
      if (_evaluatedSkills[skillId]! == 0) continue;

      final skill = _idToSkill[skillId]!;
      Map<String, TaskAppreciationLevel> tp = {};
      for (final task in skill.tasks) {
        tp[task.title] = TaskAppreciationLevel.notEvaluated;
      }
      taskCompleted[skillId] = tp;
    }
  }

  Map<String, SkillAppreciation> appreciations = {};
  bool get allAppreciationsAreDone {
    for (final skillId in appreciations.keys) {
      if (isSkillToEvaluate(skillId) &&
          appreciations[skillId] == SkillAppreciation.notSelected) {
        return false;
      }
    }
    return true;
  }

  void _initializeAppreciation() {
    appreciations.clear();
    for (final skillId in _evaluatedSkills.keys) {
      if (_evaluatedSkills[skillId] == 0) continue;
      appreciations[skillId] = SkillAppreciation.notSelected;
    }
  }

  Map<String, TextEditingController> skillCommentsControllers = {};
  void _initializeSkillCommentControllers() {
    skillCommentsControllers.clear();
    for (final skillId in _evaluatedSkills.keys) {
      if (_evaluatedSkills[skillId] == 0) continue;
      skillCommentsControllers[skillId] = TextEditingController();
    }
  }

  void _resetForm(context) {
    evaluationDate = DateTime.now();
    _previousEvaluationIndex = null;
    evaluationGranularity = SkillEvaluationGranularity.global;

    wereAtMeeting.clear();

    _initializeSkills(context);
    _initializeTaskCompleted();
    _initializeAppreciation();

    commentsController.text = '';
    _initializeSkillCommentControllers();
  }

  TextEditingController commentsController = TextEditingController();
}
