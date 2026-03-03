import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';

final _logger = Logger('AttitudeEvaluationScreen');

Future<Internship?> showAttitudeEvaluationDialog(
  BuildContext context, {
  required String internshipId,
  String? evaluationId,
}) async {
  final newEvaluation = await showDialog<InternshipEvaluationAttitude?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (ctx) => Dialog(
          child: _AttitudeEvaluationScreen(
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
    ..attitudeEvaluations.add(newEvaluation);
}

class AttitudeEvaluationFormController {
  static const _formVersion = '1.0.0';

  AttitudeEvaluationFormController({required this.internshipId});
  final String internshipId;
  Internship internship(BuildContext context, {bool listen = true}) =>
      InternshipsProvider.of(context, listen: listen)[internshipId];

  factory AttitudeEvaluationFormController.fromInternshipId(
    BuildContext context, {
    required String internshipId,
    required String evaluationId,
  }) {
    Internship internship =
        InternshipsProvider.of(context, listen: false)[internshipId];
    InternshipEvaluationAttitude evaluation =
        internship.attitudeEvaluations.firstWhere((e) => e.id == evaluationId);

    final controller = AttitudeEvaluationFormController(
      internshipId: internshipId,
    );

    controller.evaluationDate = evaluation.date;

    controller.wereAtMeeting.clear();
    controller.wereAtMeeting.addAll(evaluation.presentAtEvaluation);

    controller._ponctuality = evaluation.attitude.ponctuality;
    controller._inattendance = evaluation.attitude.inattendance;
    controller._qualityOfWork = evaluation.attitude.qualityOfWork;
    controller._productivity = evaluation.attitude.productivity;
    controller._teamCommunication = evaluation.attitude.teamCommunication;
    controller._respectOfAuthority = evaluation.attitude.respectOfAuthority;
    controller._communicationAboutSst =
        evaluation.attitude.communicationAboutSst;
    controller._selfControl = evaluation.attitude.selfControl;
    controller._takeInitiative = evaluation.attitude.takeInitiative;
    controller._adaptability = evaluation.attitude.adaptability;

    return controller;
  }

  InternshipEvaluationAttitude toInternshipEvaluation() {
    return InternshipEvaluationAttitude(
      date: evaluationDate,
      presentAtEvaluation: wereAtMeeting,
      attitude: AttitudeEvaluation(
        ponctuality: _ponctuality,
        inattendance: _inattendance,
        qualityOfWork: _qualityOfWork,
        productivity: _productivity,
        teamCommunication: _teamCommunication,
        respectOfAuthority: _respectOfAuthority,
        communicationAboutSst: _communicationAboutSst,
        selfControl: _selfControl,
        takeInitiative: _takeInitiative,
        adaptability: _adaptability,
      ),
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

  Ponctuality _ponctuality = Ponctuality.notEvaluated;
  Ponctuality get ponctuality => _ponctuality;

  Inattendance _inattendance = Inattendance.notEvaluated;
  Inattendance get inattendance => _inattendance;

  QualityOfWork _qualityOfWork = QualityOfWork.notEvaluated;
  QualityOfWork get qualityOfWork => _qualityOfWork;

  Productivity _productivity = Productivity.notEvaluated;
  Productivity get productivity => _productivity;

  TeamCommunication _teamCommunication = TeamCommunication.notEvaluated;
  TeamCommunication get teamCommunication => _teamCommunication;

  RespectOfAuthority _respectOfAuthority = RespectOfAuthority.notEvaluated;
  RespectOfAuthority get respectOfAuthority => _respectOfAuthority;

  CommunicationAboutSst _communicationAboutSst =
      CommunicationAboutSst.notEvaluated;
  CommunicationAboutSst get communicationAboutSst => _communicationAboutSst;

  SelfControl _selfControl = SelfControl.notEvaluated;
  SelfControl get selfControl => _selfControl;

  TakeInitiative _takeInitiative = TakeInitiative.notEvaluated;
  TakeInitiative get takeInitiative => _takeInitiative;

  Adaptability _adaptability = Adaptability.notEvaluated;
  Adaptability get adaptability => _adaptability;

  void setValue(AttitudeCategoryEnum value) {
    switch (value) {
      case Ponctuality value:
        _ponctuality = value;
      case Inattendance value:
        _inattendance = value;
      case QualityOfWork value:
        _qualityOfWork = value;
      case Productivity value:
        _productivity = value;
      case TeamCommunication value:
        _teamCommunication = value;
      case RespectOfAuthority value:
        _respectOfAuthority = value;
      case CommunicationAboutSst value:
        _communicationAboutSst = value;
      case SelfControl value:
        _selfControl = value;
      case TakeInitiative value:
        _takeInitiative = value;
      case Adaptability value:
        _adaptability = value;
    }
  }

  bool get isCompleted =>
      _ponctuality != Ponctuality.notEvaluated &&
      _inattendance != Inattendance.notEvaluated &&
      _qualityOfWork != QualityOfWork.notEvaluated &&
      _productivity != Productivity.notEvaluated;
}

class _AttitudeEvaluationScreen extends StatefulWidget {
  const _AttitudeEvaluationScreen({
    required this.rootContext,
    required this.internshipId,
    required this.evaluationId,
  });

  final BuildContext rootContext;
  final String internshipId;
  final String? evaluationId;

  @override
  State<_AttitudeEvaluationScreen> createState() =>
      _AttitudeEvaluationScreenState();
}

class _AttitudeEvaluationScreenState extends State<_AttitudeEvaluationScreen> {
  bool get _editMode => widget.evaluationId == null;

  late final _formController = _editMode
      ? AttitudeEvaluationFormController(internshipId: widget.internshipId)
      : AttitudeEvaluationFormController.fromInternshipId(context,
          internshipId: widget.internshipId,
          evaluationId: widget.evaluationId!);

  void _cancel() async {
    _logger.info('Cancelling AttitudeEvaluationDialog');
    final answer = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
      isEditing: _editMode,
    );
    if (!mounted || !answer) return;

    _logger.fine('User confirmed cancellation, closing dialog');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(null);
  }

  Future<void> _submit() async {
    _logger.info('Submitting attitude evaluation form');
    if (!_editMode) {
      Navigator.of(widget.rootContext).pop(null);
      return;
    }

    if (!_formController.isCompleted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => const AlertDialog(
          title: Text('Formulaire incomplet'),
          content: Text('Répondre à toutes les questions avec un *.'),
        ),
      );
      return;
    }

    _formController.setWereAtMeeting();

    _logger.fine('Attitude evaluation form submitted successfully');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext)
        .pop(_formController.toInternshipEvaluation());
  }

  Widget _controlBuilder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_editMode)
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: OutlinedButton(
                  onPressed: _cancel, child: const Text('Annuler')),
            ),
          TextButton(
              onPressed: _submit,
              child: Text(_editMode ? 'Enregistrer' : 'Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building AttitudeEvaluationScreen for internship: ${_formController.internshipId}',
    );

    final internship =
        InternshipsProvider.of(context)[_formController.internshipId];
    final student = StudentsHelpers.studentsInMyGroups(
      context,
    ).firstWhereOrNull((e) => e.id == internship.studentId);

    final workingSituations = [
      _formController.ponctuality,
      _formController.inattendance,
      _formController.qualityOfWork,
      _formController.productivity,
    ];
    final relationshipWithOthers = [
      _formController.teamCommunication,
      _formController.respectOfAuthority,
      _formController.communicationAboutSst,
    ];
    final autonomyAndAdaptability = [
      _formController.selfControl,
      _formController.takeInitiative,
      _formController.adaptability,
    ];

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${student == null ? 'En attente des informations' : 'Évaluation de ${student.fullName}'}\nC2. Attitudes - Comportements',
          ),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: student == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _EvaluationDate(
                                formController: _formController,
                                editMode: _editMode),
                            _PersonAtMeeting(
                                formController: _formController,
                                editMode: _editMode),
                            const SubTitle('Situation de travail', left: 0.0),
                            ...workingSituations.asMap().keys.map(
                              (index) {
                                final element = workingSituations[index];
                                return _AttitudeRadioChoices(
                                  title: '${index + 1}. ${element.title}',
                                  definition: element.definition,
                                  groupValue: element,
                                  onValueChanged: (value) => setState(
                                      () => _formController.setValue(value!)),
                                  elements: element.validElements,
                                  editMode: _editMode,
                                );
                              },
                            ),
                            const SubTitle('Relation avec les autres',
                                left: 0.0),
                            ...relationshipWithOthers.asMap().keys.map(
                              (index) {
                                final element = relationshipWithOthers[index];
                                return _AttitudeRadioChoices(
                                  title:
                                      '${index + workingSituations.length + 1}. ${element.title}',
                                  definition: element.definition,
                                  groupValue: element,
                                  onValueChanged: (value) => setState(
                                      () => _formController.setValue(value!)),
                                  elements: element.validElements,
                                  editMode: _editMode,
                                );
                              },
                            ),
                            const SubTitle('Autonomie et adaptabilité',
                                left: 0.0),
                            ...autonomyAndAdaptability.asMap().keys.map(
                              (index) {
                                final element = autonomyAndAdaptability[index];
                                return _AttitudeRadioChoices(
                                  title:
                                      '${index + workingSituations.length + relationshipWithOthers.length + 1}. ${element.title}',
                                  definition: element.definition,
                                  groupValue: element,
                                  onValueChanged: (value) => setState(
                                      () => _formController.setValue(value!)),
                                  elements: element.validElements,
                                  editMode: _editMode,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    _controlBuilder(),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EvaluationDate extends StatefulWidget {
  const _EvaluationDate({required this.formController, required this.editMode});

  final AttitudeEvaluationFormController formController;
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
        const SubTitle('Date de l\'évaluation', left: 0.0),
        Row(
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
      ],
    );
  }
}

class _PersonAtMeeting extends StatelessWidget {
  const _PersonAtMeeting({
    required this.formController,
    required this.editMode,
  });

  final AttitudeEvaluationFormController formController;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Personnes présentes lors de l\'évaluation', left: 0.0),
        CheckboxWithOther(
          controller: formController.wereAtMeetingController,
          enabled: editMode,
        ),
      ],
    );
  }
}

