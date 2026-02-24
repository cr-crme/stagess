import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_form_controller.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_form_screen.dart';
import 'package:stagess/screens/student/pages/pdf/skill_pdf_template.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('InternshipEvaluationSkill');

class EvaluationSkill extends StatefulWidget {
  const EvaluationSkill({
    super.key,
    required this.internshipId,
  });

  final String internshipId;

  @override
  State<EvaluationSkill> createState() => _EvaluationSkillState();
}

class _EvaluationSkillState extends State<EvaluationSkill> {
  static const _interline = 12.0;
  int _currentEvaluationIndex = -1;
  int _nbPreviousEvaluations = -1;

  List<InternshipEvaluationSkill> get _evaluations =>
      InternshipsProvider.of(context)
          .fromId(widget.internshipId)
          .skillEvaluations;

  void _resetIndex() {
    if (_nbPreviousEvaluations != _evaluations.length) {
      _currentEvaluationIndex = _evaluations.length - 1;
      _nbPreviousEvaluations = _evaluations.length;
    }
  }

  Widget _buildSelectEvaluationFromDate() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Row(
        children: [
          const Text('Évaluation du\u00a0: '),
          DropdownButton<int>(
            value: _currentEvaluationIndex,
            onChanged: (value) =>
                setState(() => _currentEvaluationIndex = value!),
            items: _evaluations
                .asMap()
                .keys
                .map(
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(
                      DateFormat(
                        'dd MMMM yyyy',
                        'fr_CA',
                      ).format(_evaluations[index].date),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentAtMeeting() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: _evaluations[_currentEvaluationIndex].presentAtEvaluation.isEmpty
          ? Container()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personnes présentes',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ItemizedText(
                    _evaluations[_currentEvaluationIndex].presentAtEvaluation,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buillSkillSection(Specialization specialization) {
    return _evaluations[_currentEvaluationIndex]
            .skills
            .where(
              (e) =>
                  e.specializationId == specialization.id &&
                  (e.appreciation == SkillAppreciation.acquired ||
                      e.appreciation == SkillAppreciation.toPursuit ||
                      e.appreciation == SkillAppreciation.failed),
            )
            .isEmpty
        ? Container()
        : Padding(
            padding: const EdgeInsets.only(bottom: _interline),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specialization.idWithName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                _buildSkill(
                  title: 'Compétences réussies',
                  skills: _evaluations[_currentEvaluationIndex]
                      .skills
                      .where(
                        (e) =>
                            e.specializationId == specialization.id &&
                            e.appreciation == SkillAppreciation.acquired,
                      )
                      .toList(),
                ),
                _buildSkill(
                  title: 'Compétences à poursuivre',
                  skills: _evaluations[_currentEvaluationIndex]
                      .skills
                      .where(
                        (e) =>
                            e.specializationId == specialization.id &&
                            e.appreciation == SkillAppreciation.toPursuit,
                      )
                      .toList(),
                ),
                _buildSkill(
                  title: 'Compétences non réussies',
                  skills: _evaluations[_currentEvaluationIndex]
                      .skills
                      .where(
                        (e) =>
                            e.specializationId == specialization.id &&
                            e.appreciation == SkillAppreciation.failed,
                      )
                      .toList(),
                ),
              ],
            ),
          );
  }

  Widget _buildSkill({
    required String title,
    required List<SkillEvaluation> skills,
  }) {
    return skills.isEmpty
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.only(bottom: _interline),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ItemizedText(skills.map((e) => e.skillName).toList()),
                ),
              ],
            ),
          );
  }

  Widget _buildComment() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Commentaires sur le stage',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              _evaluations[_currentEvaluationIndex].comments.isEmpty
                  ? 'Aucun commentaire'
                  : _evaluations[_currentEvaluationIndex].comments,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowOtherDate() {
    final controller = SkillEvaluationFormController.fromInternshipId(
      context,
      internshipId: widget.internshipId,
      evaluationIndex: _currentEvaluationIndex,
      canModify: false,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: SkillEvaluationFormScreen(
                      rootContext: context,
                      formController: controller,
                      editMode: false,
                    ),
                  ),
                );
              },
              child: const Text('Voir l\'évaluation détaillée'),
            ),
            SizedBox(width: 12),
            IconButton(
                onPressed: () {
                  showPdfDialog(
                    context,
                    pdfGeneratorCallback: (context, format) =>
                        generateSkillEvaluationPdf(context, format,
                            controller: controller),
                  );
                },
                icon: Icon(
                  Icons.picture_as_pdf,
                  color: Theme.of(context).colorScheme.primary,
                ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building EvaluationSkill for internship: ${widget.internshipId}',
    );

    final internship = InternshipsProvider.of(
      context,
    ).fromId(widget.internshipId);

    _resetIndex();

    late final Specialization specialization;
    try {
      specialization = EnterprisesProvider.of(context)
          .fromId(internship.enterpriseId)
          .jobs
          .fromId(internship.jobId)
          .specialization;
    } catch (e) {
      return SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: AnimatedExpandingCard(
        elevation: 0.0,
        header: (ctx, isExpanded) => Text(
          'C1. Compétences spécifiques du métier',
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(color: Colors.black),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_evaluations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Text('Aucune évaluation disponible pour ce stage.'),
              ),
            if (_evaluations.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectEvaluationFromDate(),
                  _buildPresentAtMeeting(),
                  _buillSkillSection(specialization),
                  if (internship.extraSpecializationIds.isNotEmpty)
                    ...internship.extraSpecializationIds.asMap().keys.map(
                          (index) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buillSkillSection(
                                ActivitySectorsService.specialization(
                                  internship.extraSpecializationIds[index],
                                ),
                              ),
                            ],
                          ),
                        ),
                  _buildComment(),
                  _buildShowOtherDate(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
