import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/form_fields/low_high_slider_form_field.dart';
import 'package:stagess/common/widgets/scrollable_stepper.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/screens/internship_forms/student_steps/enterprise_evaluation_form_enums.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/post_internship_enterprise_evaluation.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('EnterpriseEvaluationScreen');

Future<Internship?> showEnterpriseEvaluationFormDialog(
  BuildContext context, {
  required String internshipId,
  String? evaluationId,
}) async {
  final newEvaluation = await showDialog<PostInternshipEnterpriseEvaluation>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
        child: _EnterpriseEvaluationScreen(
            internshipId: internshipId, evaluationId: evaluationId)),
  );
  if (newEvaluation == null || !context.mounted) return null;

  final internship =
      InternshipsProvider.of(context, listen: false).fromId(internshipId);
  return Internship.fromSerialized(internship.serialize())
    ..enterpriseEvaluations.add(newEvaluation);
}

class EnterpriseEvaluationFormController {
  EnterpriseEvaluationFormController(
    BuildContext context, {
    required this.internshipId,
    String? evaluationId,
    required this.canModify,
  }) {
    clearForm(context);
    if (evaluationId != null) {
      fillFromPreviousEvaluation(context, previousEvaluationId: evaluationId);
    }
  }
  String? _previousEvaluationId; // -1 is the last, null is not from evaluation
  bool get isFilledUsingPreviousEvaluation => _previousEvaluationId != null;

  final bool canModify;

  final String internshipId;
  Internship internship(BuildContext context, {bool listen = true}) =>
      InternshipsProvider.of(context, listen: listen)[internshipId];

  factory EnterpriseEvaluationFormController.fromInternshipId(
    BuildContext context, {
    required String internshipId,
    required String evaluationId,
    required bool canModify,
  }) {
    final controller = EnterpriseEvaluationFormController(
      context,
      internshipId: internshipId,
      canModify: canModify,
    );
    controller.fillFromPreviousEvaluation(context,
        previousEvaluationId: evaluationId);
    return controller;
  }

  DateTime evaluationDate = DateTime.now();

  final _skillController = CheckboxWithOtherController<RequiredSkills>(
      elements: RequiredSkills.values);
  TaskVariety _taskVariety = TaskVariety.none;
  TrainingPlan _trainingPlan = TrainingPlan.none;
  double _autonomyExpected = 3.0;
  double _supervisionStyle = 3.0;
  double _efficiencyExpected = 3.0;
  double _easeOfCommunication = 3.0;
  double _absenceAcceptance = 3.0;
  final _supervisionCommentsController = TextEditingController();

  final _disabilityController =
      CheckboxWithOtherController(elements: Disabilities.values);
  late bool _hasStudentHadDisabilities = false;

  double _autismSpectrumDisorderAcceptance = -1;
  double _acceptanceLanguageDisorder = -1;
  double _acceptanceIntellectualDisability = -1;
  double _acceptancePhysicalDisability = -1;
  double _acceptanceMentalHealthDisorder = -1;
  double _acceptanceBehaviorDifficulties = -1;

  void dispose() {
    try {
      _skillController.dispose();
      _supervisionCommentsController.dispose();
      _disabilityController.dispose();
    } catch (e) {
      // Do nothing
    }
  }

  void clearForm(BuildContext context) {
    _resetForm(context);
  }

