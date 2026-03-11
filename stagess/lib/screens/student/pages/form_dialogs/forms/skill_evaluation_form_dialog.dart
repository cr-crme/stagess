import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/scrollable_stepper.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/internships/task_appreciation.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';
import 'package:stagess_common_flutter/widgets/radio_with_follow_up.dart';

final _logger = Logger('SkillEvaluationDialog');

Future<Internship?> showSkillEvaluationFormDialog(
  BuildContext context, {
  required String internshipId,
  String? evaluationId,
}) async {
  final newEvaluation = await showDialog<InternshipEvaluationSkill?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (ctx) => Dialog(
          child: _SkillEvaluationMainScreen(
            rootContext: context,
            internshipId: internshipId,
            evaluationId: evaluationId,
          ),
        ),
      ),
    ),
  );
  if (newEvaluation == null || !context.mounted) return null;

  final internship =
      InternshipsProvider.of(context, listen: false).fromId(internshipId);
  return Internship.fromSerialized(internship.serialize())
    ..skillEvaluations.add(newEvaluation);
}

class SkillEvaluationFormController {
  static const _formVersion = '1.0.0';

  SkillEvaluationFormController(
    BuildContext context, {
    required this.internshipId,
    required this.canModify,
  }) {
    clearForm(context);
  }
  String? _previousEvaluationId; // -1 is the last, null is not from evaluation
  bool get isFilledUsingPreviousEvaluation => _previousEvaluationId != null;

  final bool canModify;
  SkillEvaluationGranularity evaluationGranularity =
      SkillEvaluationGranularity.global;

  final String internshipId;
  Internship internship(BuildContext context, {bool listen = true}) =>
      InternshipsProvider.of(context, listen: listen)[internshipId];

  final Map<String, Skill> _idToSkill = {};

