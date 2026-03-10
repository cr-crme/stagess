import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/enterprise_extension.dart';
import 'package:stagess/common/extensions/students_extension.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/add_job_button.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_contract.dart';
import 'package:stagess_common/models/internships/time_utils.dart'
    as time_utils;
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/enterprise_job_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/schedule_selector.dart';
import 'package:stagess_common_flutter/widgets/student_picker_tile.dart';

final _logger = Logger('InternshipManagingContractFormDialog');

Future<Internship?> showManagingContractFormDialog(
  BuildContext context, {
  required bool isNewContract,
  required Internship internship,
  String? evaluationId,
}) async {
  return await showDialog<Internship>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (ctx) => Dialog(
          child: _InternshipDetailsScreen(
            rootContext: context,
            isNewContract: isNewContract,
            internship: internship,
            contractId: evaluationId,
          ),
        ),
      ),
    ),
  );
}

class InternshipContractFormController {
  final bool isNewContract;
  final bool canModify;

  final Internship internship;
  final String? contractId;
  Program get program => canModify
      ? (_studentController.student!.program)
      : _previousContract?.program ?? Program.undefined;
  InternshipContract? get _previousContract => contractId == null
      ? (internship.currentContract)
      : internship.contracts.firstWhereOrNull((e) => e.id == contractId);

  DateTime creationDate = DateTime.now();

  StudentPickerController _studentController;

  late final _weeklySchedulesController = WeeklySchedulesController(
    weeklySchedules: _previousContract?.weeklySchedules,
    dateRange: _previousContract?.dates,
    keepId: false,
  );
  late final _transportationsController =
      CheckboxWithOtherController<Transportation>(
          elements: Transportation.values,
          initialValues: [
        ...?_previousContract?.transportations.map((e) => e.toString()),
      ]);

  final EnterpriseJobListController _primaryJobController;
  final List<EnterpriseJobListController> _extraJobControllers;

  late final _superviserFirstNameController = TextEditingController(
      text: _previousContract?.supervisor.firstName ?? '');
  late final _supervisorLastNameController =
      TextEditingController(text: _previousContract?.supervisor.lastName ?? '');
  late final _supervisorPhoneController = TextEditingController(
      text: _previousContract?.supervisor.phone.toString() ?? '');
  late final _supervisorEmailController =
      TextEditingController(text: _previousContract?.supervisor.email ?? '');

  Person get _supervisor => Person(
        id: null,
        firstName: _superviserFirstNameController.text,
        middleName: null,
        lastName: _supervisorLastNameController.text,
        phone: PhoneNumber.fromString(_supervisorPhoneController.text),
        email: _supervisorEmailController.text,
        address: null,
        dateBirth: null,
      );

  late final _visitFrequenciesController =
      TextEditingController(text: _previousContract?.visitFrequencies ?? '');

  late final _internshipDurationController = TextEditingController(
      text: (_previousContract?.expectedDuration ?? -1) >= 0
          ? _previousContract?.expectedDuration.toString()
          : '');
  int get internshipDuration =>
      int.tryParse(_internshipDurationController.text) ?? 0;

  InternshipContractFormController(
    BuildContext context, {
    required this.isNewContract,
    required this.canModify,
    required this.internship,
    required this.contractId,
  })  : _studentController =
            _studentPickerControllerOf(context, internship: internship),
        _primaryJobController =
            _jobListControllerOf(context, internship: internship),
        _extraJobControllers = (contractId == null
                    ? (internship.currentContract)
                    : internship.contracts
                        .firstWhereOrNull((e) => e.id == contractId))
                ?.extraSpecializationIds
                .map((id) => _jobListControllerOfSpecialization(context,
                    specializationId: id))
                .toList() ??
            [] {
    if (program != Program.fpt) _extraJobControllers.clear();
  }

