import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/screens/internship_forms/student_steps/attitude_evaluation_form_controller.dart';
import 'package:stagess/screens/internship_forms/student_steps/attitude_evaluation_screen.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_form_controller.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_form_screen.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_main_screen.dart';
import 'package:stagess/screens/internship_forms/student_steps/visa_evaluation_form_controller.dart';
import 'package:stagess/screens/internship_forms/student_steps/visa_evaluation_screen.dart';
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

final _logger = Logger('InternshipSkills');

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
    _logger.finer(
      'Building InternshipSkills for internship: ${widget.internshipId}',
    );

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

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: ExpansionPanelList(
        elevation: 0,
        expansionCallback:
            (index, isExpanded) => setState(() => _isExpanded = !_isExpanded),
        children: [
          ExpansionPanel(
            isExpanded: _isExpanded,
            canTapOnHeader: true,
            headerBuilder:
                (context, isExpanded) => Text(
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
                _VisaBody(
                  internship: internship,
                  evaluation: internship.visaEvaluations,
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
            onChanged:
                (value) => setState(() => _currentEvaluationIndex = value!),
            items:
                widget.evaluation
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
                      widget
                          .evaluation[_currentEvaluationIndex]
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
                skills:
                    widget.evaluation[_currentEvaluationIndex].skills
                        .where(
                          (e) =>
                              e.specializationId == specialization.id &&
                              e.appreciation == SkillAppreciation.acquired,
                        )
                        .toList(),
              ),
              _buildSkill(
                title: 'Compétences à poursuivre',
                skills:
                    widget.evaluation[_currentEvaluationIndex].skills
                        .where(
                          (e) =>
                              e.specializationId == specialization.id &&
                              e.appreciation == SkillAppreciation.toPursuit,
                        )
                        .toList(),
              ),
              _buildSkill(
                title: 'Compétences non réussies',
                skills:
                    widget.evaluation[_currentEvaluationIndex].skills
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Center(
        child: OutlinedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => Dialog(
                    child: SkillEvaluationFormScreen(
                      rootContext: context,
                      formController:
                          SkillEvaluationFormController.fromInternshipId(
                            context,
                            internshipId: widget.internship.id,
                            evaluationIndex: _currentEvaluationIndex,
                            canModify: false,
                          ),
                      editMode: false,
                    ),
                  ),
            );
          },
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

    late final Specialization specialization;
    try {
      specialization =
          EnterprisesProvider.of(context)
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
      header:
          (ctx, isExpanded) => Row(
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
                    onPressed:
                        () => showSkillEvaluationDialog(
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
            onChanged:
                (value) => setState(() => _currentEvaluationIndex = value!),
            items:
                widget.evaluation
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
              widget
                  .evaluation[_currentEvaluationIndex]
                  .attitude
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
              widget
                  .evaluation[_currentEvaluationIndex]
                  .attitude
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
                  .values[widget
                      .evaluation[_currentEvaluationIndex]
                      .attitude
                      .generalAppreciation
                      .index]
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
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Center(
        child: OutlinedButton(
          onPressed:
              () => showAttitudeEvaluationDialog(
                context: context,
                formController:
                    AttitudeEvaluationFormController.fromInternshipId(
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
      header:
          (ctx, isExpanded) => Row(
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
                    onPressed:
                        () => showAttitudeEvaluationDialog(
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

class _VisaBody extends StatefulWidget {
  const _VisaBody({required this.internship, required this.evaluation});

  final Internship internship;
  final List<visa.InternshipEvaluationVisa> evaluation;

  @override
  State<_VisaBody> createState() => _VisaBodyState();
}

class _VisaBodyState extends State<_VisaBody> {
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
            onChanged:
                (value) => setState(() => _currentEvaluationIndex = value!),
            items:
                widget.evaluation
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
              widget
                  .evaluation[_currentEvaluationIndex]
                  .attitude
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
              widget
                  .evaluation[_currentEvaluationIndex]
                  .attitude
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
                  .values[widget
                      .evaluation[_currentEvaluationIndex]
                      .attitude
                      .generalAppreciation
                      .index]
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
          onPressed:
              () => showVisaEvaluationDialog(
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
      header:
          (ctx, isExpanded) => Row(
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
                    onPressed:
                        () => showVisaEvaluationDialog(
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
                _buildShowOtherForms(),
              ],
            ),
        ],
      ),
    );
  }
}
