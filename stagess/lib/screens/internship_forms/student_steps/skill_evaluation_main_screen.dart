import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_form_controller.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_form_screen.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';
import 'package:stagess_common_flutter/widgets/radio_with_follow_up.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('SkillEvaluationDialog');

Future<Internship?> showSkillEvaluationDialog({
  required BuildContext context,
  required String internshipId,
  required bool editMode,
}) async {
  _logger.info('Showing SkillEvaluationDialog with editMode: $editMode');

  final internships = InternshipsProvider.of(context, listen: false);
  final internship = internships[internshipId];

  if (editMode) {
    final hasLock = await internships.getLockForItem(internship);
    if (!hasLock || !context.mounted) {
      if (context.mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de modifier ce stage, il est peut-être en cours de modification ailleurs.',
        );
      }
      return null;
    }
  }

  final editedInternship = await showDialog<Internship?>(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => Navigator(
          onGenerateRoute:
              (settings) => MaterialPageRoute(
                builder:
                    (ctx) => Dialog(
                      child: SkillEvaluationMainScreen(
                        rootContext: context,
                        internshipId: internshipId,
                        editMode: editMode,
                      ),
                    ),
              ),
        ),
  );
  if (!editMode) return editedInternship;

  if (editedInternship == null) {
    await internships.releaseLockForItem(internship);
    return editedInternship;
  }

  await internships.replaceWithConfirmation(editedInternship);
  if (context.mounted) {
    showSnackBar(context, message: 'Le stage a été mis à jour');
  }
  await internships.releaseLockForItem(internship);
  return editedInternship;
}

class SkillEvaluationMainScreen extends StatefulWidget {
  const SkillEvaluationMainScreen({
    super.key,
    required this.rootContext,
    required this.internshipId,
    required this.editMode,
  });

  static const route = '/skill_evaluation';

  final BuildContext rootContext;
  final String internshipId;
  final bool editMode;

  @override
  State<SkillEvaluationMainScreen> createState() =>
      _SkillEvaluationMainScreenState();
}

class _SkillEvaluationMainScreenState extends State<SkillEvaluationMainScreen> {
  late final _formController = SkillEvaluationFormController(
    context,
    internshipId: widget.internshipId,
    canModify: true,
  );
  late int _currentEvaluationIndex =
      _formController
          .internship(context, listen: false)
          .skillEvaluations
          .length -
      1;

  @override
  void initState() {
    super.initState();

    if (_currentEvaluationIndex >= 0) {
      _formController.fillFromPreviousEvaluation(
        context,
        _currentEvaluationIndex,
      );
    }
  }

  void _cancel() async {
    _logger.info('User requested to cancel the skill evaluation dialog');

    final answer = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
      isEditing: widget.editMode,
    );
    if (!mounted || !answer) return;