  void fillFromPreviousEvaluation(BuildContext context,
      {required String previousEvaluationId}) {
    // Reset the form to fresh
    _resetForm(context);
    _previousEvaluationId = previousEvaluationId;

    final evaluation = _previousEvaluation(context);
    if (evaluation == null) return;

    if (!canModify) evaluationDate = evaluation.date;

    _skillController.forceSetIfDifferent(
        comparator: CheckboxWithOtherController(
            elements: RequiredSkills.values,
            initialValues: evaluation.skillsRequired));

    _taskVariety =
        (evaluation.taskVariety == 0 ? TaskVariety.low : TaskVariety.high);
    _trainingPlan = evaluation.trainingPlanRespect == 0
        ? TrainingPlan.notFilled
        : TrainingPlan.filled;
    if (!canModify || evaluation.autonomyExpected >= 0) {
      _autonomyExpected = evaluation.autonomyExpected;
    }
    if (!canModify || evaluation.supervisionStyle >= 0) {
      _supervisionStyle = evaluation.supervisionStyle;
    }
    if (!canModify || evaluation.efficiencyExpected >= 0) {
      _efficiencyExpected = evaluation.efficiencyExpected;
    }
    if (!canModify || evaluation.easeOfCommunication >= 0) {
      _easeOfCommunication = evaluation.easeOfCommunication;
    }
    if (!canModify || evaluation.absenceAcceptance >= 0) {
      _absenceAcceptance = evaluation.absenceAcceptance;
    }
    _supervisionCommentsController.text = evaluation.supervisionComments;

    _disabilityController.forceSetIfDifferent(
        comparator: CheckboxWithOtherController(
            elements: Disabilities.values,
            initialValues: [
              evaluation.acceptanceTsa >= 0
                  ? Disabilities.autismSpectrumDisorder.toString()
                  : null,
              evaluation.acceptanceLanguageDisorder >= 0
                  ? Disabilities.languageDisorder.toString()
                  : null,
              evaluation.acceptanceIntellectualDisability >= 0
                  ? Disabilities.intellectualDisability.toString()
                  : null,
              evaluation.acceptancePhysicalDisability >= 0
                  ? Disabilities.physicalDisability.toString()
                  : null,
              evaluation.acceptanceMentalHealthDisorder >= 0
                  ? Disabilities.mentalHealthDisorder.toString()
                  : null,
              evaluation.acceptanceBehaviorDifficulties >= 0
                  ? Disabilities.behavioralDifficulties.toString()
                  : null,
            ].where((e) => e != null).cast<String>().toList()));
    _hasStudentHadDisabilities = _disabilityController.selected.isNotEmpty;

    _autismSpectrumDisorderAcceptance = evaluation.acceptanceTsa;
    _acceptanceLanguageDisorder = evaluation.acceptanceLanguageDisorder;
    _acceptanceIntellectualDisability =
        evaluation.acceptanceIntellectualDisability;
    _acceptancePhysicalDisability = evaluation.acceptancePhysicalDisability;
    _acceptanceMentalHealthDisorder = evaluation.acceptanceMentalHealthDisorder;
    _acceptanceBehaviorDifficulties = evaluation.acceptanceBehaviorDifficulties;
  }

  PostInternshipEnterpriseEvaluation? _previousEvaluation(
      BuildContext context) {
    if (!isFilledUsingPreviousEvaluation) return null;

    final internshipTp = internship(context, listen: false);
    if (internshipTp.enterpriseEvaluations.isEmpty) return null;

    return internshipTp.enterpriseEvaluations
            .firstWhereOrNull((e) => e.id == _previousEvaluationId) ??
        internshipTp.enterpriseEvaluations.last;
  }

  PostInternshipEnterpriseEvaluation toInternshipEvaluation() {
    return PostInternshipEnterpriseEvaluation(
      date: evaluationDate,
      internshipId: internshipId,
      skillsRequired: _skillController.values,
      taskVariety: _taskVariety.toDouble(),
      trainingPlanRespect: _trainingPlan.toDouble(),
      autonomyExpected: _autonomyExpected,
      supervisionStyle: _supervisionStyle,
      efficiencyExpected: _efficiencyExpected,
      easeOfCommunication: _easeOfCommunication,
      absenceAcceptance: _absenceAcceptance,
      supervisionComments: _supervisionCommentsController.text,
      acceptanceTsa:
          _hasStudentHadDisabilities ? _autismSpectrumDisorderAcceptance : -1,
      acceptanceLanguageDisorder:
          _hasStudentHadDisabilities ? _acceptanceLanguageDisorder : -1,
      acceptanceIntellectualDisability:
          _hasStudentHadDisabilities ? _acceptanceIntellectualDisability : -1,
      acceptancePhysicalDisability:
          _hasStudentHadDisabilities ? _acceptancePhysicalDisability : -1,
      acceptanceMentalHealthDisorder:
          _hasStudentHadDisabilities ? _acceptanceMentalHealthDisorder : -1,
      acceptanceBehaviorDifficulties:
          _hasStudentHadDisabilities ? _acceptanceBehaviorDifficulties : -1,
    );
  }

