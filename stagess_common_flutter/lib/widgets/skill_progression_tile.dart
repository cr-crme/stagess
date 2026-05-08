import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/helpers/internships_helpers.dart';
import 'package:stagess_common_flutter/widgets/itemized_text.dart';

class SkillProgressionTile extends StatelessWidget {
  const SkillProgressionTile({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final skills =
        InternshipsHelpers.getStudentSkills(context, studentId: studentId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkillTile(
            title: 'Compétences réussies',
            skills: InternshipsHelpers.filterAcquiredSkills(skills: skills)),
        _SkillTile(
            title: 'Compétences à poursuivre',
            skills: InternshipsHelpers.filterToPursuitSkills(skills: skills)),
        SizedBox(height: 16.0),
      ],
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.title, required this.skills});

  final String title;
  final Map<Specialization, List<SkillEvaluation>> skills;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title (N = ${_countNumberOfSkills()})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.black)),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: skills.keys
                  .map(
                    (specialization) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (skills[specialization]!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                specialization.idWithName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ItemizedText(skillsToStrings(specialization)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  int _countNumberOfSkills() {
    int cmp = 0;
    for (final specialization in skills.keys) {
      cmp += skills[specialization]!.length;
    }
    return cmp;
  }

  String _skillComplexity(SkillEvaluation skillEvaluation) {
    final specialization =
        ActivitySectorsService.specialization(skillEvaluation.specializationId);
    final skill = specialization.skills
        .firstWhere((skill) => skill.id == skillEvaluation.skillId);
    return skill.complexity;
  }

  List<String> skillsToStrings(Specialization specialization) {
    return skills[specialization]!
        .sorted((a, b) => a.skillId.compareTo(b.skillId))
        .map((skillEvaluation) =>
            '${ActivitySectorsService.skillOrNull(skillEvaluation.skillId)?.idWithName ?? 'Compétence non trouvée'}'
            '\u00a0(Niv.${_skillComplexity(skillEvaluation)})')
        .toList();
  }
}
