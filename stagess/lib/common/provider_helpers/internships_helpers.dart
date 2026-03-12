import 'package:flutter/material.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

final _logger = Logger('InternshipsHelpers');

class InternshipsHelpers {
  static Map<Specialization, List<SkillEvaluation>> getStudentSkills(
      BuildContext context,
      {required String studentId}) {
    _logger.finer('Fetching all skills for student: $studentId');

    final enterprises = EnterprisesProvider.of(context, listen: false);
    final internships =
        InternshipsProvider.of(context, listen: false).byStudentId(studentId);

    Map<Specialization, List<SkillEvaluation>> out = {};
    for (final internship in internships) {
      final List<Specialization?> specializations = [];

      // Fetch all the specialization of the current internship
      specializations.add(enterprises
          .fromIdOrNull(internship.enterpriseId)
          ?.jobs[internship.currentContract?.jobId]
          .specialization);
      specializations.addAll(
          (internship.currentContract?.extraSpecializationIds ?? [])
              .map((id) => ActivitySectorsService.specialization(id)));

      specializations.removeWhere((specialization) => specialization == null);

      for (final specialization in specializations) {
        if (!out.containsKey(specialization)) out[specialization!] = [];

        for (final evaluation in internship.skillEvaluations) {
          for (final skill in evaluation.skills) {
            if (specialization!.skills
                .any((e) => e.idWithName == skill.skillName)) {
              if (out[specialization]!
                  .any((e) => e.skillName == skill.skillName)) {
                final index = out[specialization]!
                    .indexWhere((e) => e.skillName == skill.skillName);
                out[specialization]![index] = skill;
              } else {
                out[specialization]!.add(skill);
              }
            }
          }
        }
      }
    }
    return out;
  }

  static Map<Specialization, List<SkillEvaluation>> filterAcquiredSkills(
      {required Map<Specialization, List<SkillEvaluation>> skills}) {
    _logger.finer('Filtering acquired skills');

    final Map<Specialization, List<SkillEvaluation>> out = {};
    for (final specialization in skills.keys) {
      out[specialization] = [];
      for (final skillEvaluation in skills[specialization]!) {
        if (skillEvaluation.appreciation == SkillAppreciation.acquired) {
          out[specialization]!.add(skillEvaluation);
        }
      }
    }
    return out;
  }

  static Map<Specialization, List<SkillEvaluation>> filterToPursuitSkills(
      {required Map<Specialization, List<SkillEvaluation>> skills}) {
    _logger.finer('Fetching skills to pursue');

    // Make sure no previously acheived evaluation overrides to fail
    final acquired = InternshipsHelpers.filterAcquiredSkills(skills: skills);

    final Map<Specialization, List<SkillEvaluation>> out = {};
    for (final specialization in skills.keys) {
      if (!out.containsKey(specialization)) out[specialization] = [];
      for (final skillEvaluation in skills[specialization]!) {
        if (!acquired[specialization]!
                .any((eval) => eval.skillName == skillEvaluation.skillName) &&
            (skillEvaluation.appreciation == SkillAppreciation.toPursuit ||
                skillEvaluation.appreciation == SkillAppreciation.failed)) {
          out[specialization]!.add(skillEvaluation);
        }
      }
    }
    return out;
  }
}