  void _resetForm(BuildContext context) {
    evaluationDate = DateTime.now();
    _previousEvaluationId = null;

    _skillController.forceSetIfDifferent(
        comparator: CheckboxWithOtherController(
            elements: RequiredSkills.values, initialValues: []));
    _taskVariety = TaskVariety.none;
    _trainingPlan = TrainingPlan.none;
    _autonomyExpected = 3.0;
    _supervisionStyle = 3.0;
    _efficiencyExpected = 3.0;
    _easeOfCommunication = 3.0;
    _absenceAcceptance = 3.0;
    _supervisionCommentsController.text = '';

    _disabilityController.forceSetIfDifferent(
        comparator: CheckboxWithOtherController(
            elements: Disabilities.values, initialValues: []));
    _hasStudentHadDisabilities = false;
    _autismSpectrumDisorderAcceptance = -1;
    _acceptanceLanguageDisorder = -1;
    _acceptanceIntellectualDisability = -1;
    _acceptancePhysicalDisability = -1;
    _acceptanceMentalHealthDisorder = -1;
    _acceptanceBehaviorDifficulties = -1;
  }
}

class _EnterpriseEvaluationScreen extends StatefulWidget {
  const _EnterpriseEvaluationScreen(
      {required this.internshipId, required this.evaluationId});

  final String internshipId;
  final String? evaluationId;

  @override
  State<_EnterpriseEvaluationScreen> createState() =>
      _EnterpriseEvaluationScreenState();
}