    _formController.dispose();
    _logger.fine('User confirmed cancellation, disposing form controller');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building SkillEvaluationMainScreen for internship: ${widget.internshipId}',
    );
    final internship = InternshipsProvider.of(context)[widget.internshipId];

    final student = StudentsHelpers.studentsInMyGroups(
      context,
    ).firstWhereOrNull((e) => e.id == internship.studentId);

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${student == null ? 'En attente des informations' : 'Évaluation de ${student.fullName}'}\n'
            'C1. Compétences spécifiques',
          ),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: PopScope(
          child:
              student == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    child: Builder(
                      builder: (context) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _EvaluationDate(
                              formController: _formController,
                              editMode: widget.editMode,
                            ),
                            _PersonAtMeeting(
                              formController: _formController,
                              editMode: widget.editMode,
                            ),
                            _buildAutofillChooser(),
                            _JobToEvaluate(
                              formController: _formController,
                              editMode: widget.editMode,
                            ),
                            _EvaluationTypeChoser(
                              formController: _formController,
                              editMode: widget.editMode,
                            ),
                            _StartEvaluation(
                              rootContext: widget.rootContext,
                              formController: _formController,
                              editMode: widget.editMode,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildAutofillChooser() {
    final evaluations =
        _formController.internship(context, listen: false).skillEvaluations;

    return evaluations.isEmpty
        ? Container()
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SubTitle('Options de remplissage'),
            Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: Column(
                children: [
                  const Text('Préremplir avec les résultats de\u00a0: '),
                  DropdownButton<int?>(
                    value: _currentEvaluationIndex,
                    onChanged: (value) {
                      _currentEvaluationIndex = value!;
                      _currentEvaluationIndex >= evaluations.length
                          ? _formController.clearForm(context)
                          : _formController.fillFromPreviousEvaluation(
                            context,
                            _currentEvaluationIndex,
                          );
                      setState(() {});
                    },
                    items:
                        evaluations
                            .asMap()
                            .keys
                            .map(
                              (index) => DropdownMenuItem(
                                value: index,
                                child: Text(
                                  DateFormat(
                                    'dd MMMM yyyy',
                                    'fr_CA',
                                  ).format(evaluations[index].date),
                                ),
                              ),
                            )
                            .toList()
                          ..add(
                            DropdownMenuItem(
                              value: evaluations.length,
                              child: const Text('Vide'),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
  }
}

class _EvaluationDate extends StatefulWidget {
  const _EvaluationDate({required this.formController, required this.editMode});

  final SkillEvaluationFormController formController;
  final bool editMode;
  @override
  State<_EvaluationDate> createState() => _EvaluationDateState();
}

class _EvaluationDateState extends State<_EvaluationDate> {
  void _promptDate(context) async {
    final newDate = await showCustomDatePicker(
      helpText: 'Sélectionner la date',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      context: context,
      initialDate: widget.formController.evaluationDate,
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (newDate == null) return;

    widget.formController.evaluationDate = newDate;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Date de l\'évaluation'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                DateFormat(
                  'dd MMMM yyyy',
                  'fr_CA',
                ).format(widget.formController.evaluationDate),
              ),
              if (widget.editMode)
                IconButton(
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.blue,
                  ),
                  onPressed: () => _promptDate(context),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonAtMeeting extends StatelessWidget {
  const _PersonAtMeeting({
    required this.formController,
    required this.editMode,
  });

  final SkillEvaluationFormController formController;
  final bool editMode;

  @override
  Widget build(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Personnes présentes lors de l\'évaluation'),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: CheckboxWithOther(
            key: formController.wereAtMeetingKey,
            elements: formController.wereAtMeetingOptions,
            initialValues: formController.wereAtMeeting,
            enabled: editMode,
          ),
        ),
      ],
    );
  }
}

class _EvaluationTypeChoser extends StatefulWidget {
  const _EvaluationTypeChoser({
    required this.formController,
    required this.editMode,
  });

  final SkillEvaluationFormController formController;
  final bool editMode;

  @override
  State<_EvaluationTypeChoser> createState() => _EvaluationTypeChoserState();
}

class _EvaluationTypeChoserState extends State<_EvaluationTypeChoser> {
  final _key = GlobalKey<RadioWithFollowUpState<SkillEvaluationGranularity>>();

  @override
  Widget build(context) {
    if (_key.currentState != null) {
      _key.currentState!.forceValue(
        widget.formController.evaluationGranularity,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Type d\'évaluation'),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: RadioWithFollowUp<SkillEvaluationGranularity>(
            key: _key,
            elements: SkillEvaluationGranularity.values,
            initialValue: widget.formController.evaluationGranularity,
            onChanged: (value) {
              widget.formController.evaluationGranularity = value!;
            },
            enabled: !widget.formController.isFilledUsingPreviousEvaluation,
          ),
        ),
      ],
    );
  }
}

class _JobToEvaluate extends StatefulWidget {
  const _JobToEvaluate({required this.formController, required this.editMode});

  final SkillEvaluationFormController formController;
  final bool editMode;

  @override
  State<_JobToEvaluate> createState() => _JobToEvaluateState();
}

class _JobToEvaluateState extends State<_JobToEvaluate> {
  Specialization get specialization {
    final internship = widget.formController.internship(context, listen: false);
    final enterprise =
        EnterprisesProvider.of(context, listen: false)[internship.enterpriseId];
    return enterprise.jobs[internship.jobId].specialization;
  }

  List<Specialization> get extraSpecializations {
    final internship = widget.formController.internship(context, listen: false);
    return internship.extraSpecializationIds
        .map(
          (specializationId) =>
              ActivitySectorsService.specialization(specializationId),
        )
        .toList();
  }

  void _showHelpOnJobSelection() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Explication des sélections'),
            content: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Sélectionner '),
                  WidgetSpan(
                    child: SizedBox(
                      height: 19,
                      width: 22,
                      child: Checkbox(
                        tristate: true,
                        value: null,
                        onChanged: null,
                        fillColor: WidgetStateProperty.resolveWith(
                          (states) => Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' pour masquer les compétences précédemment évaluées pour '
                        'cette évaluation-ci (les résultats sont conservés).',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildJobTile({
    required String title,
    required Specialization specialization,
    Map<String, bool>? duplicatedSkills,
  }) {
    final isMainSpecialization = duplicatedSkills == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubTitle(title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    specialization.idWithName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('* Compétences à évaluer :'),
                  ...specialization.skills.map((skill) {
                    final out = CheckboxListTile(
                      tristate: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      onChanged: (value) {
                        // Make sure false is only possible for non previously
                        // evaluated values and null is only possible for previously
                        // evaluted values
                        if (value == null &&
                            !widget.formController
                                .isNotEvaluatedButWasPreviously(skill.id)) {
                          // If it comes from true (so it is null now)
                          // Change it to false if it was not previously evaluated
                          value = false;
                        } else if (!value!) {
                          // If it comes from null, then it was previously evaluated
                          // and the user wants it to true
                          value = true;
                        }

                        if (value) {
                          widget.formController.addSkill(skill.id);
                        } else {
                          widget.formController.removeSkill(context, skill.id);
                        }
                        setState(() {});
                      },
                      value:
                          widget.formController.isNotEvaluatedButWasPreviously(
                                skill.id,
                              )
                              ? null
                              : widget.formController.isSkillToEvaluate(
                                skill.id,
                              ),
                      title: Text(
                        '${skill.idWithName}${skill.isOptional ? ' (Facultative)' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      enabled:
                          widget.editMode &&
                          (isMainSpecialization ||
                              !duplicatedSkills[skill.id]!),
                    );
                    return out;
                  }),
                ],
              ),
              if (widget.formController.isFilledUsingPreviousEvaluation)
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    height: 45,
                    width: 45,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: _showHelpOnJobSelection,
                      child: Icon(
                        Icons.info,
                        size: 30,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, bool> _setDuplicateFlag() {
    // Duplicate skills deals with common skills in different jobs. Only allows for
    // modification of the first occurence (and tie them)
    final Map<String, bool> usedDuplicateSkills = {};

    final internship = widget.formController.internship(context, listen: false);
    final enterprise =
        EnterprisesProvider.of(context, listen: false)[internship.enterpriseId];
    final mainSkills = enterprise.jobs[internship.jobId].specialization.skills;

    for (final extra in extraSpecializations) {
      for (final skill in extra.skills) {
        usedDuplicateSkills[skill.id] = mainSkills.any((e) => e.id == skill.id);
      }
    }

    return usedDuplicateSkills;
  }

  @override
  Widget build(BuildContext context) {
    final usedDuplicateSkills = _setDuplicateFlag();
    final extra = extraSpecializations;

    // If there is more than one job, the user must select which skills are evaluated
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildJobTile(
          title: 'Métier principal',
          specialization: specialization,
        ),
        ...extra.asMap().keys.map(
          (i) => _buildJobTile(
            title:
                'Métier supplémentaire${extra.length > 1 ? ' (${i + 1})' : ''}',
            specialization: extra[i],
            duplicatedSkills: usedDuplicateSkills,
          ),
        ),
      ],
    );
  }
}

class _StartEvaluation extends StatelessWidget {
  const _StartEvaluation({
    required this.rootContext,
    required this.formController,
    required this.editMode,
  });

  final BuildContext rootContext;
  final SkillEvaluationFormController formController;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 24, right: 24.0, bottom: 24),
        child: TextButton(
          onPressed: () {
            formController.setWereAtMeeting();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => Dialog(
                      child: SkillEvaluationFormScreen(
                        rootContext: rootContext,
                        formController: formController,
                        editMode: editMode,
                      ),
                    ),
              ),
            );
          },
          child: const Text('Commencer l\'évaluation'),
        ),
      ),
    );
  }
}
