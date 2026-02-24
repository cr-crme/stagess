import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/misc/question_file_service.dart';
import 'package:stagess/screens/internship_forms/enterprise_steps/enterprise_evaluation_screen.dart';
import 'package:stagess/screens/internship_forms/student_steps/attitude_evaluation_form_controller.dart';
import 'package:stagess/screens/internship_forms/student_steps/attitude_evaluation_screen.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_form_controller.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_form_screen.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_main_screen.dart';
import 'package:stagess/screens/internship_forms/student_steps/visa_evaluation_form_controller.dart';
import 'package:stagess/screens/internship_forms/student_steps/visa_evaluation_screen.dart';
import 'package:stagess/screens/sst_evaluation_form/sst_evaluation_form_screen.dart';
import 'package:stagess/screens/student/pages/pdf/attitude_pdf_template.dart';
import 'package:stagess/screens/student/pages/pdf/skill_pdf_template.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart'
    as attitude;
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/internships/internship_evaluation_visa.dart'
    as visa;
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('InternshipEvaluationSst');

class InternshipSkills extends StatefulWidget {
  const InternshipSkills({super.key, required this.internshipId});

  final String internshipId;

  @override
  State<InternshipSkills> createState() => _InternshipSkillsState();
}

class _InternshipSkillsState extends State<InternshipSkills> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: ExpansionPanelList(
        elevation: 0,
        expansionCallback: (index, isExpanded) =>
            setState(() => _isExpanded = !_isExpanded),
        children: [
          ExpansionPanel(
            isExpanded: _isExpanded,
            canTapOnHeader: true,
            headerBuilder: (context, isExpanded) => Text(
              'Évaluations',
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(color: Colors.black),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJob(
                  'Métier${internship.extraSpecializationIds.isNotEmpty ? ' principal' : ''}',
                  specialization: job.specialization,
                ),
                if (internship.extraSpecializationIds.isNotEmpty)
                  ...internship.extraSpecializationIds.asMap().keys.map(
                        (indexExtra) => _buildJob(
                          'Métier supplémentaire${internship.extraSpecializationIds.length > 1 ? ' (${indexExtra + 1})' : ''}',
                          specialization: ActivitySectorsService.specialization(
                            internship.extraSpecializationIds[indexExtra],
                          ),
                        ),
                      ),
                _SpecificSkillBody(
                  internship: internship,
                  evaluation: internship.skillEvaluations,
                ),
                const SizedBox(height: 16.0),
                _AttitudeBody(
                  internship: internship,
                  evaluation: internship.attitudeEvaluations,
                ),
                const SizedBox(height: 16.0),
                EvaluationSst(internship: internship),
                const SizedBox(height: 16.0),
                _PostInternshipEnterpriseBody(internship: internship),
                const SizedBox(height: 16.0),
                _VisaBody(
                  internship: internship,
                  evaluations: internship.visaEvaluations,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _interline = 12.0;
  static const TextStyle _titleStyle = TextStyle(fontWeight: FontWeight.bold);

  Widget _buildJob(String title, {required Specialization specialization}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(specialization.idWithName),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Secteur ${specialization.sector.idWithName}'),
          ),
        ],
      ),
    );
  }
}

class _SpecificSkillBody extends StatefulWidget {
  const _SpecificSkillBody({
    required this.internship,
    required this.evaluation,
  });

  final Internship internship;
  final List<InternshipEvaluationSkill> evaluation;

  @override
  State<_SpecificSkillBody> createState() => _SpecificSkillBodyState();
}

class _SpecificSkillBodyState extends State<_SpecificSkillBody> {
  static const _interline = 12.0;
  int _currentEvaluationIndex = -1;
  int _nbPreviousEvaluations = -1;