  factory InternshipContractFormController.fromInternshipId(
    BuildContext context, {
    required bool isNewContract,
    required bool canModify,
    required Internship internship,
    required String contractId,
  }) {
    InternshipContract contract =
        internship.contracts.firstWhereOrNull((e) => e.id == contractId) ??
            InternshipContract.empty;

    final controller = InternshipContractFormController(
      context,
      isNewContract: isNewContract,
      canModify: canModify,
      internship: internship,
      contractId: contractId,
    );

    controller.creationDate = contract.date;

    return controller;
  }

  InternshipContract toContract() {
    return InternshipContract(
      date: creationDate,
      supervisor: _supervisor,
      jobId: _primaryJobController.job.id,
      extraSpecializationIds:
          _extraJobControllers.map((e) => e.job.specialization.id).toList(),
      program: program,
      dates: _weeklySchedulesController.dateRange!,
      weeklySchedules: _weeklySchedulesController.weeklySchedules,
      transportations: _transportationsController.values,
      visitFrequencies: _visitFrequenciesController.text,
      expectedDuration: internshipDuration,
      formVersion: InternshipContract.currentVersion,
    );
  }

  void dispose() {
    _studentController.dispose();
    _primaryJobController.dispose();
    for (final controller in _extraJobControllers) {
      controller.dispose();
    }
    _superviserFirstNameController.dispose();
    _supervisorLastNameController.dispose();
    _supervisorPhoneController.dispose();
    _supervisorEmailController.dispose();

    _internshipDurationController.dispose();
    _visitFrequenciesController.dispose();

    _weeklySchedulesController.dispose();
  }
}

class _InternshipDetailsScreen extends StatefulWidget {
  const _InternshipDetailsScreen({
    required this.rootContext,
    required this.isNewContract,
    required this.internship,
    required this.contractId,
  });

  final BuildContext rootContext;
  final bool isNewContract;
  final Internship internship;
  final String? contractId;

  @override
  State<_InternshipDetailsScreen> createState() =>
      _InternshipDetailsScreenState();
}