class _AttitudeRadioChoices extends StatefulWidget {
  const _AttitudeRadioChoices({
    required this.title,
    required this.definition,
    required this.groupValue,
    required this.onValueChanged,
    required this.elements,
    required this.editMode,
  });

  final String title;
  final String definition;
  final AttitudeCategoryEnum groupValue;
  final ValueChanged<AttitudeCategoryEnum?> onValueChanged;
  final List<AttitudeCategoryEnum> elements;
  final bool editMode;

  @override
  State<_AttitudeRadioChoices> createState() => _AttitudeRadioChoicesState();
}

class _AttitudeRadioChoicesState extends State<_AttitudeRadioChoices> {
  @override
  Widget build(BuildContext context) {
    return RadioGroup<AttitudeCategoryEnum>(
      groupValue: widget.groupValue,
      onChanged: widget.onValueChanged,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(widget.title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  icon: Icon(Icons.info_rounded,
                      color: widget.groupValue.extraInformation == null
                          ? Colors.transparent
                          : Theme.of(context).primaryColor),
                  onPressed: widget.groupValue.extraInformation == null
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              content:
                                  Text(widget.groupValue.extraInformation!),
                            ),
                          );
                        },
                ),
              ]),
          Flexible(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Définition : ',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  TextSpan(
                    text: '${widget.definition}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          ...widget.elements.map(
            (e) => RadioListTile<AttitudeCategoryEnum>(
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
          SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
