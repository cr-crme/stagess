import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/form_fields/low_high_slider_form_field.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/forms/enterprise_evaluation_form_enums.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/post_internship_enterprise_evaluation.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('EnterpriseEvaluationScreen');
const double _defaultValue = 3.0;

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
  }) : program = canModify
            ? (StudentsProvider.of(context, listen: false)
                .fromId(InternshipsProvider.of(context, listen: false)
                    .fromId(internshipId)
                    .studentId)
                .program)
            : (InternshipsProvider.of(context, listen: false)
                    .fromId(internshipId)
                    .enterpriseEvaluations
                    .firstWhereOrNull((e) => e.id == evaluationId)
                    ?.program ??
                Program.undefined) {
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
  final Program program;

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

  DateTime _evaluationDate = DateTime.now();

  final _skillController = CheckboxWithOtherController<RequiredSkills>(
      elements: RequiredSkills.values);
  TaskVariety _taskVariety = TaskVariety.none;
  TrainingPlan _trainingPlan = TrainingPlan.none;

  double _autonomyExpected = _defaultValue;
  double _supervisionStyle = _defaultValue;
  double _efficiencyExpected = _defaultValue;
  double _specialNeedsAccommodation = _defaultValue;
  double _easeOfCommunication = _defaultValue;
  double _absenceAcceptance = _defaultValue;
  double _sstManagement = _defaultValue;

  void dispose() {
    try {
      _skillController.dispose();
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

    if (!canModify) _evaluationDate = evaluation.date;

    _skillController.forceSetIfDifferent(
        comparator: CheckboxWithOtherController(
            elements: RequiredSkills.values,
            initialValues: evaluation.skillsRequired));

    _taskVariety =
        (evaluation.taskVariety == 0 ? TaskVariety.low : TaskVariety.high);
    _trainingPlan = evaluation.trainingPlanRespect == 0
        ? TrainingPlan.notFollowed
        : TrainingPlan.followed;
    if (!canModify || evaluation.autonomyExpected >= 0) {
      _autonomyExpected = evaluation.autonomyExpected;
    }
    if (!canModify || evaluation.supervisionStyle >= 0) {
      _supervisionStyle = evaluation.supervisionStyle;
    }
    if (!canModify || evaluation.efficiencyExpected >= 0) {
      _efficiencyExpected = evaluation.efficiencyExpected;
    }
    if (!canModify || evaluation.specialNeedsAccommodation >= 0) {
      _specialNeedsAccommodation = evaluation.specialNeedsAccommodation;
    }
    if (!canModify || evaluation.easeOfCommunication >= 0) {
      _easeOfCommunication = evaluation.easeOfCommunication;
    }
    if (!canModify || evaluation.absenceAcceptance >= 0) {
      _absenceAcceptance = evaluation.absenceAcceptance;
    }
    if (!canModify || evaluation.sstManagement >= 0) {
      _sstManagement = evaluation.sstManagement;
    }
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
      date: _evaluationDate,
      internshipId: internshipId,
      program: program,
      skillsRequired: _skillController.values,
      taskVariety: _taskVariety.toDouble(),
      trainingPlanRespect: _trainingPlan.toDouble(),
      autonomyExpected: _autonomyExpected,
      supervisionStyle: _supervisionStyle,
      efficiencyExpected: _efficiencyExpected,
      specialNeedsAccommodation: _specialNeedsAccommodation,
      easeOfCommunication: _easeOfCommunication,
      absenceAcceptance: _absenceAcceptance,
      sstManagement: _sstManagement,
    );
  }

  void _resetForm(BuildContext context) {
    _evaluationDate = DateTime.now();
    _previousEvaluationId = null;

    _skillController.forceSetIfDifferent(
        comparator: CheckboxWithOtherController(
            elements: RequiredSkills.values, initialValues: []));
    _taskVariety = TaskVariety.none;
    _trainingPlan = TrainingPlan.none;
    _autonomyExpected = _defaultValue;
    _supervisionStyle = _defaultValue;
    _efficiencyExpected = _defaultValue;
    _specialNeedsAccommodation = _defaultValue;
    _easeOfCommunication = _defaultValue;
    _absenceAcceptance = _defaultValue;
    _sstManagement = _defaultValue;
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
  final _formKey = GlobalKey<FormState>();

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

  void _showInvalidFieldsSnakBar([String? message]) {
    ScaffoldMessenger.of(context).clearSnackBars();
    showSnackBar(
      context,
      message: message ?? 'Remplir tous les champs avec un *.',
    );
  }

  void _submit() async {
    _logger
        .info('Submitting evaluation for internship: ${widget.internshipId}');

    if (!_controller.canModify) {
      Navigator.of(context).pop();
      return;
    }

    bool valid = _formKey.currentState?.validate() ?? true;
    String? message;

    setState(() {});

    if (!valid) {
      _showInvalidFieldsSnakBar(message);
      return;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.of(context).pop(_controller.toInternshipEvaluation());
  }

  void _cancel() async {
    _logger.info('Cancel called');
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

    final enterprise = EnterprisesProvider.of(context, listen: false)
        .firstWhereOrNull((e) => e.id == internship.enterpriseId);

    final student = StudentsHelpers.studentsInMyGroups(context, listen: false)
        .firstWhereOrNull((e) => e.id == internship.studentId);

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
        // Sometimes for some reason the build is called this with these
        // provider empty on the first call
        body: student == null || enterprise == null
            ? Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor),
              )
            : Selector<EnterprisesProvider, Job>(
                builder: (context, job, _) => Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _EvaluationDate(controller: _controller),
                                const SubTitle('Informations générales',
                                    left: 0),
                                _buildEnterpriseName(enterprise),
                                _buildStudentName(student),
                                const SubTitle('Tâches', left: 0),
                                _buildVariety(),
                                const SizedBox(height: 12),
                                _buildTrainingPlan(),
                                const SubTitle('Habiletés', left: 0),
                                const SizedBox(height: 16),
                                _buildSkillsRequired(),
                                const Text('Encadrement'),
                                const SubTitle(
                                    'Attentes envers le ou la stagiaire',
                                    left: 0),
                                _buildAutonomyRequired(),
                                const SizedBox(height: 8),
                                _buildEfficiency(),
                                const SizedBox(height: 8),
                                _buildSpecialNeedsAccomodation(),
                                const SubTitle('Encadrement', left: 0),
                                _buildSupervisionStyle(),
                                const SizedBox(height: 8),
                                _buildCommunication(),
                                const SizedBox(height: 8),
                                _buildAbsenceTolerance(),
                                const SizedBox(height: 8),
                                _buildSstManagement(),
                              ],
                            ),
                          ),
                        ),
                        _controlBuilder(),
                      ],
                    ),
                  ),
                ),
                selector: (context, enterprises) =>
                    enterprises[internship.enterpriseId]
                        .jobs[internship.currentContract?.jobId],
              ),
      ),
    );
  }

  Widget _buildSkillsRequired() {
    return CheckboxWithOther(
      controller: _controller._skillController,
      title: '* Habiletés requises pour le stage\u00a0:',
      enabled: _controller.canModify,
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

  Widget _buildVariety() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '* Tâches données à l\'élève',
              style: Theme.of(context).textTheme.titleSmall!,
            ),
            IconButton(
              icon: Icon(Icons.info_rounded,
                  color: Theme.of(context).primaryColor),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text(
                        'Tâches incluses dans le répertoire des métiers semi-spécialisés'),
                  ),
                );
              },
            )
          ],
        ),
        RadioGroup(
          groupValue: _controller._taskVariety,
          onChanged: (value) =>
              setState(() => _controller._taskVariety = value!),
          child: Column(
            children: [
              SizedBox(
                width: 200,
                child: RadioListTile<TaskVariety>(
                  value: TaskVariety.low,
                  enabled: _controller.canModify,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'Peu variées',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: RadioListTile<TaskVariety>(
                  value: TaskVariety.mid,
                  enabled: _controller.canModify,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'Variées',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: RadioListTile<TaskVariety>(
                  value: TaskVariety.high,
                  enabled: _controller.canModify,
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

  Widget _buildTrainingPlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Respect du plan de formation',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        Text(
          'Possibilité d\'exercer toutes les tâches de toutes les compétences spécifiques '
          'obligatoires d\'un métier semi-spécialisé',
        ),
        RadioGroup(
          groupValue: _controller._trainingPlan,
          onChanged: (value) =>
              setState(() => _controller._trainingPlan = value!),
          child: Column(
            children: [
              SizedBox(
                width: 200,
                child: RadioListTile<TrainingPlan>(
                  value: TrainingPlan.followed,
                  enabled: _controller.canModify,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'Oui',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: RadioListTile<TrainingPlan>(
                  value: TrainingPlan.notFollowed,
                  enabled: _controller.canModify,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'Non',
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

  Widget _buildSpecialNeedsAccomodation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Ouverture de l\'entreprise à accueillir des élèves avec des besoins particuliers',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            initialValue: _controller._specialNeedsAccommodation,
            fixed: !_controller.canModify,
            onChanged: (value) =>
                _controller._specialNeedsAccommodation = value,
            lowLabel: SpecialNeedsAccommodation.low.label,
            highLabel: SpecialNeedsAccommodation.high.label,
          ),
        )
      ],
    );
  }

  Widget _buildSstManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '* Encadrement par rapport à la SST',
              style: Theme.of(context).textTheme.titleSmall!,
            ),
            IconButton(
              icon: Icon(Icons.info_rounded,
                  color: Theme.of(context).primaryColor),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text(
                        'Niveau d\'encadrement des mesures de sécurité et prévention '
                        'des risques à la SST (formations, modélisation, accompagnement, etc.)'),
                  ),
                );
              },
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: LowHighSliderFormField(
            initialValue: _controller._sstManagement,
            fixed: !_controller.canModify,
            onChanged: (value) => _controller._sstManagement = value,
            lowLabel: SstManagement.low.label,
            highLabel: SstManagement.high.label,
          ),
        )
      ],
    );
  }

  Widget _buildAbsenceTolerance() {
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
            initialValue: _controller._absenceAcceptance,
            fixed: !_controller.canModify,
            onChanged: (value) => _controller._absenceAcceptance = value,
            lowLabel: AbsenceAcceptance.low.label,
            highLabel: AbsenceAcceptance.high.label,
          ),
        )
      ],
    );
  }

  Widget _buildCommunication() {
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
            initialValue: _controller._easeOfCommunication,
            fixed: !_controller.canModify,
            onChanged: (value) => _controller._easeOfCommunication = value,
            lowLabel: EaseOfCommunication.low.label,
            highLabel: EaseOfCommunication.high.label,
          ),
        )
      ],
    );
  }

  Widget _buildSupervisionStyle() {
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
            initialValue: _controller._supervisionStyle,
            fixed: !_controller.canModify,
            onChanged: (value) => _controller._supervisionStyle = value,
            lowLabel: SupervisionStyle.low.label,
            highLabel: SupervisionStyle.high.label,
          ),
        )
      ],
    );
  }

  Widget _buildEfficiency() {
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
            initialValue: _controller._efficiencyExpected,
            fixed: !_controller.canModify,
            onChanged: (value) => _controller._efficiencyExpected = value,
            lowLabel: EfficiencyExpected.low.label,
            highLabel: EfficiencyExpected.high.label,
          ),
        )
      ],
    );
  }

  Widget _buildAutonomyRequired() {
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
            initialValue: _controller._autonomyExpected,
            fixed: !_controller.canModify,
            onChanged: (value) => _controller._autonomyExpected = value,
            lowLabel: AutonomyExpected.low.label,
            highLabel: AutonomyExpected.high.label,
          ),
        ),
      ],
    );
  }

  Widget _controlBuilder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_controller.canModify)
            OutlinedButton(
              onPressed: _cancel,
              child: const Text('Annuler'),
            ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: _submit,
            child: Text(_controller.canModify ? 'Enregistrer' : 'Fermer'),
          ),
        ],
      ),
    );
  }
}

class _EvaluationDate extends StatefulWidget {
  const _EvaluationDate({required this.controller});

  final EnterpriseEvaluationFormController controller;

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
      initialDate: widget.controller._evaluationDate,
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (newDate == null) return;

    widget.controller._evaluationDate = newDate;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4),
        const SubTitle('Date de l\'évaluation', left: 0.0),
        Row(
          children: [
            Text(
              DateFormat('dd MMMM yyyy', 'fr_CA')
                  .format(widget.controller._evaluationDate),
            ),
            if (widget.controller.canModify)
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.blue,
                ),
                onPressed: () => _promptDate(context),
              ),
          ],
        ),
      ],
    );
  }
}