class _InternshipDetailsScreenState extends State<_InternshipDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _editMode => widget.contractId == null;

  late final _controller = _editMode
      ? InternshipContractFormController(
          context,
          isNewContract: widget.isNewContract,
          canModify: true,
          internship: widget.internship,
          contractId: widget.contractId,
        )
      : InternshipContractFormController.fromInternshipId(
          context,
          isNewContract: widget.isNewContract,
          canModify: false,
          internship: widget.internship,
          contractId: widget.contractId!,
        );

  void _cancel() async {
    _logger.info('Cancelling InternshipDetailsDialog');
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
    _logger.info('Submitting internship contract form');
    if (!_editMode) {
      Navigator.of(widget.rootContext).pop(null);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    _logger.fine('Internship contract form submitted successfully');
    if (!widget.rootContext.mounted) return;
    if (!_editMode) {
      Navigator.of(widget.rootContext).pop(null);
      return;
    }

    final newContract = _controller.toContract();
    final previousContract = widget.internship.contracts.lastOrNull;
    final contractDifferences = newContract
        .getDifference(previousContract, ignoreKeys: ['id'])
      ..removeWhere((element) => element == 'date'); // Date is always different

    // Prepare the new internship
    if (contractDifferences.isEmpty) {
      _logger.fine(
          'No changes detected in internship, not returning updated internship');
      Navigator.of(widget.rootContext).pop(null);
      return;
    }

    Internship newInternship =
        Internship.fromSerialized(widget.internship.serialize())
          ..contracts.add(newContract);

    if (widget.isNewContract) {
      final student = _controller._studentController.student;
      final schoolBoard =
          SchoolBoardsProvider.of(context, listen: false).currentSchoolBoard;
      final school = schoolBoard?.schools
          .firstWhereOrNull((s) => s.id == student?.schoolId);
      final teacherId = AuthProvider.of(context).teacherId;
      final enterprise = EnterprisesProvider.of(context, listen: false)
          .fromIdOrNull(_controller.internship.enterpriseId);
      if (student == null ||
          teacherId == null ||
          schoolBoard == null ||
          school == null ||
          enterprise == null) {
        _logger.severe(
            'Cannot create internship with missing student, teacher, or school information');
        Navigator.of(widget.rootContext).pop(null);
        return;
      }
      newInternship = newInternship.copyWith(
        schoolBoardId: schoolBoard.id,
        studentId: student.id,
        signatoryTeacherId: teacherId,
        enterpriseId: enterprise.id,
      );
    }
    Navigator.of(widget.rootContext).pop(newInternship);
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building InternshipContractScreen for internship: ${_controller.internship.id}, editMode: $_editMode',
    );
    final enterprise = EnterprisesProvider.of(context, listen: false)
        .fromId(_controller.internship.enterpriseId);
    final studentName = _controller._studentController.student?.fullName;
    final linebreak =
        ResponsiveService.getScreenSize(context) == ScreenSize.small
            ? '\n'
            : ' ';

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _controller.isNewContract
                ? 'Inscrire un stagiaire${linebreak}chez ${enterprise.name}'
                : 'Contrat de stage de $studentName${linebreak}chez ${enterprise.name}',
          ),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CreationDate(
                            controller: _controller, editMode: _editMode),
                        _GeneralInformations(
                            controller: _controller, setState: setState),
                        _MainJob(controller: _controller),
                        if (_controller.program == Program.fpt)
                          _ExtraSpecialization(
                            controller: _controller,
                            setState: setState,
                          ),
                        _SupervisonInformation(controller: _controller),
                        _TransportationsCheckBoxes(controller: _controller),
                        _SchedulePicker(controller: _controller),
                      ],
                    ),
                  ),
                ),
                _controlBuilder(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreationDate extends StatefulWidget {
  const _CreationDate({required this.controller, required this.editMode});

  final InternshipContractFormController controller;
  final bool editMode;

  @override
  State<_CreationDate> createState() => _CreationDateState();
}

class _CreationDateState extends State<_CreationDate> {
  void _promptDate(BuildContext context) async {
    final newDate = await showCustomDatePicker(
      helpText: 'Sélectionner la date',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      context: context,
      initialDate: widget.controller.creationDate,
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (newDate == null) return;

    widget.controller.creationDate = newDate;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Date de création du contrat', left: 0.0),
        Row(
          children: [
            Text(
              DateFormat(
                'dd MMMM yyyy',
                'fr_CA',
              ).format(widget.controller.creationDate),
            ),
            if (widget.editMode)
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.blue,
                ),
                onPressed: () => _promptDate(context),
              )
            else
              const SizedBox(height: 36.0),
          ],
        ),
      ],
    );
  }
}

class _GeneralInformations extends StatelessWidget {
  const _GeneralInformations({
    required this.controller,
    required this.setState,
  });
  final InternshipContractFormController controller;

  final Function(Function()) setState;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building _GeneralInformations with selected student: ${controller._studentController.student?.id}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Stagiaire', left: 0, top: 0),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentPickerTile(
                controller: controller._studentController,
                editMode: controller.isNewContract,
                onSelected: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MainJob extends StatelessWidget {
  const _MainJob({required this.controller});

  final InternshipContractFormController controller;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building _MainJob with controller job: ${controller._primaryJobController.job.id}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Métier', left: 0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller._extraJobControllers.isNotEmpty)
              Text(
                'Métier principal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            EnterpriseJobListTile(
              controller: controller._primaryJobController,
              schools: [
                SchoolBoardsProvider.of(context, listen: false).currentSchool!,
              ],
              editMode: controller.isNewContract,
              specializationOnly: true,
              canChangeExpandedState: false,
              initialExpandedState: true,
              elevation: 0.0,
              jobPickerPadding: const EdgeInsets.only(
                left: 8,
                top: 12,
                right: 24,
              ),
              showHeader: false,
            ),
          ],
        ),
      ],
    );
  }
}

class _ExtraSpecialization extends StatelessWidget {
  const _ExtraSpecialization({
    required this.controller,
    required this.setState,
  });