  factory SkillEvaluationFormController.fromInternshipId(
    BuildContext context, {
    required String internshipId,
    required String evaluationId,
    required bool canModify,
  }) {
    final controller = SkillEvaluationFormController(
      context,
      internshipId: internshipId,
      canModify: canModify,
    );
    controller.fillFromPreviousEvaluation(context, evaluationId);
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

  void removeSkill(BuildContext context, String skillId) {
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

  void clearForm(BuildContext context) {
    _resetForm(context);

    final internshipTp = internship(context, listen: false);
    final enterprise = EnterprisesProvider.of(context,
        listen: false)[internshipTp.enterpriseId];
    final specialization =
        enterprise.jobs[internshipTp.currentContract?.jobId].specialization;

    for (final skill in specialization.skills) {
      addSkill(skill.id);
    }
  }

  InternshipEvaluationSkill? _previousEvaluation(BuildContext context) {
    if (!isFilledUsingPreviousEvaluation) return null;

    final internshipTp = internship(context, listen: false);
    if (internshipTp.skillEvaluations.isEmpty) return null;

    return internshipTp.skillEvaluations
            .firstWhereOrNull((e) => e.id == _previousEvaluationId) ??
        internshipTp.skillEvaluations.last;
  }

  void fillFromPreviousEvaluation(
      BuildContext context, String previousEvaluationId) {
    // Reset the form to fresh
    _resetForm(context);
    _previousEvaluationId = previousEvaluationId;

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
        taskCompleted[skillId]![task.title] = skillEvaluation.tasks
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
      final List<TaskAppreciation> tasks = taskCompleted[skillId]!
          .keys
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

  void _initializeSkills(BuildContext context) {
    _idToSkill.clear();

    final internshipTp = internship(context, listen: false);
    final enterprise = EnterprisesProvider.of(context,
        listen: false)[internshipTp.enterpriseId];

    final specialization =
        enterprise.jobs[internshipTp.currentContract?.jobId].specialization;
    for (final skill in specialization.skills) {
      _idToSkill[skill.id] = skill;
      _evaluatedSkills[skill.id] = 0;
      _skillsAreFromSpecializationId[skill.id] = specialization.id;
    }

    for (final extraSpecializationId
        in (internshipTp.currentContract?.extraSpecializationIds ?? [])) {
      for (final skill in ActivitySectorsService.specialization(
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

  void _resetForm(BuildContext context) {
    evaluationDate = DateTime.now();
    _previousEvaluationId = null;
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

class _SkillEvaluationMainScreen extends StatefulWidget {
  const _SkillEvaluationMainScreen({
    required this.rootContext,
    required this.internshipId,
    this.evaluationId,
  });

  final BuildContext rootContext;
  final String internshipId;
  final String? evaluationId;

  @override
  State<_SkillEvaluationMainScreen> createState() =>
      _SkillEvaluationMainScreenState();
}

class _SkillEvaluationMainScreenState
    extends State<_SkillEvaluationMainScreen> {
  bool get _editMode => widget.evaluationId == null;

  late final _formController = _editMode
      ? SkillEvaluationFormController(
          context,
          internshipId: widget.internshipId,
          canModify: true,
        )
      : SkillEvaluationFormController.fromInternshipId(
          context,
          internshipId: widget.internshipId,
          evaluationId: widget.evaluationId!,
          canModify: false,
        );
  late String? _currentEvaluationId = _editMode
      ? (_formController
              .internship(context, listen: false)
              .skillEvaluations
              .isEmpty
          ? null
          : _formController
              .internship(context, listen: false)
              .skillEvaluations
              .last
              .id)
      : widget.evaluationId!;

  @override
  void initState() {
    super.initState();

    if (_currentEvaluationId != null) {
      _formController.fillFromPreviousEvaluation(
          context, _currentEvaluationId!);
    }
  }

  void _cancel() async {
    _logger.info('User requested to cancel the skill evaluation dialog');

    final answer = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
      isEditing: _editMode,
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
          child: student == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Builder(
                          builder: (context) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _EvaluationDate(
                                  formController: _formController,
                                  editMode: _editMode,
                                ),
                                _PersonAtMeeting(
                                  formController: _formController,
                                  editMode: _editMode,
                                ),
                                if (_editMode) _buildAutofillChooser(),
                                _JobToEvaluate(
                                  formController: _formController,
                                  editMode: _editMode,
                                ),
                                _EvaluationTypeChoser(
                                  formController: _formController,
                                  editMode: _editMode,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    _StartEvaluation(
                      rootContext: widget.rootContext,
                      formController: _formController,
                      editMode: _editMode,
                    ),
                  ],
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
              const SubTitle('Options d\'évaluation'),
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  children: [
                    const Text('Recommencer à partir de\u00a0: '),
                    DropdownButton<String?>(
                      value: _currentEvaluationId,
                      onChanged: (value) {
                        _currentEvaluationId = evaluations
                            .firstWhereOrNull((e) => e.id == value)
                            ?.id;
                        value == null || value == 'Nouveau formulaire vide'
                            ? _formController.clearForm(context)
                            : _formController.fillFromPreviousEvaluation(
                                context,
                                _currentEvaluationId!,
                              );
                        setState(() {});
                      },
                      items: evaluations
                          .map(
                            (evaluation) => DropdownMenuItem(
                              value: evaluation.id,
                              child: Text(
                                'Évaluation du ${DateFormat(
                                  'dd MMMM yyyy',
                                  'fr_CA',
                                ).format(evaluation.date)}',
                              ),
                            ),
                          )
                          .toList()
                        ..add(
                          DropdownMenuItem(
                              value: null,
                              child: const Text('Nouveau formulaire vide')),
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
  void _promptDate(BuildContext context) async {
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
            controller: formController.wereAtMeetingController,
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
  late final _controller =
      RadioWithFollowUpController<SkillEvaluationGranularity>(
    initialValue: widget.formController.evaluationGranularity,
  );

  @override
  void didUpdateWidget(covariant _EvaluationTypeChoser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editMode) return;

    if (_controller.value != widget.formController.evaluationGranularity) {
      _controller.forceSet(widget.formController.evaluationGranularity);
    }
  }

  @override
  Widget build(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Type d\'évaluation'),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: RadioWithFollowUp<SkillEvaluationGranularity>(
            controller: _controller,
            elements: SkillEvaluationGranularity.values,
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
    return enterprise.jobs[internship.currentContract?.jobId].specialization;
  }

  List<Specialization> get extraSpecializations {
    final internship = widget.formController.internship(context, listen: false);
    return (internship.currentContract?.extraSpecializationIds ?? [])
        .map(
          (specializationId) =>
              ActivitySectorsService.specialization(specializationId),
        )
        .toList();
  }

  void _showHelpOnJobSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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
                      enabled: widget.editMode &&
                          (isMainSpecialization ||
                              !duplicatedSkills[skill.id]!),
                    );
                    return out;
                  }),
                ],
              ),
              if (widget.editMode &&
                  widget.formController.isFilledUsingPreviousEvaluation)
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
    final mainSkills = enterprise
        .jobs[internship.currentContract?.jobId].specialization.skills;

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
                builder: (context) => Dialog(
                  child: _SkillEvaluationFormScreen(
                    rootContext: rootContext,
                    formController: formController,
                    editMode: editMode,
                  ),
                ),
              ),
            );
          },
          child:
              Text(editMode ? 'Commencer l\'évaluation' : 'Voir l\'évaluation'),
        ),
      ),
    );
  }
}