class _EnterpriseEvaluationScreenState
    extends State<_EnterpriseEvaluationScreen> {
  final _scrollController = ScrollController();

  final List<StepState> _stepStatus = [
    StepState.indexed,
    StepState.indexed,
    StepState.indexed,
  ];

  late final EnterpriseEvaluationFormController _controller =
      widget.evaluationId == null
          ? EnterpriseEvaluationFormController(context,
              internshipId: widget.internshipId,
              evaluationId: InternshipsProvider.of(context, listen: false)
                  .fromId(widget.internshipId)
                  .enterpriseEvaluations
                  .lastOrNull
                  ?.id,
              canModify: true)
          : (InternshipsProvider.of(context, listen: false)
                      .fromId(widget.internshipId)
                      .enterpriseEvaluations
                      .firstWhereOrNull((e) => e.id == widget.evaluationId) ==
                  null
              ? EnterpriseEvaluationFormController(context,
                  internshipId: widget.internshipId, canModify: false)
              : EnterpriseEvaluationFormController.fromInternshipId(context,
                  internshipId: widget.internshipId,
                  evaluationId: widget.evaluationId!,
                  canModify: false));

  final _taskAndAbilityKey = GlobalKey<_TaskAndAbilityStepState>();
  final _supervisionKey = GlobalKey<_SupervisionStepState>();
  final _specializedStudentsKey = GlobalKey<_SpecializedStudentsStepState>();
  final double _tabHeight = 0.0;
  int _currentStep = 0;

  void _showInvalidFieldsSnakBar([String? message]) {
    ScaffoldMessenger.of(context).clearSnackBars();
    showSnackBar(
      context,
      message: message ?? 'Remplir tous les champs avec un *.',
    );
  }

  void _nextStep() async {
    _logger.finer('Next step called, current step: $_currentStep');
    if (!_controller.canModify) {
      setState(() {
        _currentStep += 1;
      });
      _currentStep > 2 ? _cancel() : _scrollToCurrentTab();
      return;
    }

    bool valid = false;
    String? message;
    if (_currentStep >= 0) {
      message = await _taskAndAbilityKey.currentState!.validate();
      valid = message == null;
      _stepStatus[0] = valid ? StepState.complete : StepState.error;
    }
    if (_currentStep >= 1) {
      message = await _supervisionKey.currentState!.validate();
      valid = message == null;
      _stepStatus[1] = valid ? StepState.complete : StepState.error;
    }
    if (_currentStep >= 2) {
      message = await _specializedStudentsKey.currentState!.validate();
      valid = message == null;
      _stepStatus[2] = valid ? StepState.complete : StepState.error;
    }
    setState(() {});

    if (!valid) {
      _showInvalidFieldsSnakBar(message);
      return;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    if (_currentStep == 2) {
      if ((await _taskAndAbilityKey.currentState!.validate()) != null) {
        setState(() {
          _currentStep = 0;
          _scrollToCurrentTab();
        });
        _showInvalidFieldsSnakBar(message);
        return;
      }

      if (await _supervisionKey.currentState!.validate() != null) {
        setState(() {
          _currentStep = 1;
          _scrollToCurrentTab();
        });
        _showInvalidFieldsSnakBar(message);
        return;
      }
      _submit();
    } else {
      setState(() {
        _currentStep += 1;
        _scrollToCurrentTab();
      });
    }
  }

  void _previousStep() {
    _logger.finer('Previous step called, current step: $_currentStep');

    _currentStep--;
    _scrollToCurrentTab();
    setState(() {});
  }

  void _scrollToCurrentTab() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Wait until the stepper has closed and reopened before moving
      _scrollController.jumpTo(_currentStep * _tabHeight);
    });
  }

  void _submit() {
    _logger
        .info('Submitting evaluation for internship: ${widget.internshipId}');

    Navigator.of(context).pop(_controller.toInternshipEvaluation());
  }

  void _cancel() async {
    _logger.info('Cancel called, current step: $_currentStep');
    final navigator = Navigator.of(context);

    if (_controller.canModify) {
      final answer = await ConfirmExitDialog.show(
        context,
        content: const Text('Toutes les modifications seront perdues.'),
      );
      if (!mounted || !answer) return;
    }

    _logger.fine('User confirmed exit, navigating back');
    navigator.pop(null);
  }

  @override
  Widget build(BuildContext context) {
    _logger.fine(
      'Building EnterpriseEvaluationScreen for internship: ${widget.internshipId}',
    );

    final internships = InternshipsProvider.of(context, listen: false);
    final internship =
        internships.firstWhere((e) => e.id == widget.internshipId);

    if (_currentStep > 2) {
      // We are probably waiting for the current page to close
      return SizedBox.shrink();
    }

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Évaluation post-stage'),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: PopScope(
          child: Selector<EnterprisesProvider, Job>(
            builder: (context, job, _) => ScrollableStepper(
              type: StepperType.horizontal,
              scrollController: _scrollController,
              currentStep: _currentStep,
              onTapContinue: _nextStep,
              onStepTapped: (int tapped) => setState(() {
                _scrollController.jumpTo(0);
                _currentStep = tapped;
              }),
              onTapCancel: () => Navigator.pop(context),
              steps: [
                Step(
                  state: _stepStatus[0],
                  isActive: _currentStep == 0,
                  title: const Text(
                    'Tâches et\nhabiletés',
                    textAlign: TextAlign.center,
                  ),
                  content: _TaskAndAbilityStep(
                    key: _taskAndAbilityKey,
                    controller: _controller,
                  ),
                ),
                Step(
                  state: _stepStatus[1],
                  isActive: _currentStep == 1,
                  title: const Text('Encadrement'),
                  content: _SupervisionStep(
                      key: _supervisionKey, controller: _controller),
                ),
                Step(
                  state: _stepStatus[2],
                  isActive: _currentStep == 2,
                  title: const Text('Clientèle\nspécialisée'),
                  content: _SpecializedStudentsStep(
                    key: _specializedStudentsKey,
                    controller: _controller,
                  ),
                ),
              ],
              controlsBuilder: _controlBuilder,
            ),
            selector: (context, enterprises) =>
                enterprises[internship.enterpriseId].jobs[internship.jobId],
          ),
        ),
      ),
    );
  }

  Widget _controlBuilder(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentStep != 0)
            OutlinedButton(
              onPressed: _previousStep,
              child: const Text('Précédent'),
            ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: details.onStepContinue,
            child: _currentStep == 2
                ? Text(_controller.canModify ? 'Confirmer' : 'Fermer')
                : const Text('Suivant'),
          ),
        ],
      ),
    );
  }
}

class _TaskAndAbilityStep extends StatefulWidget {
  const _TaskAndAbilityStep({super.key, required this.controller});

  final EnterpriseEvaluationFormController controller;

  @override
  State<_TaskAndAbilityStep> createState() => _TaskAndAbilityStepState();
}

class _TaskAndAbilityStepState extends State<_TaskAndAbilityStep> {
  final _formKey = GlobalKey<FormState>();

  Internship get _internship => widget.controller.internship(context);

  Future<String?> validate() async {
    _logger.finer('Validating TaskAndAbilityStep');

    if (!_formKey.currentState!.validate() ||
        widget.controller._taskVariety == TaskVariety.none ||
        widget.controller._trainingPlan == TrainingPlan.none) {
      return 'Remplir tous les champs avec un *.';
    }
    _formKey.currentState!.save();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building TaskAndAbilityStep for internship: ${_internship.id}',
    );

    final enterprise = EnterprisesProvider.of(
      context,
      listen: false,
    ).firstWhereOrNull((e) => e.id == _internship.enterpriseId);