  void _resetIndex() {
    if (_nbPreviousEvaluations != widget.evaluation.length) {
      _currentEvaluationIndex = widget.evaluation.length - 1;
      _nbPreviousEvaluations = widget.evaluation.length;
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
            items: widget.evaluation
                .asMap()
                .keys
                .map(
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(
                      DateFormat(
                        'dd MMMM yyyy',
                        'fr_CA',
                      ).format(widget.evaluation[index].date),
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
      child:
          widget.evaluation[_currentEvaluationIndex].presentAtEvaluation.isEmpty
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
                        widget.evaluation[_currentEvaluationIndex]
                            .presentAtEvaluation,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buillSkillSection(Specialization specialization) {
    return widget.evaluation[_currentEvaluationIndex].skills
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
                  skills: widget.evaluation[_currentEvaluationIndex].skills
                      .where(
                        (e) =>
                            e.specializationId == specialization.id &&
                            e.appreciation == SkillAppreciation.acquired,
                      )
                      .toList(),
                ),
                _buildSkill(
                  title: 'Compétences à poursuivre',
                  skills: widget.evaluation[_currentEvaluationIndex].skills
                      .where(
                        (e) =>
                            e.specializationId == specialization.id &&
                            e.appreciation == SkillAppreciation.toPursuit,
                      )
                      .toList(),
                ),
                _buildSkill(
                  title: 'Compétences non réussies',
                  skills: widget.evaluation[_currentEvaluationIndex].skills
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
              widget.evaluation[_currentEvaluationIndex].comments.isEmpty
                  ? 'Aucun commentaire'
                  : widget.evaluation[_currentEvaluationIndex].comments,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowOtherDate() {
    final controller = SkillEvaluationFormController.fromInternshipId(
      context,
      internshipId: widget.internship.id,
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
    final teacherId =
        TeachersProvider.of(context, listen: false).currentTeacher?.id;

    _resetIndex();

    late final Specialization specialization;
    try {
      specialization = EnterprisesProvider.of(context)
          .fromId(widget.internship.enterpriseId)
          .jobs
          .fromId(widget.internship.jobId)
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

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (ctx, isExpanded) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Text(
            'C1. Compétences spécifiques du métier',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Visibility(
            visible: widget.internship.supervisingTeacherIds.contains(
              teacherId,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(18)),
              ),
              child: IconButton(
                onPressed: () => showSkillEvaluationDialog(
                  context: context,
                  internshipId: widget.internship.id,
                  editMode: true,
                ),
                icon: const Icon(Icons.add_chart_rounded),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.evaluation.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Text('Aucune évaluation disponible pour ce stage.'),
            ),
          if (widget.evaluation.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSelectEvaluationFromDate(),
                _buildPresentAtMeeting(),
                _buillSkillSection(specialization),
                if (widget.internship.extraSpecializationIds.isNotEmpty)
                  ...widget.internship.extraSpecializationIds.asMap().keys.map(
                        (index) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buillSkillSection(
                              ActivitySectorsService.specialization(
                                widget.internship.extraSpecializationIds[index],
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
    );
  }
}

class _AttitudeBody extends StatefulWidget {
  const _AttitudeBody({required this.internship, required this.evaluation});

  final Internship internship;
  final List<attitude.InternshipEvaluationAttitude> evaluation;

  @override
  State<_AttitudeBody> createState() => _AttitudeBodyState();
}

class _AttitudeBodyState extends State<_AttitudeBody> {
  static const _interline = 12.0;
  int _currentEvaluationIndex = -1;
  int _nbPreviousEvaluations = -1;

  void _resetIndex() {
    if (_nbPreviousEvaluations != widget.evaluation.length) {
      _currentEvaluationIndex = widget.evaluation.length - 1;
      _nbPreviousEvaluations = widget.evaluation.length;
    }
  }

  Widget _buildLastEvaluation() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Row(
        children: [
          const Text('Évaluation du\u00a0: '),
          DropdownButton<int>(
            value: _currentEvaluationIndex,
            onChanged: (value) =>
                setState(() => _currentEvaluationIndex = value!),
            items: widget.evaluation
                .asMap()
                .keys
                .map(
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(
                      DateFormat(
                        'dd MMMM yyyy',
                        'fr_CA',
                      ).format(widget.evaluation[index].date),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttitudeIsGood() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conformes aux exigences',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: ItemizedText(
              widget.evaluation[_currentEvaluationIndex].attitude
                  .meetsRequirements,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttitudeIsBad() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À améliorer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: ItemizedText(
              widget.evaluation[_currentEvaluationIndex].attitude
                  .doesNotMeetRequirements,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralAppreciation() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appréciation générale',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              attitude
                  .GeneralAppreciation
                  .values[widget.evaluation[_currentEvaluationIndex].attitude
                      .generalAppreciation.index]
                  .name,
            ),
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
              widget.evaluation[_currentEvaluationIndex].comments.isEmpty
                  ? 'Aucun commentaire'
                  : widget.evaluation[_currentEvaluationIndex].comments,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowOtherForms() {
    final controller = AttitudeEvaluationFormController.fromInternshipId(
      context,
      internshipId: widget.internship.id,
      evaluationIndex: _currentEvaluationIndex,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () => showAttitudeEvaluationDialog(
                context: context,
                formController: controller,
                editMode: false,
              ),
              child: const Text('Voir l\'évaluation détaillée'),
            ),
            SizedBox(width: 12),
            IconButton(
                onPressed: () {
                  showPdfDialog(
                    context,
                    pdfGeneratorCallback: (context, format) =>
                        generateAttitudeEvaluationPdf(context, format,
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
    final teacherId =
        TeachersProvider.of(context, listen: false).currentTeacher?.id;
    _resetIndex();

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (ctx, isExpanded) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Text(
            'C2. Attitudes et comportements',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Visibility(
            visible: widget.internship.supervisingTeacherIds.contains(
              teacherId,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(18)),
              ),
              child: IconButton(
                onPressed: () => showAttitudeEvaluationDialog(
                  context: context,
                  formController: AttitudeEvaluationFormController(
                    internshipId: widget.internship.id,
                  ),
                  editMode: true,
                ),
                icon: const Icon(Icons.playlist_add_sharp),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.evaluation.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Text('Aucune évaluation disponible pour ce stage.'),
            ),
          if (widget.evaluation.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLastEvaluation(),
                _buildAttitudeIsGood(),
                _buildAttitudeIsBad(),
                _buildGeneralAppreciation(),
                _buildComment(),
                _buildShowOtherForms(),
              ],
            ),
        ],
      ),
    );
  }
}

class EvaluationSst extends StatelessWidget {
  const EvaluationSst({required this.internship});

  final Internship internship;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building _SstBody for job: ${internship.id}');

    final teacherId =
        TeachersProvider.of(context, listen: false).currentTeacher?.id;
    final isFilled = internship.sstEvaluation != null;

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (ctx, isExpanded) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Text(
            'SST en entreprise',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Visibility(
            visible: internship.supervisingTeacherIds.contains(
              teacherId,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(18)),
              ),
              child: IconButton(
                onPressed: () => showSstEvaluationFormDialog(context,
                    internshipId: internship.id),
                icon: const Icon(Icons.health_and_safety_outlined),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        ],
      ),
      child: SizedBox(
        width: Size.infinite.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isFilled
                  ? 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» a '
                      'été rempli pour ce poste de travail.\n'
                      'Dernière modification le '
                      '${DateFormat.yMMMEd('fr_CA').format(internship.sstEvaluation!.date)}'
                  : 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» n\'a '
                      'jamais été rempli pour ce poste de travail.'),
              const SizedBox(height: 12),
              _buildAnswers(context),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswers(BuildContext context) {
    final enterprise =
        EnterprisesProvider.of(context).fromId(internship.enterpriseId);
    final job = enterprise.jobs.fromId(internship.jobId);

    final questionIds = [...job.specialization.questions.map((e) => e)];
    final questions =
        questionIds.map((e) => QuestionFileService.fromId(e)).toList();
    questions.sort((a, b) => int.parse(a.idSummary) - int.parse(b.idSummary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.map((q) {
        final answer = internship.sstEvaluation?.questions['Q${q.id}'];
        final answerT = internship.sstEvaluation?.questions['Q${q.id}+t'];
        if ((q.questionSummary == null && q.followUpQuestionSummary == null) ||
            (answer == null && answerT == null)) {
          return Container();
        }

        late Widget question;
        late Widget answerWidget;
        if (q.followUpQuestionSummary == null) {
          question = Text(
            q.questionSummary!,
            style: Theme.of(context).textTheme.titleSmall,
          );

          switch (q.type) {
            case QuestionType.radio:
              answerWidget = Text(
                answer!.first,
                style: Theme.of(context).textTheme.bodyMedium,
              );
              break;
            case QuestionType.checkbox:
              if (answer!.isEmpty ||
                  answer[0] == '__NOT_APPLICABLE_INTERNAL__') {
                return Container();
              }
              answerWidget = ItemizedText(answer);
              break;
            case QuestionType.text:
              answerWidget = Text(answer!.first);
              break;
          }
        } else {
          if (q.type == QuestionType.checkbox || q.type == QuestionType.text) {
            throw 'Showing follow up question for Checkbox or Text '
                'is not implemented yet';
          }

          if (answer!.first == q.choices!.last) {
            // No follow up question was needed
            return Container();
          }

          question = question = Text(
            q.followUpQuestionSummary!,
            style: Theme.of(context).textTheme.titleSmall,
          );
          answerWidget = Text(
            answerT?.first ?? 'Aucune réponse fournie',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            question,
            answerWidget,
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}

class _PostInternshipEnterpriseBody extends StatelessWidget {
  const _PostInternshipEnterpriseBody({required this.internship});

  final Internship internship;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building EvaluationSst for job: ${internship.id}');

    final internship = InternshipsProvider.of(
      context,
    ).fromId(widget.internshipId);

    final enterprises = EnterprisesProvider.of(context);
    late final Job job;
    try {
      job = enterprises[internship.enterpriseId].jobs[internship.jobId];
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

    final teacherId =
        TeachersProvider.of(context, listen: false).currentTeacher?.id;
    final evaluation = internship.enterpriseEvaluation;
    final isFilled = evaluation != null;

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (ctx, isExpanded) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Text(
            'Évaluation de l\'entreprise',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Visibility(
            visible: internship.supervisingTeacherIds.contains(
              teacherId,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(18)),
              ),
              child: IconButton(
                onPressed: () => showEnterpriseEvaluationDialog(context,
                    internshipId: internship.id),
                icon: const Icon(Icons.factory_outlined),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        ],
      ),
      child: SizedBox(
        width: Size.infinite.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isFilled
                  ? 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» a '
                      'été rempli pour ce poste de travail.\n'
                      'Dernière modification le '
                      '${DateFormat.yMMMEd('fr_CA').format(internship.enterpriseEvaluation!.date)}'
                  : 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» n\'a '
                      'jamais été rempli pour ce poste de travail.'),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisaBody extends StatefulWidget {
  const _VisaBody({required this.internship, required this.evaluations});

  final Internship internship;
  final List<visa.InternshipEvaluationVisa> evaluations;

  @override
  State<_VisaBody> createState() => _VisaBodyState();
}

class _VisaBodyState extends State<_VisaBody> {
  static const _interline = 12.0;
  int _currentEvaluationIndex = -1;
  int _nbPreviousEvaluations = -1;

  void _resetIndex() {
    if (_nbPreviousEvaluations != widget.evaluations.length) {
      _currentEvaluationIndex = widget.evaluations.length - 1;
      _nbPreviousEvaluations = widget.evaluations.length;
    }
  }

  Widget _buildLastEvaluation() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Row(
        children: [
          const Text('Évaluation du\u00a0: '),
          DropdownButton<int>(
            value: _currentEvaluationIndex,
            onChanged: (value) =>
                setState(() => _currentEvaluationIndex = value!),
            items: widget.evaluations
                .asMap()
                .keys
                .map(
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(
                      DateFormat(
                        'dd MMMM yyyy',
                        'fr_CA',
                      ).format(widget.evaluations[index].date),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttitudeIsGood() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conformes aux exigences',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: ItemizedText(
              widget
                  .evaluations[_currentEvaluationIndex].form.meetsRequirements,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttitudeIsBad() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À améliorer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: ItemizedText(
              widget.evaluations[_currentEvaluationIndex].form
                  .doesNotMeetRequirements,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralAppreciation() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appréciation générale',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              visa
                  .GeneralAppreciation
                  .values[widget.evaluations[_currentEvaluationIndex].form
                      .generalAppreciation.index]
                  .name,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowOtherForms() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Center(
        child: OutlinedButton(
          onPressed: () => showVisaEvaluationDialog(
            context: context,
            formController: VisaEvaluationFormController.fromInternshipId(
              context,
              internshipId: widget.internship.id,
              evaluationIndex: _currentEvaluationIndex,
            ),
            editMode: false,
          ),
          child: const Text('Voir l\'évaluation détaillée'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherId =
        TeachersProvider.of(context, listen: false).currentTeacher?.id;
    _resetIndex();

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (ctx, isExpanded) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Text('VISA', style: TextStyle(fontWeight: FontWeight.bold)),
          Visibility(
            visible: widget.internship.supervisingTeacherIds.contains(
              teacherId,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(18)),
              ),
              child: IconButton(
                onPressed: () => showVisaEvaluationDialog(
                  context: context,
                  formController: VisaEvaluationFormController(
                    internshipId: widget.internship.id,
                  ),
                  editMode: true,
                ),
                icon: const Icon(Icons.post_add),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.evaluations.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Text('Aucune évaluation disponible pour ce stage.'),
            ),
          if (widget.evaluations.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLastEvaluation(),
                _buildAttitudeIsGood(),
                _buildAttitudeIsBad(),
                _buildGeneralAppreciation(),
                _buildShowOtherForms(),
              ],
            ),
        ],
      ),
    );
  }
}