class _SkillEvaluationFormScreen extends StatefulWidget {
  const _SkillEvaluationFormScreen({
    required this.rootContext,
    required this.formController,
    required this.editMode,
  });

  final BuildContext rootContext;
  final SkillEvaluationFormController formController;
  final bool editMode;

  @override
  State<_SkillEvaluationFormScreen> createState() =>
      _SkillEvaluationFormScreenState();
}

class _SkillEvaluationFormScreenState
    extends State<_SkillEvaluationFormScreen> {
  final _scrollController = ScrollController();
  final double _tabHeight = 74.0;
  int _currentStep = 0;

  // This is to ensure the frame that call build after everything is disposed
  // does not block the app
  bool _isDisposed = false;

  SkillList _extractSkills(
    BuildContext context, {
    required Internship internship,
  }) {
    final out = SkillList.empty();
    for (final skill in widget.formController.skillResults(activeOnly: true)) {
      out.add(skill);
    }
    return out;
  }

  void _nextStep() {
    _logger.finer('Moving to next step: $_currentStep');

    _currentStep++;
    _scrollToCurrentTab();
    setState(() {});
  }

  void _previousStep() {
    _logger.finer('Moving to previous step: $_currentStep');

    _currentStep--;
    _scrollToCurrentTab();
    setState(() {});
  }

  void _cancel() async {
    _logger.info('User requested to cancel the evaluation form');

    final answer = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
      isEditing: widget.editMode,
    );
    if (!mounted || !answer) return;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.formController.dispose();
    });

    _logger.fine('User confirmed cancellation, disposing form controller');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(null);
  }

  void _submit() async {
    _logger.info('Submitting skill evaluation form');
    // Confirm the user is really ready to submit

    if (!widget.formController.allAppreciationsAreDone) {
      final result = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Soumettre l\'évaluation?'),
          content: const Text(
            '**Attention, toutes les compétences n\'ont pas été évaluées**',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Oui'),
            ),
          ],
        ),
      );
      if (result == null || !result) return;
    }
    if (!mounted) return;

    // Fetch the data from the form controller
    final newEvaluation = widget.formController.toInternshipEvaluation();
    _isDisposed = true;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.formController.dispose();
    });

    _logger.fine('Skill evaluation form submitted successfully');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(newEvaluation);
  }

  Widget _controlBuilder(
    BuildContext context,
    ControlsDetails details,
    SkillList skills,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Expanded(child: SizedBox()),
              if (_currentStep != 0)
                OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Précédent'),
                ),
              const SizedBox(width: 20),
              if (_currentStep != skills.length)
                TextButton(
                  onPressed: details.onStepContinue,
                  child: const Text('Suivant'),
                ),
              if (_currentStep == skills.length && widget.editMode)
                TextButton(onPressed: _submit, child: const Text('Soumettre')),
            ],
          ),
        ],
      ),
    );
  }

  void _scrollToCurrentTab() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Wait until the stepper has closed and reopened before moving
      _scrollController.jumpTo(_currentStep * _tabHeight);
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building SkillEvaluationFormScreen for internship: ${widget.formController.internshipId} '
      'and editMode: ${widget.editMode}',
    );
    if (_isDisposed) return Container();

    final internship = widget.formController.internship(context);
    final skills = _extractSkills(context, internship: internship);

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
          child: student == null
              ? const Center(child: CircularProgressIndicator())
              : ScrollableStepper(
                  scrollController: _scrollController,
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onTapContinue: _nextStep,
                  onStepTapped: (int tapped) => setState(() {
                    _currentStep = tapped;
                    _scrollToCurrentTab();
                  }),
                  onTapCancel: _cancel,
                  steps: [
                    ...skills.map(
                      (skill) => Step(
                        isActive: true,
                        state: widget.formController.appreciations[skill.id] ==
                                SkillAppreciation.notSelected
                            ? StepState.indexed
                            : StepState.complete,
                        title: SubTitle(
                          '${skill.id}${skill.isOptional ? ' (Facultative)' : ''}',
                          top: 0,
                          bottom: 0,
                        ),
                        content: _EvaluateSkill(
                          formController: widget.formController,
                          skill: skill,
                          editMode: widget.editMode,
                        ),
                      ),
                    ),
                    Step(
                      isActive: true,
                      title: const SubTitle(
                        'Commentaires',
                        top: 0,
                        bottom: 0,
                      ),
                      content: _Comments(
                        formController: widget.formController,
                        editMode: widget.editMode,
                      ),
                    ),
                  ],
                  controlsBuilder:
                      (BuildContext context, ControlsDetails details) =>
                          _controlBuilder(context, details, skills),
                ),
        ),
      ),
    );
  }
}