    // Sometimes for some reason the build is called this with these
    // provider empty on the first call
    if (enterprise == null) return Container();
    final student = StudentsHelpers.studentsInMyGroups(
      context,
    ).firstWhereOrNull((e) => e.id == _internship.studentId);

    return student == null
        ? Container()
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SubTitle('Informations générales', left: 0),
                  _buildEnterpriseName(enterprise),
                  _buildStudentName(student),
                  const SubTitle('Tâches', left: 0),
                  _buildVariety(context),
                  const SizedBox(height: 8),
                  _buildTrainingPlan(context),
                  const SubTitle('Habiletés', left: 0),
                  const SizedBox(height: 16),
                  _buildSkillsRequired(context),
                ],
              ),
            ),
          );
  }

  Widget _buildSkillsRequired(BuildContext context) {
    return CheckboxWithOther(
      controller: widget.controller._skillController,
      title: '* Habiletés requises pour le stage\u00a0:',
      enabled: widget.controller.canModify,
      errorMessageOther: 'Préciser les autres habiletés requises.',
    );
  }

  TextField _buildEnterpriseName(Enterprise enterprise) {
    // ThemeData does not work anymore so we have to override the style manually
    const styleOverride = TextStyle(color: Colors.black);

    return TextField(
      decoration: const InputDecoration(
        labelText: 'Nom de l\'entreprise',
        border: InputBorder.none,
        labelStyle: styleOverride,
      ),
      enabled: false,
      style: styleOverride,
      controller: TextEditingController(text: enterprise.name),
    );
  }

  TextField _buildStudentName(Student student) {
    // ThemeData does not work anymore so we have to override the style manually
    const styleOverride = TextStyle(color: Colors.black);

    return TextField(
      decoration: const InputDecoration(
        labelText: 'Nom de l\'élève',
        border: InputBorder.none,
        labelStyle: styleOverride,
      ),
      enabled: false,
      style: styleOverride,
      controller: TextEditingController(text: student.fullName),
    );
  }

  Widget _buildVariety(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Tâches données à l\'élève',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        RadioGroup(
          groupValue: widget.controller._taskVariety,
          onChanged: (value) =>
              setState(() => widget.controller._taskVariety = value!),
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<TaskVariety>(
                  value: TaskVariety.low,
                  enabled: widget.controller.canModify,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'Peu variées',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Expanded(
                child: RadioListTile<TaskVariety>(
                  value: TaskVariety.high,
                  enabled: widget.controller.canModify,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'Très variées',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingPlan(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Respect du plan de formation',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        Text(
          'Tâches et compétences prévues dans le plan de formation ont été '
          'faites par l\'élève\u00a0:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        RadioGroup(
          groupValue: widget.controller._trainingPlan,
          onChanged: (value) =>
              setState(() => widget.controller._trainingPlan = value!),
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<TrainingPlan>(
                  value: TrainingPlan.notFilled,
                  enabled: widget.controller.canModify,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'En partie',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Expanded(
                child: RadioListTile<TrainingPlan>(
                  value: TrainingPlan.filled,
                  enabled: widget.controller.canModify,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'En totalité',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _SupervisionStep extends StatefulWidget {
  const _SupervisionStep({
    super.key,
    required this.controller,
  });

  final EnterpriseEvaluationFormController controller;

  @override
  State<_SupervisionStep> createState() => _SupervisionStepState();
}

class _SupervisionStepState extends State<_SupervisionStep> {
  final _formKey = GlobalKey<FormState>();

  Future<String?> validate() async {
    _logger.finer('Validating SupervisionStep');

    if (!_formKey.currentState!.validate()) {
      return 'Remplir tous les champs avec un *.';
    }
    _formKey.currentState!.save();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building SupervisionStep');

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SubTitle('Attentes envers le ou la stagiaire', left: 0),
            _buildAutonomyRequired(context),
            const SizedBox(height: 8),
            _buildEfficiency(context),
            const SubTitle('Encadrement', left: 0),
            _buildSupervisionStyle(context),
            const SizedBox(height: 8),
            _buildCommunication(context),
            const SizedBox(height: 8),
            _buildAbsenceTolerance(context),
            const SizedBox(height: 8),
            _Comments(
              controller: widget.controller._supervisionCommentsController,
              canModify: widget.controller.canModify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceTolerance(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Tolérance du milieu à l\'égard des retards et absences de l\'élève',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            initialValue: widget.controller._absenceAcceptance,
            fixed: !widget.controller.canModify,
            onChanged: (value) => widget.controller._absenceAcceptance = value,
            lowLabel: AbsenceAcceptance.low.label,
            highLabel: AbsenceAcceptance.high.label,
          ),
        )
      ],
    );
  }

  Widget _buildCommunication(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Communication avec l\'entreprise',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            initialValue: widget.controller._easeOfCommunication,
            fixed: !widget.controller.canModify,
            onChanged: (value) =>
                widget.controller._easeOfCommunication = value,
            lowLabel: EaseOfCommunication.low.label,
            highLabel: EaseOfCommunication.high.label,
          ),
        )
      ],
    );
  }

  Widget _buildSupervisionStyle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Type d\'encadrement',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            initialValue: widget.controller._supervisionStyle,
            fixed: !widget.controller.canModify,
            lowLabel: SupervisionStyle.low.label,
            highLabel: SupervisionStyle.high.label,
          ),
        )
      ],
    );
  }

  Widget _buildEfficiency(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Rendement de l\'élève',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            initialValue: widget.controller._efficiencyExpected,
            fixed: !widget.controller.canModify,
            onChanged: (value) => widget.controller._efficiencyExpected = value,
            lowLabel: EfficiencyExpected.low.label,
            highLabel: EfficiencyExpected.high.label,
          ),
        )
      ],
    );
  }

  Widget _buildAutonomyRequired(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Niveau d\'autonomie de l\'élève souhaité',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            initialValue: widget.controller._autonomyExpected,
            fixed: !widget.controller.canModify,
            onChanged: (value) => widget.controller._autonomyExpected = value,
            lowLabel: AutonomyExpected.low.label,
            highLabel: AutonomyExpected.high.label,
          ),
        ),
      ],
    );
  }
}

