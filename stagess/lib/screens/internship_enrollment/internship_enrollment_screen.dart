import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:stagess/common/widgets/scrollable_stepper.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/router.dart';
import 'package:stagess/screens/internship_enrollment/steps/caracteristics_step.dart';
import 'package:stagess/screens/internship_enrollment/steps/schedule_step.dart';
import 'package:stagess/screens/internship_enrollment/steps/validation_step.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/time_utils.dart'
    as time_utils;
import 'package:stagess_common/models/itineraries/visiting_priority.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('InternshipEnrollmentScreen');

class InternshipEnrollmentScreen extends StatefulWidget {
  const InternshipEnrollmentScreen({
    super.key,
    required this.enterprise,
    this.specifiedSpecialization,
  });

  static const route = '/internship-enrollment';
  final Enterprise enterprise;
  final Specialization? specifiedSpecialization;

  @override
  State<InternshipEnrollmentScreen> createState() =>
      _InternshipEnrollmentScreenState();
}

class _InternshipEnrollmentScreenState
    extends State<InternshipEnrollmentScreen> {
  final _scrollController = ScrollController();

  final _caracteristicsKey = GlobalKey<CaracteristicsStepState>();
  final _scheduleKey = GlobalKey<ScheduleStepState>();

  int _currentStep = 0;
  final List<StepState> _stepStatus = [
    StepState.indexed,
    StepState.indexed,
    StepState.indexed,
  ];

  void _showInvalidFieldsSnakBar([String? message]) {
    ScaffoldMessenger.of(context).clearSnackBars();
    showSnackBar(
      context,
      message: message ?? 'Remplir tous les champs avec un *.',
    );
  }

  void _previousStep() {
    _logger.finer('Going to previous step: $_currentStep');

    if (_currentStep == 0) return;
    _currentStep -= 1;
    _scrollController.jumpTo(0);
    setState(() {});
  }

  void _nextStep() async {
    _logger.finer('Going to next step: $_currentStep');

    bool areAllValid = true;
    if (_currentStep >= 0) {
      final isValid = FormService.validateForm(
        _caracteristicsKey.currentState!.formKey,
      );
      areAllValid = areAllValid && isValid;
      _stepStatus[0] = isValid ? StepState.complete : StepState.error;
    }
    if (_currentStep >= 1) {
      final isValid = FormService.validateForm(
        _scheduleKey.currentState!.formKey,
      );
      areAllValid = areAllValid && isValid;
      _stepStatus[1] = isValid ? StepState.complete : StepState.error;
    }
    setState(() {});

    if (!areAllValid) {
      _showInvalidFieldsSnakBar();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    if (_currentStep == 2) {
      return await _submit();
    } else {
      _currentStep += 1;
      _scrollController.jumpTo(0);
      setState(() {});
      return;
    }
  }

  Future<void> _submit() async {
    // Submit
    _logger.info('Submitting internship enrollment form');
    _caracteristicsKey.currentState!.formKey.currentState!.save();
    _scheduleKey.currentState!.formKey.currentState!.save();

    final internship = _newInternship;
    if (internship == null) {
      _logger.warning('Failed to create internship, missing data.');
      showSnackBar(context, message: 'Remplir tous les champs.');
      return;
    }

    InternshipsProvider.of(context, listen: false).add(internship);
    final enterprise = EnterprisesProvider.of(
      context,
      listen: false,
    ).fromId(internship.enterpriseId);

    final student = StudentsHelpers.studentsInMyGroups(
      context,
      listen: false,
    ).firstWhere((e) => e.id == _caracteristicsKey.currentState!.student!.id);
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const SubTitle('Inscription réussie', left: 0, bottom: 0),
            content: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${student.fullName} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: ' a bien été inscrit comme stagiaire chez ',
                  ),
                  TextSpan(
                    text: enterprise.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text:
                        '.\n\nVous pouvez maintenant accéder au contrat de stage dans la section "Documents".',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ok'),
              ),
            ],
          ),
    );

    _logger.finer('Internship enrollment form submitted successfully');
    if (!mounted) return;
    Navigator.pop(context);
    GoRouter.of(context).pushNamed(
      Screens.student,
      pathParameters: Screens.params(internship.studentId),
      queryParameters: Screens.queryParams(pageIndex: '1'),
    );
  }

  Internship? get _newInternship {
    final enterprise =
        _caracteristicsKey.currentState == null
            ? null
            : EnterprisesProvider.of(
              context,
              listen: false,
            ).fromIdOrNull(_caracteristicsKey.currentState!.enterprise.id);
    if (enterprise == null) return null;

    final signatoryTeacher =
        TeachersProvider.of(context, listen: false).currentTeacher;
    if (signatoryTeacher == null) {
      showSnackBar(
        context,
        message:
            'Vous devez être connecté en tant qu\'enseignant pour inscrire un stagiaire.',
      );
      return null;
    }

    final schoolBoard =
        SchoolBoardsProvider.of(context, listen: false).currentSchoolBoard;
    if (schoolBoard == null) return null;

    return Internship(
      schoolBoardId: schoolBoard.id,
      creationDate: DateTime.now(),
      studentId: _caracteristicsKey.currentState!.student!.id,
      signatoryTeacherId: signatoryTeacher.id,
      extraSupervisingTeacherIds: [],
      enterpriseId: _caracteristicsKey.currentState!.enterprise.id,
      jobId:
          enterprise.jobs
              .firstWhere(
                (job) =>
                    job.specialization ==
                    _caracteristicsKey
                        .currentState!
                        .primaryJobController
                        .job
                        .specialization,
              )
              .id,
      extraSpecializationIds:
          _caracteristicsKey.currentState!.extraJobControllers
              .map<String>((e) => e.job.specializationOrNull?.id ?? '')
              .where((e) => e.isNotEmpty)
              .toList(),
      supervisor: Person(
        firstName: _caracteristicsKey.currentState!.supervisorFirstName ?? '',
        middleName: null,
        lastName: _caracteristicsKey.currentState!.supervisorLastName ?? '',
        dateBirth: null,
        email: _caracteristicsKey.currentState!.supervisorEmail ?? '',
        address: Address.empty,
        phone:
            _caracteristicsKey.currentState?.supervisorPhone == null
                ? null
                : PhoneNumber.fromString(
                  _caracteristicsKey.currentState!.supervisorPhone,
                ),
      ),
      dates:
          _scheduleKey.currentState?.weeklyScheduleController.dateRange ??
          time_utils.DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 30)),
          ),
      expectedDuration: _scheduleKey.currentState?.internshipDuration ?? -1,
      achievedDuration: -1,
      endDate: DateTime(0),
      weeklySchedules:
          _scheduleKey.currentState?.weeklyScheduleController.weeklySchedules ??
          [],
      transportations: _caracteristicsKey.currentState?.transportations ?? [],
      visitFrequencies: _scheduleKey.currentState?.visitFrequencies ?? '',
      visitingPriority: VisitingPriority.low,
    );
  }

  void _cancel() async {
    _logger.info('Canceling internship enrollment form');
    final navigator = Navigator.of(context);
    final answer = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
    );
    if (!mounted || !answer) return;

    _logger.finer('Internship enrollment form canceled');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building InternshipEnrollmentScreen for enterprise: ${widget.enterprise.id}',
    );

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Inscrire un stagiaire chez${ResponsiveService.getScreenSize(context) == ScreenSize.small ? '\n' : ' '}'
            '${widget.enterprise.name}',
          ),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: PopScope(
          child: ScrollableStepper(
            type: StepperType.horizontal,
            scrollController: _scrollController,
            currentStep: _currentStep,
            onTapContinue: _nextStep,
            onStepTapped: (int tapped) {
              setState(() {
                _currentStep = tapped;
                _scrollController.jumpTo(0);
              });
            },
            onTapCancel: _cancel,
            steps: [
              Step(
                state: _stepStatus[0],
                isActive: _currentStep == 0,
                title: const Text('Caractéristiques'),
                content: CaracteristicsStep(
                  key: _caracteristicsKey,
                  enterprise: widget.enterprise,
                  specifiedSpecialization:
                      widget.specifiedSpecialization == null
                          ? null
                          : [widget.specifiedSpecialization!],
                ),
              ),
              Step(
                state: _stepStatus[1],
                isActive: _currentStep == 1,
                title: const Text('Horaire'),
                content: ScheduleStep(key: _scheduleKey),
              ),
              Step(
                state: _stepStatus[2],
                isActive: _currentStep == 2,
                title: const Text('Validation des\ninformations'),
                content: ValidationStep(
                  internship: _newInternship,
                  weeklySchedulesController:
                      _scheduleKey.currentState?.weeklyScheduleController,
                ),
              ),
            ],
            controlsBuilder: _controlBuilder,
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
            child: Text(
              _currentStep == 2
                  ? 'Valider'
                  : _currentStep == 1
                  ? 'Enregistrer'
                  : 'Suivant',
            ),
          ),
        ],
      ),
    );
  }
}
