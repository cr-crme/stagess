import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/scrollable_stepper.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/persons/student_visa.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';

final _logger = Logger('VisaFormDialog');

Future<Student?> showVisaEvaluationFormDialog({
  required BuildContext context,
  required VisaFormController formController,
  required bool editMode,
}) async {
  final newEvaluation = await showDialog<StudentVisa?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (ctx) => Dialog(
          child: _VisaEvaluationScreen(
            rootContext: context,
            formController: formController,
            editMode: editMode,
          ),
        ),
      ),
    ),
  );
  if (newEvaluation == null || !context.mounted) return null;

  final student = StudentsProvider.of(context, listen: false)
      .fromId(formController.studentId);

  // Erase the previous visa and replace it by the new one
  return Student.fromSerialized(student.serialize())
    ..allVisa.clear()
    ..allVisa.add(newEvaluation);
}

class VisaFormController {
  static const _formVersion = '1.0.0';

  VisaFormController({required this.studentId});

  final String studentId;
  Student student(BuildContext context, {bool listen = true}) =>
      StudentsProvider.of(context, listen: listen).fromId(studentId);

  factory VisaFormController.fromStudentId(
    BuildContext context, {
    required String studentId,
  }) {
    Student student =
        StudentsProvider.of(context, listen: false).fromId(studentId);

    // It is currently not possible to have more than one evaluation
    final evaluationIndex = 0;
    StudentVisa visaForm = student.allVisa[evaluationIndex];

    final controller = VisaFormController(studentId: studentId);

    controller.responses[Inattendance] = visaForm.form.inattendance;
    controller.responses[Ponctuality] = visaForm.form.ponctuality;
    controller.responses[Sociability] = visaForm.form.sociability;
    controller.responses[Politeness] = visaForm.form.politeness;
    controller.responses[Motivation] = visaForm.form.motivation;
    controller.responses[DressCode] = visaForm.form.dressCode;
    controller.responses[QualityOfWork] = visaForm.form.qualityOfWork;
    controller.responses[Productivity] = visaForm.form.productivity;
    controller.responses[Autonomy] = visaForm.form.autonomy;
    controller.responses[Cautiousness] = visaForm.form.cautiousness;
    controller.responses[GeneralAppreciation] =
        visaForm.form.generalAppreciation;

    return controller;
  }

  StudentVisa toVisa() {
    return StudentVisa(
      form: VisaEvaluation(
        inattendance: responses[Inattendance]! as Inattendance,
        ponctuality: responses[Ponctuality]! as Ponctuality,
        sociability: responses[Sociability]! as Sociability,
        politeness: responses[Politeness]! as Politeness,
        motivation: responses[Motivation]! as Motivation,
        dressCode: responses[DressCode]! as DressCode,
        qualityOfWork: responses[QualityOfWork]! as QualityOfWork,
        productivity: responses[Productivity]! as Productivity,
        autonomy: responses[Autonomy]! as Autonomy,
        cautiousness: responses[Cautiousness]! as Cautiousness,
        generalAppreciation:
            responses[GeneralAppreciation]! as GeneralAppreciation,
      ),
      formVersion: _formVersion,
    );
  }

  Map<Type, VisaCategoryEnum?> responses = {};

  bool get isAttitudeCompleted =>
      responses[Inattendance] != null &&
      responses[Ponctuality] != null &&
      responses[Sociability] != null &&
      responses[Politeness] != null &&
      responses[Motivation] != null &&
      responses[DressCode] != null;

  bool get isSkillCompleted =>
      responses[QualityOfWork] != null &&
      responses[Productivity] != null &&
      responses[Autonomy] != null &&
      responses[Cautiousness] != null;

  bool get isGeneralAppreciationCompleted =>
      responses[GeneralAppreciation] != null;

  bool get isCompleted =>
      isAttitudeCompleted && isSkillCompleted && isGeneralAppreciationCompleted;
}

class _VisaEvaluationScreen extends StatefulWidget {
  const _VisaEvaluationScreen({
    required this.rootContext,
    required this.formController,
    required this.editMode,
  });

  final BuildContext rootContext;
  final VisaFormController formController;
  final bool editMode;

  @override
  State<_VisaEvaluationScreen> createState() => _VisaEvaluationScreenState();
}

class _VisaEvaluationScreenState extends State<_VisaEvaluationScreen> {
  final _scrollController = ScrollController();

  int _currentStep = 0;
  final List<StepState> _stepStatus = [
    StepState.indexed,
    StepState.indexed,
    StepState.indexed,
    StepState.indexed,
  ];

  void _previousStep() {
    _logger.finer('Going back to previous step from step $_currentStep');

    if (_currentStep == 0) return;

    _currentStep -= 1;
    _scrollController.jumpTo(0);
    setState(() {});
  }

  void _nextStep() {
    _logger.finer('Going to next step from step $_currentStep');

    _stepStatus[0] = StepState.complete;
    if (_currentStep >= 1) {
      _stepStatus[1] = widget.formController.isAttitudeCompleted
          ? StepState.complete
          : StepState.error;
    }
    if (_currentStep >= 2) {
      _stepStatus[2] = widget.formController.isSkillCompleted
          ? StepState.complete
          : StepState.error;
    }
    if (_currentStep >= 3) {
      _stepStatus[3] = widget.formController.isGeneralAppreciationCompleted
          ? StepState.complete
          : StepState.error;
    }
    setState(() {});

    if (_currentStep == 3) {
      _submit();
      return;
    }

    _currentStep += 1;
    _scrollController.jumpTo(0);
    setState(() {});
  }