  final InternshipContractFormController controller;
  final Function(void Function()) setState;

  Widget _extraJobTileBuilder(BuildContext context, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Métier supplémentaire ${index + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (controller.canModify)
              SizedBox(
                width: 35,
                height: 35,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => setState(
                      () => controller._extraJobControllers.removeAt(index)),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
              ),
          ],
        ),
        EnterpriseJobListTile(
          controller: controller._extraJobControllers[index],
          schools: [
            SchoolBoardsProvider.of(context, listen: false).currentSchool!,
          ],
          editMode: controller.isNewContract || controller.canModify,
          specializationOnly: true,
          canChangeExpandedState: false,
          initialExpandedState: true,
          elevation: 0.0,
          jobPickerPadding: const EdgeInsets.only(left: 8, top: 12, right: 24),
          showHeader: false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building _ExtraSpecialization with ${controller._extraJobControllers.length} controllers',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...controller._extraJobControllers.asMap().keys.map<Widget>(
              (i) => Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: _extraJobTileBuilder(context, i),
              ),
            ),
        controller.canModify
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Besoin d\'ajouter des compétences d\'un autre métier pour ce stage?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AddJobButton(
                    controllers: controller._extraJobControllers,
                    onJobAdded: () => setState(() {}),
                    style: Theme.of(context).textButtonTheme.style!.copyWith(
                          backgroundColor: Theme.of(context)
                              .elevatedButtonTheme
                              .style!
                              .backgroundColor,
                        ),
                  ),
                ],
              )
            : Container(),
      ],
    );
  }
}

class _SupervisonInformation extends StatefulWidget {
  const _SupervisonInformation({required this.controller});

  final InternshipContractFormController controller;

  @override
  State<_SupervisonInformation> createState() => _SupervisonInformationState();
}

class _SupervisonInformationState extends State<_SupervisonInformation> {
  late bool _useContactInfo = widget.controller._supervisor.getDifference(
      EnterprisesProvider.of(context, listen: false)
          .fromId(widget.controller.internship.enterpriseId)
          .contact,
      ignoreKeys: ['id', 'address']).isEmpty;

  void _toggleUseContactInfo() {
    final enterprise = EnterprisesProvider.of(context, listen: false)
        .fromId(widget.controller.internship.enterpriseId);

    _useContactInfo = !_useContactInfo;
    if (_useContactInfo) {
      widget.controller._superviserFirstNameController.text =
          enterprise.contact.firstName;
      widget.controller._supervisorLastNameController.text =
          enterprise.contact.lastName;
      widget.controller._supervisorPhoneController.text =
          enterprise.contact.phone.toString();
      widget.controller._supervisorEmailController.text =
          enterprise.contact.email ?? '';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final enterprise = EnterprisesProvider.of(context, listen: false)
        .fromId(widget.controller.internship.enterpriseId);

    _logger.finer(
      'Building _SupervisionInformation for enterprise: ${enterprise.id} '
      'and contact id: ${enterprise.contact.id}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Responsable en milieu de stage', left: 0),
        if (widget.controller.canModify)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Même personne que le contact de l\'entreprise',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Switch(
                onChanged: (newValue) => _toggleUseContactInfo(),
                value: _useContactInfo,
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller:
                        widget.controller._superviserFirstNameController,
                    decoration: const InputDecoration(
                      labelText: '* Prénom',
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    validator: (text) =>
                        text!.isEmpty ? 'Ajouter un prénom.' : null,
                    enabled: !_useContactInfo && widget.controller.canModify,
                  ),
                  TextFormField(
                    controller: widget.controller._supervisorLastNameController,
                    decoration: const InputDecoration(
                      labelText: '* Nom de famille',
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    validator: (text) =>
                        text!.isEmpty ? 'Ajouter un nom de famille.' : null,
                    enabled: !_useContactInfo && widget.controller.canModify,
                  ),
                ],
              ),
              PhoneListTile(
                controller: widget.controller._supervisorPhoneController,
                isMandatory: true,
                canCall: false,
                enabled: !_useContactInfo && widget.controller.canModify,
              ),
              EmailListTile(
                controller: widget.controller._supervisorEmailController,
                isMandatory: true,
                enabled: !_useContactInfo && widget.controller.canModify,
                canMail: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransportationsCheckBoxes extends StatelessWidget {
  const _TransportationsCheckBoxes({required this.controller});

  final InternshipContractFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Transport de l\'élève vers l\'entreprise', left: 0),
        CheckboxWithOther(
          controller: controller._transportationsController,
          enabled: controller.canModify,
        ),
      ],
    );
  }
}