class _EvaluateSkill extends StatelessWidget {
  const _EvaluateSkill({
    required this.formController,
    required this.skill,
    required this.editMode,
  });

  final SkillEvaluationFormController formController;
  final Skill skill;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SubTitle(skill.name, top: 0, left: 0),
        Padding(
          padding: const EdgeInsets.only(bottom: spacing),
          child: Text(
            'Niveau\u00a0: ${skill.complexity}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Critères de performance:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...skill.criteria.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '\u00b7 ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Flexible(child: Text(e)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        formController.evaluationGranularity ==
                SkillEvaluationGranularity.global
            ? _TaskEvaluation(
                spacing: spacing,
                skill: skill,
                formController: formController,
                editMode: editMode,
              )
            : _TaskEvaluationDetailed(
                spacing: spacing,
                skill: skill,
                formController: formController,
                editMode: editMode,
              ),
        TextFormField(
          decoration: const InputDecoration(label: Text('Commentaires')),
          controller: formController.skillCommentsControllers[skill.id]!,
          maxLines: null,
          enabled: editMode,
        ),
        const SizedBox(height: 24),
        _AppreciationEvaluation(
          spacing: spacing,
          skill: skill,
          formController: formController,
          editMode: editMode,
        ),
      ],
    );
  }
}

class _TaskEvaluation extends StatefulWidget {
  const _TaskEvaluation({
    required this.spacing,
    required this.skill,
    required this.formController,
    required this.editMode,
  });

  final double spacing;
  final Skill skill;
  final SkillEvaluationFormController formController;
  final bool editMode;

  @override
  State<_TaskEvaluation> createState() => _TaskEvaluationState();
}

class _TaskEvaluationState extends State<_TaskEvaluation> {
  late final _checkboxController = CheckboxWithOtherController(
    elements: widget.skill.tasks,
    initialValues: widget.formController.taskCompleted[widget.skill.id]!.keys
        .where(
          (e) =>
              widget.formController.taskCompleted[widget.skill.id]![e]! !=
              TaskAppreciationLevel.notEvaluated,
        )
        .toList(),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.spacing),
      child: CheckboxWithOther(
        key: ValueKey('checkbox_${widget.skill.id}'),
        controller: _checkboxController,
        title: 'L\'élève a réussi les tâches suivantes\u00a0:',
        onOptionSelected: (values) {
          for (final task
              in widget.formController.taskCompleted[widget.skill.id]!.keys) {
            widget.formController.taskCompleted[widget.skill.id]![task] =
                values.contains(task)
                    ? TaskAppreciationLevel.evaluated
                    : TaskAppreciationLevel.notEvaluated;
          }
        },
        enabled: widget.editMode,
        showOtherOption: false,
      ),
    );
  }
}

