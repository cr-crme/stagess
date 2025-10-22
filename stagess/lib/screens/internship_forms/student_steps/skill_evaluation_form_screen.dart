import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/scrollable_stepper.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_form_controller.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/internships/task_appreciation.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';

final _logger = Logger('SkillEvaluationFormScreen');

class SkillEvaluationFormScreen extends StatefulWidget {
  const SkillEvaluationFormScreen({
    super.key,
    required this.rootContext,
    required this.formController,
    required this.editMode,
  });

  static const route = '/skill_evaluation_form';

  final BuildContext rootContext;
  final SkillEvaluationFormController formController;
  final bool editMode;

  @override
  State<SkillEvaluationFormScreen> createState() =>
      _SkillEvaluationFormScreenState();
}

class _SkillEvaluationFormScreenState extends State<SkillEvaluationFormScreen> {
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
        builder:
            (context) => AlertDialog(
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
    final internship = widget.formController.internship(context, listen: false);
    internship.skillEvaluations.add(
      widget.formController.toInternshipEvaluation(),
    );

    _isDisposed = true;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.formController.dispose();
    });

    _logger.fine('Skill evaluation form submitted successfully');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(internship);
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
          child:
              student == null
                  ? const Center(child: CircularProgressIndicator())
                  : ScrollableStepper(
                    scrollController: _scrollController,
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onTapContinue: _nextStep,
                    onStepTapped:
                        (int tapped) => setState(() {
                          _currentStep = tapped;
                          _scrollToCurrentTab();
                        }),
                    onTapCancel: _cancel,
                    steps: [
                      ...skills.map(
                        (skill) => Step(
                          isActive: true,
                          state:
                              widget.formController.appreciations[skill.id] ==
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
    initialValues:
        widget.formController.taskCompleted[widget.skill.id]!.keys
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

  void _showHelpOnTask(context) {
    List<String> texts = [];
    for (final task in byTaskAppreciationLevel) {
      texts.add('${task.abbreviation()}: $task\n');
    }

    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
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

  void _select(value) {
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
            children:
                byTaskAppreciationLevel
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
        onChanged:
            (value) => setState(
              () =>
                  widget.formController.appreciations[widget.skill.id] = value!,
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