class _SchedulePicker extends StatefulWidget {
  const _SchedulePicker({required this.controller});

  final InternshipContractFormController controller;

  @override
  State<_SchedulePicker> createState() => _SchedulePickerState();
}

class _SchedulePickerState extends State<_SchedulePicker> {
  void onScheduleChanged() {
    if (widget.controller._weeklySchedulesController.dateRange != null) {
      widget.controller._weeklySchedulesController.addWeeklySchedule(
          WeeklySchedulesController.fillNewScheduleList(
              schedule: widget.controller._weeklySchedulesController
                      .weeklySchedules.isEmpty
                  ? {}
                  : widget.controller._weeklySchedulesController.weeklySchedules
                      .last.schedule,
              periode:
                  widget.controller._weeklySchedulesController.dateRange!));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building ScheduleStep widget');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateRange(
          controller: widget.controller,
          onScheduleChanged: onScheduleChanged,
        ),
        Visibility(
            visible:
                widget.controller._weeklySchedulesController.dateRange != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SubTitle('Horaire du stage', left: 0),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ScheduleSelector(
                    scheduleController:
                        widget.controller._weeklySchedulesController,
                    editMode: widget.controller.canModify,
                  ),
                ),
                _Hours(controller: widget.controller),
                _VisitFrequencies(controller: widget.controller),
              ],
            )),
      ],
    );
  }
}

class _DateRange extends StatefulWidget {
  const _DateRange({required this.controller, required this.onScheduleChanged});

  final InternshipContractFormController controller;
  final Function() onScheduleChanged;

  @override
  State<_DateRange> createState() => _DateRangeState();
}

class _DateRangeState extends State<_DateRange> {
  bool _isValid = true;