class _TaskEvaluationDetailed extends StatelessWidget {
  const _TaskEvaluationDetailed({
    required this.spacing,
    required this.skill,
    required this.formController,
    required this.editMode,
  });

  final double spacing;
  final Skill skill;
  final SkillEvaluationFormController formController;
  final bool editMode;

  void _showHelpOnTask(BuildContext context) {
    List<String> texts = [];
    for (final task in byTaskAppreciationLevel) {
      texts.add('${task.abbreviation()}: $task\n');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Explication des boutons'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: texts.map((e) => Text(e)).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Tâche\u00a0:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(
                height: 45,
                width: 45,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => _showHelpOnTask(context),
                  child: Icon(
                    Icons.info,
                    size: 30,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          ...formController.taskCompleted[skill.id]!.keys.map(
            (task) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _TaskAppreciationSelection(
                formController: formController,
                skillId: skill.id,
                task: task,
                enabled: editMode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskAppreciationSelection extends StatefulWidget {
  const _TaskAppreciationSelection({
    required this.formController,
    required this.skillId,
    required this.task,
    required this.enabled,
  });

  final String skillId;
  final SkillEvaluationFormController formController;
  final String task;
  final bool enabled;

  @override
  State<_TaskAppreciationSelection> createState() =>
      _TaskAppreciationSelectionState();
}

class _TaskAppreciationSelectionState
    extends State<_TaskAppreciationSelection> {
  late TaskAppreciationLevel _current =
      widget.formController.taskCompleted[widget.skillId]![widget.task]!;

  void _select(TaskAppreciationLevel? value) {
    if (value == null) return;
    _current = value;
    widget.formController.taskCompleted[widget.skillId]![widget.task] = value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.task),
        RadioGroup(
          groupValue: _current,
          onChanged: _select,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: byTaskAppreciationLevel
                .map(
                  (e) => InkWell(
                    onTap: widget.enabled ? () => _select(e) : null,
                    child: Row(
                      children: [
                        Radio(
                          enabled: widget.enabled,
                          fillColor: WidgetStateColor.resolveWith((state) {
                            return widget.enabled
                                ? Theme.of(context).primaryColor
                                : Colors.grey;
                          }),
                          value: e,
                        ),
                        Text(e.abbreviation()),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _AppreciationEvaluation extends StatefulWidget {
  const _AppreciationEvaluation({
    required this.spacing,
    required this.skill,
    required this.formController,
    required this.editMode,
  });

  final double spacing;
  final Skill skill;
  final SkillEvaluationFormController formController;
  final bool editMode;

  @override
  State<_AppreciationEvaluation> createState() =>
      _AppreciationEvaluationState();
}

class _AppreciationEvaluationState extends State<_AppreciationEvaluation> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.spacing),
      child: RadioGroup(
        groupValue: widget.formController.appreciations[widget.skill.id],
        onChanged: (value) => setState(
          () => widget.formController.appreciations[widget.skill.id] = value!,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Appréciation générale de la compétence\u00a0:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...SkillAppreciation.values
                .where((e) => e != SkillAppreciation.notSelected)
                .map(
                  (e) => RadioListTile<SkillAppreciation>(
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    enabled: widget.editMode,
                    value: e,
                    fillColor: WidgetStateColor.resolveWith((state) {
                      return widget.editMode
                          ? Theme.of(context).primaryColor
                          : Colors.grey;
                    }),
                    title: Text(
                      e.name,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(color: Colors.black),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Comments extends StatelessWidget {
  const _Comments({required this.formController, required this.editMode});

  final SkillEvaluationFormController formController;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: Text(
            'Ajouter des commentaires sur le stage',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        TextFormField(
          controller: formController.commentsController,
          enabled: editMode,
          maxLines: null,
        ),
      ],
    );
  }
}
