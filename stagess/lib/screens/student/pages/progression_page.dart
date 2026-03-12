import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/internships_helpers.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/screens/student/pages/form_dialogs/widgets/student_visa_form.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('SkillsPage');

class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building SkillsPage for student: $studentId');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkillCard(studentId: studentId),
          StudentVisaForm(studentId: studentId),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final skills =
        InternshipsHelpers.getStudentSkills(context, studentId: studentId);

    return AnimatedExpandingCard(
        header: (context, isExpanded) => ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Plan de formation',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: Colors.black),
                ),
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkillTile(
                title: 'Compétences réussies',
                skills:
                    InternshipsHelpers.filterAcquiredSkills(skills: skills)),
            _SkillTile(
                title: 'Compétences à poursuivre',
                skills:
                    InternshipsHelpers.filterToPursuitSkills(skills: skills)),
            SizedBox(height: 16.0),
          ],
        ));
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
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.black)),
          Text('Nombre total = ${_countNumberOfSkills()}',
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
        .firstWhere((skill) => skill.idWithName == skillEvaluation.skillName);
    return skill.complexity;
  }

  List<String> skillsToStrings(Specialization specialization) {
    return skills[specialization]!
        .sorted((a, b) => a.skillName.compareTo(b.skillName))
        .map((skillEvaluation) =>
            '${skillEvaluation.skillName}\u00a0(Niv.${_skillComplexity(skillEvaluation)})')
        .toList();
  }
}