  Future<void> _promptDateRange(BuildContext context) async {
    final range = await showCustomDateRangePicker(
      helpText: 'Sélectionner les dates',
      saveText: 'Confirmer',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      context: context,
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDateRange:
          widget.controller._weeklySchedulesController.dateRange ??
              time_utils.DateTimeRange(
                start: DateTime.now(),
                end: DateTime.now().add(const Duration(days: 90)),
              ),
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (range == null) return;

    _isValid = true;
    widget.controller._weeklySchedulesController.dateRange = range;

    widget.onScheduleChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Dates de stage', top: 0, left: 0),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.controller.canModify)
                Row(
                  children: [
                    FormField<void>(
                      validator: (value) {
                        if (widget.controller._weeklySchedulesController
                                .dateRange ==
                            null) {
                          _isValid = false;
                          setState(() {});
                          return 'Nope';
                        } else {
                          _isValid = true;
                          setState(() {});
                          return null;
                        }
                      },
                      builder: (state) => Text(
                        '* Sélectionner les dates',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: _isValid ? Colors.black : Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.blue,
                      ),
                      onPressed: () async {
                        await _promptDateRange(context);
                        setState(() {});
                      },
                    )
                  ],
                ),
              Visibility(
                visible:
                    widget.controller._weeklySchedulesController.dateRange !=
                        null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 180,
                      child: TextField(
                        decoration: const InputDecoration(
                            labelText: 'Date de début',
                            labelStyle: TextStyle(color: Colors.black),
                            border: InputBorder.none),
                        style: TextStyle(color: Colors.black),
                        controller: TextEditingController(
                            text: widget.controller._weeklySchedulesController
                                        .dateRange ==
                                    null
                                ? null
                                : DateFormat.yMMMEd('fr_CA').format(widget
                                    .controller
                                    ._weeklySchedulesController
                                    .dateRange!
                                    .start)),
                        enabled: false,
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        decoration: const InputDecoration(
                            labelText: 'Date de fin',
                            labelStyle: TextStyle(color: Colors.black),
                            border: InputBorder.none),
                        style: TextStyle(color: Colors.black),
                        controller: TextEditingController(
                            text: widget.controller._weeklySchedulesController
                                        .dateRange ==
                                    null
                                ? null
                                : DateFormat.yMMMEd('fr_CA').format(widget
                                    .controller
                                    ._weeklySchedulesController
                                    .dateRange!
                                    .end)),
                        enabled: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hours extends StatelessWidget {
  const _Hours({required this.controller});

  final InternshipContractFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Nombre d\'heures', left: 0, bottom: 0),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: TextFormField(
            controller: controller._internshipDurationController,
            enabled: controller.canModify,
            decoration: const InputDecoration(
              labelText: '* Nombre total d\'heures de stage à faire',
              labelStyle: TextStyle(color: Colors.black),
            ),
            style: TextStyle(color: Colors.black),
            validator: (text) =>
                text!.isEmpty ? 'Indiquer un nombre d\'heures.' : null,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}

class _VisitFrequencies extends StatelessWidget {
  const _VisitFrequencies({required this.controller});

  final InternshipContractFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Visites de supervision', left: 0, bottom: 0),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: TextFormField(
            controller: controller._visitFrequenciesController,
            enabled: controller.canModify,
            decoration: const InputDecoration(
              labelText: 'Fréquence des visites de l\'enseignant\u00b7e',
              labelStyle: TextStyle(color: Colors.black),
            ),
            style: TextStyle(color: Colors.black),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}

List<Student> _studentsWithoutInternship(
    BuildContext context, List<Student> students) {
  final List<Student> out = [];
  for (final student in students) {
    if (!student.hasActiveInternship(context)) out.add(student);
  }

  return out;
}

StudentPickerController _studentPickerControllerOf(BuildContext context,
    {required Internship internship}) {
  final student = StudentsProvider.of(context, listen: false)
      .fromIdOrNull(internship.studentId);
  List<Student> myStudents = student != null
      ? [student]
      : _studentsWithoutInternship(
          context, StudentsHelpers.studentsInMyGroups(context));

  return StudentPickerController(
    schoolBoardId: AuthProvider.of(context, listen: false).schoolBoardId!,
    studentWhiteList: myStudents,
    initial: student,
  );
}

EnterpriseJobListController _jobListControllerOf(BuildContext context,
    {required Internship internship}) {
  final enterprise = EnterprisesProvider.of(context, listen: false)
      .fromIdOrNull(internship.enterpriseId);

  return EnterpriseJobListController(
    context: context,
    enterpriseStatus: EnterpriseStatus.active,
    job: internship.currentContract == null
        ? (enterprise?.availablejobs(context).length == 1
            ? enterprise!.availablejobs(context).first
            : Job.empty)
        : (enterprise?.jobs.firstWhereOrNull(
                (job) => job.id == internship.currentContract!.jobId) ??
            Job.empty),
    specializationWhiteList: enterprise
        ?.jobsWithRemainingPositions(
          context,
          schoolId: AuthProvider.of(context, listen: false).schoolId!,
          listen: false,
        )
        .map((job) => job.specialization)
        .toList(),
  );
}

EnterpriseJobListController _jobListControllerOfSpecialization(
    BuildContext context,
    {required String specializationId}) {
  final specialization =
      ActivitySectorsService.specializationOrNull(specializationId)!;
  return EnterpriseJobListController(
    context: context,
    enterpriseStatus: EnterpriseStatus.active,
    job: Job.empty.copyWith(specialization: specialization),
  );
}