class _Comments extends StatelessWidget {
  const _Comments({required this.controller, required this.canModify});

  final TextEditingController controller;
  final bool canModify;

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: spacing),
          child: Text(
            'Autres commentaires sur l\'encadrement\u00a0:',
            style: Theme.of(context).textTheme.titleSmall!,
          ),
        ),
        TextFormField(
          controller: controller,
          enabled: canModify,
          maxLines: null,
        ),
      ],
    );
  }
}

class _SpecializedStudentsStep extends StatefulWidget {
  const _SpecializedStudentsStep({super.key, required this.controller});

  final EnterpriseEvaluationFormController controller;

  @override
  State<_SpecializedStudentsStep> createState() =>
      _SpecializedStudentsStepState();
}

class _SpecializedStudentsStepState extends State<_SpecializedStudentsStep> {
  final _formKey = GlobalKey<FormState>();

  Future<String?> validate() async {
    _logger.finer('Validating SpecializedStudentsStep');

    if (!_formKey.currentState!.validate()) {
      return 'Remplir tous les champs avec un *.';
    }
    _formKey.currentState!.save();
    return null;
  }

  Key _disabilityKey(Disabilities disability) {
    switch (disability) {
      case Disabilities.autismSpectrumDisorder:
        return const Key('acceptanceTSA');
      case Disabilities.languageDisorder:
        return const Key('acceptanceLanguageDisorder');
      case Disabilities.intellectualDisability:
        return const Key('acceptanceIntellectualDisability');
      case Disabilities.physicalDisability:
        return const Key('acceptancePhysicalDisability');
      case Disabilities.mentalHealthDisorder:
        return const Key('acceptanceMentalHealthDisorder');
      case Disabilities.behavioralDifficulties:
        return const Key('acceptanceBehaviorDifficulties');
    }
  }

  double _getDisabilityValue(Disabilities disability) {
    switch (disability) {
      case Disabilities.autismSpectrumDisorder:
        return widget.controller._autismSpectrumDisorderAcceptance;
      case Disabilities.languageDisorder:
        return widget.controller._acceptanceLanguageDisorder;
      case Disabilities.intellectualDisability:
        return widget.controller._acceptanceIntellectualDisability;
      case Disabilities.physicalDisability:
        return widget.controller._acceptancePhysicalDisability;
      case Disabilities.mentalHealthDisorder:
        return widget.controller._acceptanceMentalHealthDisorder;
      case Disabilities.behavioralDifficulties:
        return widget.controller._acceptanceBehaviorDifficulties;
    }
  }