  void _cancel() async {
    _logger.info('Cancelling VisaEvaluationDialog');
    final answer = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
      isEditing: widget.editMode,
    );
    if (!mounted || !answer) return;

    _logger.fine('User confirmed cancellation, closing dialog');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(null);
  }

  Future<void> _submit() async {
    _logger.info('Submitting attitude evaluation form');
    if (!widget.formController.isCompleted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => const AlertDialog(
          title: Text('Formulaire incomplet'),
          content: Text('Répondre à toutes les questions.'),
        ),
      );
      return;
    }

    _logger.fine('Visa evaluation form submitted successfully');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(widget.formController.toVisa());
  }

  Widget _controlBuilder(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Expanded(child: SizedBox()),
          if (_currentStep != 0)
            OutlinedButton(
              onPressed: _previousStep,
              child: const Text('Précédent'),
            ),
          const SizedBox(width: 20),
          if (_currentStep != 3)
            TextButton(
              onPressed: details.onStepContinue,
              child: const Text('Suivant'),
            ),
          if (_currentStep == 3 && widget.editMode)
            TextButton(
              onPressed: details.onStepContinue,
              child: const Text('Soumettre'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building AttitudeEvaluationScreen for student: ${widget.formController.studentId}',
    );

    final student = StudentsHelpers.studentsInMyGroups(context)
        .firstWhereOrNull((e) => e.id == widget.formController.studentId);

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            student == null
                ? 'En attente des informations'
                : 'Génération du visa pour ${student.firstName} ${student.lastName}',
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
                  type: StepperType.horizontal,
                  currentStep: _currentStep,
                  onTapContinue: _nextStep,
                  onStepTapped: (int tapped) => setState(() {
                    _currentStep = tapped;
                    _scrollController.jumpTo(0);
                  }),
                  onTapCancel: _cancel,
                  steps: [
                    Step(
                      label: const Text('Détails'),
                      title: Container(),
                      state: _stepStatus[0],
                      isActive: _currentStep == 0,
                      content: _AttitudeGeneralDetailsStep(
                        formController: widget.formController,
                        editMode: widget.editMode,
                      ),
                    ),
                    Step(
                      label: const Text('Attitudes'),
                      title: Container(),
                      state: _stepStatus[1],
                      isActive: _currentStep == 1,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AttitudeRadioChoices(
                            title: '1. *${Inattendance.title}',
                            formController: widget.formController,
                            elements: Inattendance.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '2. *${Ponctuality.title}',
                            formController: widget.formController,
                            elements: Ponctuality.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '3. *${Sociability.title}',
                            formController: widget.formController,
                            elements: Sociability.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '4. *${Politeness.title}',
                            formController: widget.formController,
                            elements: Politeness.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '5. *${Motivation.title}',
                            formController: widget.formController,
                            elements: Motivation.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '6. *${DressCode.title}',
                            formController: widget.formController,
                            elements: DressCode.values,
                            editMode: widget.editMode,
                          ),
                        ],
                      ),
                    ),
                    Step(
                      label: const Text('Aptitudes'),
                      title: Container(),
                      state: _stepStatus[2],
                      isActive: _currentStep == 2,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AttitudeRadioChoices(
                            title: '7. *${QualityOfWork.title}',
                            formController: widget.formController,
                            elements: QualityOfWork.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '8. *${Productivity.title}',
                            formController: widget.formController,
                            elements: Productivity.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '9. *${Autonomy.title}',
                            formController: widget.formController,
                            elements: Autonomy.values,
                            editMode: widget.editMode,
                          ),
                          _AttitudeRadioChoices(
                            title: '10. *${Cautiousness.title}',
                            formController: widget.formController,
                            elements: Cautiousness.values,
                            editMode: widget.editMode,
                          ),
                        ],
                      ),
                    ),
                    Step(
                      label: const Text('Commentaires'),
                      title: Container(),
                      state: _stepStatus[3],
                      isActive: _currentStep == 3,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AttitudeRadioChoices(
                            title: '11. *${GeneralAppreciation.title}',
                            formController: widget.formController,
                            elements: GeneralAppreciation.values,
                            editMode: widget.editMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                  controlsBuilder: _controlBuilder,
                ),
        ),
      ),
    );
  }
}

class _AttitudeGeneralDetailsStep extends StatelessWidget {
  const _AttitudeGeneralDetailsStep({
    required this.formController,
    required this.editMode,
  });

  final VisaFormController formController;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TODO'),
      ],
    );
  }
}

class _AttitudeRadioChoices extends StatefulWidget {
  const _AttitudeRadioChoices({
    required this.title,
    required this.formController,
    required this.elements,
    required this.editMode,
  });

  final String title;
  final VisaFormController formController;
  final List<VisaCategoryEnum> elements;
  final bool editMode;

  @override
  State<_AttitudeRadioChoices> createState() => _AttitudeRadioChoicesState();
}

class _AttitudeRadioChoicesState extends State<_AttitudeRadioChoices> {
  @override
  void initState() {
    super.initState();
    if (widget.editMode) {
      widget.formController.responses[widget.elements[0].runtimeType] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RadioGroup(
      groupValue:
          widget.formController.responses[widget.elements[0].runtimeType],
      onChanged: (newValue) => setState(
        () => widget.formController.responses[widget.elements[0].runtimeType] =
            newValue!,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubTitle(widget.title),
          ...widget.elements.map(
            (e) => RadioListTile<VisaCategoryEnum>(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(
                e.name,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: Colors.black),
              ),
              value: e,
              enabled: widget.editMode,
            ),
          ),
        ],
      ),
    );
  }
}