  void _setDisabilityValue(Disabilities disability, double value) {
    switch (disability) {
      case Disabilities.autismSpectrumDisorder:
        widget.controller._autismSpectrumDisorderAcceptance = value;
        break;
      case Disabilities.languageDisorder:
        widget.controller._acceptanceLanguageDisorder = value;
        break;
      case Disabilities.intellectualDisability:
        widget.controller._acceptanceIntellectualDisability = value;
        break;
      case Disabilities.physicalDisability:
        widget.controller._acceptancePhysicalDisability = value;
        break;
      case Disabilities.mentalHealthDisorder:
        widget.controller._acceptanceMentalHealthDisorder = value;
        break;
      case Disabilities.behavioralDifficulties:
        widget.controller._acceptanceBehaviorDifficulties = value;
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building SpecializedStudentsStep');

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _YesOrNoRadioTile(
            title: '* Est-ce que le ou la stagiaire avait des besoins '
                'particuliers\u00a0?',
            value: widget.controller._hasStudentHadDisabilities,
            enabled: widget.controller.canModify,
            onChanged: (value) => setState(
                () => widget.controller._hasStudentHadDisabilities = value),
          ),
          if (widget.controller._hasStudentHadDisabilities)
            FormField(
              validator: (value) {
                for (final element
                    in widget.controller._disabilityController.selected) {
                  if (_getDisabilityValue(element) <= 0) {
                    return 'Sélectionner une valeur pour $element';
                  }
                }
                return null;
              },
              builder: (errorState) => CheckboxWithOther(
                controller: widget.controller._disabilityController,
                title:
                    '* Évaluer la prise en charge de l\'entreprise par rapport '
                    'aux différents besoins de l\'élève s\'il ou elle avait:\u00a0:',
                enabled: widget.controller.canModify,
                titleStyle: Theme.of(context).textTheme.titleSmall,
                elementStyleBuilder: (element, isSelected) {
                  var out = Theme.of(context).textTheme.titleSmall!;

                  if (errorState.hasError &&
                      widget.controller._disabilityController.selected
                          .contains(element) &&
                      _getDisabilityValue(element) <= 0) {
                    out = out.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    );
                  }

                  return out;
                },
                showOtherOption: false,
                subWidgetBuilder: (element, isSelected) {
                  return isSelected
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 24.0,
                              bottom: 8.0,
                            ),
                            child: _RatingBarForm(
                              key: _disabilityKey(element),
                              initialValue: _getDisabilityValue(element),
                              enabled: widget.controller.canModify,
                              validator: (value) => value! <= 0
                                  ? 'Sélectionner une valeur'
                                  : null,
                              onRatingChanged: (newValue) =>
                                  _setDisabilityValue(element, newValue!),
                            ),
                          ),
                        )
                      : Container();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _YesOrNoRadioTile extends StatelessWidget {
  const _YesOrNoRadioTile({
    required this.title,
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool enabled;
  final bool value;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup(
      groupValue: value,
      onChanged: (newValue) => onChanged(newValue!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: RadioListTile(
                  title: Text(
                    'Oui',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  enabled: enabled,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  value: true,
                ),
              ),
              SizedBox(
                width: 150,
                child: RadioListTile(
                  title: Text(
                    'Non',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  enabled: enabled,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  value: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingBarForm extends FormField<double> {
  const _RatingBarForm({
    super.key,
    super.initialValue = -1,
    required super.enabled,
    super.validator,
    required void Function(double? rating) onRatingChanged,
  }) : super(onSaved: onRatingChanged, builder: _builder);

  static Widget _builder(FormFieldState<double> state) {
    final onRatingChanged = state.widget.onSaved!;
    final enabled = (state.widget as _RatingBarForm).enabled;

    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 12.0),
      child: RatingBar(
        initialRating: state.value!,
        ratingWidget: RatingWidget(
          full: Icon(
            Icons.star,
            color: Theme.of(state.context).colorScheme.secondary,
          ),
          half: Icon(
            Icons.star_half,
            color: Theme.of(state.context).colorScheme.secondary,
          ),
          empty: Icon(
            Icons.star_border,
            color: Theme.of(state.context).colorScheme.secondary,
          ),
        ),
        ignoreGestures: !enabled,
        onRatingUpdate: (double value) {
          state.didChange(value);
          onRatingChanged(value);
        },
      ),
    );
  }
}
