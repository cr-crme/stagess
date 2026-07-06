import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stagess_admin/screens/internships/confirm_delete_internship_dialog.dart';
import 'package:stagess_admin/screens/internships/schedule_list_tile.dart';
import 'package:stagess_admin/widgets/enterprise_picker_tile.dart';
import 'package:stagess_admin/widgets/section_divider.dart';
import 'package:stagess_admin/widgets/teacher_picker_tile.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_contract.dart';
import 'package:stagess_common/models/internships/internship_evaluation.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/configuration_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/add_job_button.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/dialogs/finalize_internship_dialog.dart';
import 'package:stagess_common_flutter/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/forms/attitude_evaluation_form_dialog.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/forms/enterprise_evaluation_form_dialog.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/forms/internship_managing_contract_form_dialog.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/forms/show_forms.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/forms/skill_evaluation_form_dialog.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/forms/sst_evaluation_form_dialog.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/pdf/evaluation_attitude_pdf_template.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/pdf/evaluation_enterprise_pdf_template.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/pdf/evaluation_skill_pdf_template.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/pdf/evaluation_sst_pdf_template.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/pdf/internship_contract_pdf_template.dart';
import 'package:stagess_common_flutter/widgets/jobs_expansion_panels/enterprise_job_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/schedule_selector.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';
import 'package:stagess_common_flutter/widgets/student_picker_tile.dart';

class InternshipListTile extends StatefulWidget {
  const InternshipListTile({
    super.key,
    required this.schoolBoardId,
    required this.internship,
    this.forceEditingMode = false,
    required this.canEdit,
    required this.canDelete,
  });

  final String schoolBoardId;
  final Internship internship;
  final bool forceEditingMode;
  final bool canEdit;
  final bool canDelete;

  @override
  State<InternshipListTile> createState() => InternshipListTileState();
}

class InternshipListTileState extends State<InternshipListTile> {
  final _formKey = GlobalKey<FormState>();
  Future<bool> validate() async {
    // We do both like so, so all the fields get validated even if one is not valid
    bool isValid = _formKey.currentState?.validate() ?? false;
    return isValid;
  }

  @override
  void dispose() {
    _studentPickerController.dispose();
    _teacherPickerController.dispose();
    _enterprisePickerController.dispose();
    _visitFrequenciesController.dispose();
    _teacherNotesController.dispose();
    _contactFirstNameController.dispose();
    _contactLastNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _expectedDurationController.dispose();
    _achievedDurationController.dispose();
    _weeklySchedulesController.dispose();
    super.dispose();
  }

  var _fetchFullDataCompleter = Completer<void>();
  bool _isExpanded = false;
  bool _forceDisabled = false;
  bool _isEditing = false;

  late final _studentPickerController = StudentPickerController(
    schoolBoardId: widget.schoolBoardId,
    initial: context.mounted
        ? StudentsProvider.of(
            context,
            listen: false,
          ).firstWhereOrNull(
            (student) => student.id == widget.internship.studentId)
        : null,
  );
  late final _teacherPickerController = TeacherPickerController(
    initial: context.mounted
        ? TeachersProvider.of(context, listen: false).firstWhereOrNull(
            (teacher) =>
                teacher.id ==
                (widget.forceEditingMode
                    ? AuthProvider.of(context).currentId
                    : widget.internship.signatoryTeacherId),
          )
        : null,
  );
  late final _extraTeachersPickerController = widget
      .internship.extraSupervisingTeacherIds
      .map((teacherId) => TeacherPickerController(
            initial: context.mounted
                ? TeachersProvider.of(context, listen: false).firstWhereOrNull(
                    (teacher) => teacher.id == teacherId,
                  )
                : null,
          ))
      .toList();
  late final _enterprisePickerController = EnterprisePickerController(
    initialEnterprise: EnterprisesProvider.of(
      context,
      listen: false,
    ).firstWhereOrNull(
      (enterprise) => enterprise.id == widget.internship.enterpriseId,
    ),
    initialSelectedSpecializationId:
        widget.internship.currentContract?.specializationId,
  );

  late final List<EnterpriseJobListController> _extraJobControllers = widget
          .internship.currentContract?.extraSpecializationIds
          .map((specializationId) => EnterpriseJobListController(
              context: context,
              enterpriseStatus: EnterpriseStatus.active,
              job: Job.empty.copyWith(
                  specialization: ActivitySectorsService.specializationOrNull(
                      specializationId)!)))
          .toList() ??
      [];

  late final _contactFirstNameController = TextEditingController(
    text: widget.internship.currentContract?.supervisor.firstName ?? '',
  );
  late final _contactLastNameController = TextEditingController(
    text: widget.internship.currentContract?.supervisor.lastName ?? '',
  );
  late final _contactPhoneController = TextEditingController(
    text: widget.internship.currentContract?.supervisor.phone.toString() ?? '',
  );
  late final _contactEmailController = TextEditingController(
    text: widget.internship.currentContract?.supervisor.email ?? '',
  );
  late bool _useContactInfo = _editedSupervisor.getDifference(
      _enterprisePickerController.enterprise.contact,
      ignoreKeys: ['id', 'address']).isEmpty;

  late final _weeklySchedulesController = WeeklySchedulesController(
    dateRange: widget.internship.currentContract?.dates,
    dayCycle: widget
        .internship.currentContract?.weeklySchedules.firstOrNull?.dayCycle,
    weeklySchedules: widget.internship.currentContract?.weeklySchedules,
    keepId: false,
  );
  late final _expectedDurationController = TextEditingController(
    text: (widget.internship.currentContract?.expectedDuration ?? -1) > 0
        ? widget.internship.currentContract?.expectedDuration.toString()
        : '',
  );
  late final _transportations = CheckboxWithOtherController<Transportation>(
      elements: Transportation.values,
      initialValues: [
        ...widget.internship.currentContract?.transportations ?? []
      ]);
  late final _visitFrequenciesController = TextEditingController(
    text: widget.internship.currentContract?.visitFrequencies ?? '',
  );
  late DateTime _endDate = widget.internship.endDate;
  bool get _isActive => _endDate == DateTime(0);
  late final _achievedDurationController = TextEditingController(
    text: widget.internship.achievedDuration > 0
        ? widget.internship.achievedDuration.toString()
        : '',
  );
  late final _teacherNotesController = TextEditingController(
    text: widget.internship.teacherNotes,
  );

  Internship get editedInternship {
    final lastContract =
        widget.internship.currentContract ?? InternshipContract.empty;
    final newContract = InternshipContract(
      date: DateTime.now(),
      jobId: _enterprisePickerController.job.id,
      specializationId: _enterprisePickerController.job.specialization.id,
      extraSpecializationIds: _extraJobControllers
          .map((controller) => controller.job.specialization.id)
          .toList(),
      program: _studentPickerController.student?.program ?? Program.undefined,
      supervisor: _editedSupervisor,
      dates: _weeklySchedulesController.dateRange!,
      weeklySchedules: InternshipHelpers.copySchedules(
        _weeklySchedulesController.weeklySchedules,
        keepId: false,
      ),
      transportations: _transportations.values,
      visitFrequencies: _visitFrequenciesController.text,
      expectedDuration: int.tryParse(_expectedDurationController.text) ?? 0,
      formVersion: InternshipContract.currentVersion,
    );

    final contracts = [...widget.internship.contracts];
    if (newContract
        .getDifference(lastContract, ignoreKeys: ['id', 'date']).isNotEmpty) {
      contracts.add(newContract);
    }

    return widget.internship.copyWith(
      studentId: _studentPickerController.student?.id,
      signatoryTeacherId: _teacherPickerController.teacher?.id ?? '',
      extraSupervisingTeacherIds: _extraTeachersPickerController
          .map((controller) => controller.teacher!.id)
          .toSet()
          .toList(),
      enterpriseId: _enterprisePickerController.enterprise.id,
      teacherNotes: _teacherNotesController.text,
      achievedDuration: int.tryParse(_achievedDurationController.text) ?? -1,
      endDate: _endDate,
      contracts: contracts,
    );
  }

  Person get _editedSupervisor => Person.empty.copyWith(
        firstName: _contactFirstNameController.text,
        lastName: _contactLastNameController.text,
        phone: _contactPhoneController.text.isEmpty
            ? PhoneNumber.empty
            : PhoneNumber.fromString(_contactPhoneController.text),
        email: _contactEmailController.text,
      );

  @override
  void initState() {
    super.initState();
    if (widget.forceEditingMode) {
      _fetchFullDataCompleter.complete();
      _onClickedEditing();
    }
  }

  Future<void> _onClickedDeleting() async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });

    final internships = InternshipsProvider.of(context, listen: false);
    final hasLock = await internships.getLockForItem(widget.internship);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de supprimer le stage, car il est en cours de modification par un autre utilisateur.',
        );
      }
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    // Show confirmation dialog
    final answer = await showDialog(
      context: context,
      builder: (context) =>
          ConfirmDeleteInternshipDialog(internship: widget.internship),
    );
    if (answer == null || !answer || !mounted) {
      await internships.releaseLockForItem(widget.internship);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    final isSuccess = await internships.removeWithConfirmation(
      widget.internship,
    );
    if (mounted) {
      showSnackBar(
        context,
        message: isSuccess
            ? 'Stage supprimé avec succès.'
            : 'Échec de la suppression du stage.',
      );
    }
    await internships.releaseLockForItem(widget.internship);
    setState(() {
      _forceDisabled = false;
    });
  }

  Future<void> _onClickedEditing() async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });

    final internships = InternshipsProvider.of(context, listen: false);

    if (_isEditing) {
      // Validate the form
      if (!(await validate()) || !mounted) {
        setState(() {
          _forceDisabled = false;
        });
        return;
      }

      // Finish editing
      final newInternship = editedInternship;
      if (newInternship.getDifference(widget.internship).isNotEmpty) {
        final authProvider = AuthProvider.of(context, listen: false);
        final isSuccess =
            await internships.replaceWithConfirmation(newInternship);
        if (mounted) {
          showSnackBar(
            context,
            message: isSuccess
                ? 'Stage modifié avec succès.'
                : 'Échec de la modification du stage.'
                    '${authProvider.databaseAccessLevel < AccessLevel.schoolAdmin ? ' Vous devez faire parti de la liste des enseignants responsables de ce stage pour pouvoir le modifier.' : ''}',
          );
        }
      }
      await internships.releaseLockForItem(widget.internship);

      _weeklySchedulesController.changesWereDealtWith();
    } else {
      final hasLock = await internships.getLockForItem(widget.internship);
      if (!hasLock || !mounted) {
        if (mounted) {
          showSnackBar(
            context,
            message:
                'Impossible de modifier le stage, car il est en cours de modification par un autre utilisateur.',
          );
        }
        setState(() {
          _forceDisabled = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isEditing = !_isEditing;
        _forceDisabled = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant InternshipListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.internship.getDifference(editedInternship).isEmpty) return;
    _resetForm();
  }

  void _resetForm() {
    _teacherPickerController.teacher =
        TeachersProvider.of(context, listen: false)
            .fromIdOrNull(widget.internship.signatoryTeacherId);

    final supervisor =
        widget.internship.currentContract?.supervisor ?? Person.empty;
    _contactFirstNameController.text = supervisor.firstName;
    _contactLastNameController.text = supervisor.lastName;
    _contactPhoneController.text = supervisor.phone.toString();
    _contactEmailController.text = supervisor.email;
    _useContactInfo = _editedSupervisor.getDifference(
        _enterprisePickerController.enterprise.contact,
        ignoreKeys: ['id', 'address']).isEmpty;

    _weeklySchedulesController.dateRange =
        widget.internship.currentContract?.dates;
    _weeklySchedulesController.dayCycle = widget.internship.currentContract
            ?.weeklySchedules.firstOrNull?.dayCycle ??
        ConfigurationService.dayCycleDefault;

    _weeklySchedulesController.weeklySchedules =
        InternshipHelpers.copySchedules(
      widget.internship.currentContract?.weeklySchedules ?? [],
      keepId: true,
    );

    _expectedDurationController.text =
        widget.internship.currentContract?.expectedDuration.toString() ?? '';

    _transportations.forceSetIfDifferent(
        comparator: CheckboxWithOtherController(
            elements: Transportation.values,
            initialValues:
                widget.internship.currentContract?.transportations ?? []));

    _visitFrequenciesController.text =
        widget.internship.currentContract?.visitFrequencies ?? '';
    _endDate = widget.internship.endDate;
    _achievedDurationController.text = widget.internship.achievedDuration < 0
        ? ''
        : widget.internship.achievedDuration.toString();

    _teacherNotesController.text = widget.internship.teacherNotes;
  }

  Future<void> _fetchData() async {
    if (_isExpanded) {
      await InternshipsProvider.of(
        context,
        listen: false,
      ).fetchData(id: widget.internship.id, fields: FetchableFields.all);
      if (!mounted) return;

      await StudentsProvider.of(context, listen: false).fetchData(
          id: widget.internship.studentId, fields: FetchableFields.all);
      if (!mounted) return;

      if (!widget.forceEditingMode) {
        final enterpriseProvider =
            EnterprisesProvider.of(context, listen: false);
        await enterpriseProvider.fetchData(
          id: widget.internship.enterpriseId,
          fields: FetchableFields.all,
        );
        _enterprisePickerController.enterprise =
            enterpriseProvider.fromId(widget.internship.enterpriseId);
      }

      _fetchFullDataCompleter.complete();
    } else {
      await Future.delayed(ConfigurationService.expandingTileDuration);
      _fetchFullDataCompleter = Completer<void>();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = _studentPickerController.student;
    final enterprise = _enterprisePickerController.enterprise;

    return widget.forceEditingMode
        ? _buildEditingForm()
        : AnimatedExpandingCard(
            expandingDuration: ConfigurationService.expandingTileDuration,
            initialExpandedState: _isExpanded,
            onTapHeader: (isExpanded) {
              setState(() => _isExpanded = isExpanded);
              _fetchData();
            },
            header: (ctx, isExpanded) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                    top: 8,
                    bottom: 8,
                  ),
                  child: Text(
                    '${student?.fullName} - ${enterprise.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_isExpanded)
                  FutureBuilder(
                    future: _fetchFullDataCompleter.future,
                    builder: (context, snapshot) => snapshot.connectionState ==
                            ConnectionState.done
                        ? Row(
                            children: [
                              if (widget.canDelete)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: _forceDisabled
                                        ? Colors.grey
                                        : Colors.red,
                                  ),
                                  onPressed: _forceDisabled
                                      ? null
                                      : _onClickedDeleting,
                                ),
                              if (_isEditing && !widget.forceEditingMode)
                                IconButton(
                                  icon: Icon(
                                    Icons.cancel,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () async {
                                    _resetForm();

                                    await InternshipsProvider.of(context,
                                            listen: false)
                                        .releaseLockForItem(widget.internship);

                                    setState(() {
                                      _isEditing = false;
                                    });
                                  },
                                ),
                              if (widget.canEdit)
                                IconButton(
                                  icon: Icon(
                                    _isEditing ? Icons.save : Icons.edit,
                                    color: _forceDisabled
                                        ? Colors.grey
                                        : Theme.of(
                                            context,
                                          ).primaryColor,
                                  ),
                                  onPressed:
                                      _forceDisabled ? null : _onClickedEditing,
                                ),
                            ],
                          )
                        : SizedBox.shrink(),
                  ),
              ],
            ),
            child: _buildEditingForm(),
          );
  }

  Widget _buildEditingForm() {
    return FutureBuilder(
      future: _fetchFullDataCompleter.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur de chargement'));
        }

        return Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSupervisingTeacher(),
                const SizedBox(height: 8),
                _buildExtraSupervisingTeachers(),
                const SizedBox(height: 16),
                if (widget.forceEditingMode)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudent(),
                      const SizedBox(height: 8),
                    ],
                  ),
                _buildEnterprise(),
                const SizedBox(height: 8),
                _buildExtraJob(),
                const SizedBox(height: 32),
                _buildSupervisorContact(),
                const SizedBox(height: 8),
                _buildWeeklySchedule(),
                const SizedBox(height: 8.0),
                _buildExpectedDuration(),
                const SizedBox(height: 8.0),
                _buildTransportation(),
                const SizedBox(height: 8.0),
                _buildVisitFrequencies(),
                const SizedBox(height: 8.0),
                if (!_isEditing)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEndDate(),
                      const SizedBox(height: 8.0),
                      _buildAchievedDuration(),
                      const SizedBox(height: 8),
                      _buildTeacherNotes(),
                      SectionDivider(),
                      _buildActions(),
                      SectionDivider(),
                      _buildDocumentsSection(),
                      const SizedBox(height: 8),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudent() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: StudentPickerTile(
        title: '${_isEditing ? '* ' : ''}Élève',
        controller: _studentPickerController,
        editMode: _isEditing,
        onSelected: (_) {
          if (_studentPickerController.student?.program != Program.fpt) {
            _extraJobControllers.clear();
          }
          setState(() {});
        },
      ),
    );
  }

  Widget _buildEnterprise() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: EnterprisePickerTile(
        title: '${_isEditing ? '* ' : ''}Entreprise',
        schoolBoardId: widget.schoolBoardId,
        controller: _enterprisePickerController,
        editMode: widget.forceEditingMode,
        onChanged: (enterprise) async {
          _toggleUseContactInfo(true, enterprise: enterprise);
        },
      ),
    );
  }

  Widget _buildExtraJob() {
    if (_studentPickerController.student?.program != Program.fpt) {
      return SizedBox.shrink();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.forceEditingMode)
        AddJobButton(
          controllers: _extraJobControllers,
          onJobAdded: () => setState(() {}),
          style: Theme.of(context).textButtonTheme.style!.copyWith(
                backgroundColor: Theme.of(context)
                    .elevatedButtonTheme
                    .style!
                    .backgroundColor,
              ),
        ),
      ..._extraJobControllers.asMap().keys.map((index) => Row(
            children: [
              Expanded(
                child: EnterpriseJobListTile(
                  key: ValueKey(_extraJobControllers[index].hashCode),
                  controller: _extraJobControllers[index],
                  schools: [...SchoolBoardsProvider.of(context, listen: false)]
                      .map((e) => e.schools)
                      .flattened
                      .toList(),
                  editMode: widget.forceEditingMode,
                  specializationOnly: true,
                  canChangeExpandedState: false,
                  initialExpandedState: true,
                  elevation: 0.0,
                  jobPickerPadding:
                      const EdgeInsets.only(left: 8, top: 12, right: 24),
                  showHeader: false,
                ),
              ),
              if (widget.forceEditingMode)
                IconButton(
                    onPressed: () => setState(() {
                          _extraJobControllers.removeAt(index);
                        }),
                    icon: Icon(Icons.delete, color: Colors.red)),
            ],
          ))
    ]);
  }

  Widget _buildSupervisingTeacher() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: TeacherPickerTile(
        title: '${_isEditing ? '* ' : ''}Enseignant·e responsable',
        schoolBoardId: widget.schoolBoardId,
        controller: _teacherPickerController,
        editMode: widget.forceEditingMode,
        isMandatory: true,
      ),
    );
  }

  Widget _buildExtraSupervisingTeachers() {
    return Column(
      children: [
        ..._extraTeachersPickerController.map((controller) => Row(
              children: [
                Expanded(
                  child: TeacherPickerTile(
                    key: ValueKey(controller.hashCode),
                    title:
                        '${_isEditing ? '* ' : ''}Enseignant·e responsable supplémentaire',
                    schoolBoardId: widget.schoolBoardId,
                    controller: controller,
                    editMode: _isEditing,
                    isMandatory: true,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                      onPressed: () => setState(() {
                            _extraTeachersPickerController.remove(controller);
                          }),
                      icon: Icon(Icons.delete, color: Colors.red)),
              ],
            )),
        if (_isEditing)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextButton(
                  onPressed: () {
                    setState(() {
                      _extraTeachersPickerController
                          .add(TeacherPickerController());
                    });
                  },
                  child: Text('Ajouter un·e enseignant·e responsable',
                      textAlign: TextAlign.center)),
            ),
          )
      ],
    );
  }

  void _toggleUseContactInfo(bool value, {required Enterprise? enterprise}) {
    _useContactInfo = value;
    if (_useContactInfo && enterprise != null) {
      _contactFirstNameController.text = enterprise.contact.firstName;
      _contactLastNameController.text = enterprise.contact.lastName;
      _contactPhoneController.text = enterprise.contact.phone.toString();
      _contactEmailController.text = enterprise.contact.email;
    } else {
      _contactFirstNameController.text = '';
      _contactLastNameController.text = '';
      _contactPhoneController.text = '';
      _contactEmailController.text = '';
    }
    setState(() {});
  }

  Widget _buildSupervisorContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: _isEditing && _isActive
                  ? Text('Contact')
                  : Text(
                      'Contact : ${widget.internship.currentContract?.supervisor.toString() ?? ''}',
                    ),
            ),
            if (_isEditing)
              Switch(
                onChanged: (newValue) => _toggleUseContactInfo(newValue,
                    enterprise: _enterprisePickerController.enterprise),
                value: _useContactInfo,
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditing && _isActive)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contactFirstNameController,
                        decoration: const InputDecoration(
                            labelText: '* Prénom',
                            labelStyle: TextStyle(color: Colors.black)),
                        style: const TextStyle(color: Colors.black),
                        maxLength: 50,
                        enabled: !_useContactInfo,
                        validator: (value) {
                          if (value?.isEmpty == true) {
                            return 'Le prénom du contact est requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _contactLastNameController,
                        decoration: const InputDecoration(
                          labelText: '* Nom de famille',
                          labelStyle: TextStyle(color: Colors.black),
                        ),
                        style: const TextStyle(color: Colors.black),
                        maxLength: 50,
                        enabled: !_useContactInfo,
                        validator: (value) {
                          if (value?.isEmpty == true) {
                            return 'Le nom du contact est requis';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              PhoneListTile(
                controller: _contactPhoneController,
                isMandatory: false,
                enabled: _isEditing && _isActive && !_useContactInfo,
              ),
              const SizedBox(height: 4),
              EmailListTile(
                controller: _contactEmailController,
                isMandatory: false,
                enabled: _isEditing && _isActive && !_useContactInfo,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySchedule() {
    return ScheduleListTile(
      scheduleController: _weeklySchedulesController,
      editMode: _isEditing && _isActive,
    );
  }

  Widget _buildExpectedDuration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nombre d\'heures prévues'),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: TextFormField(
            controller: _expectedDurationController,
            decoration: const InputDecoration(
              labelText: '* Nombre total d\'heures de stage à faire',
              labelStyle: TextStyle(color: Colors.black),
            ),
            validator: (text) =>
                text!.isEmpty ? 'Indiquer un nombre d\'heures.' : null,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.black),
            enabled: _isEditing,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildTransportation() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transport vers l\'entreprise'),
          CheckboxWithOther(
            controller: _transportations,
            enabled: _isEditing && _isActive,
            otherMaxLength: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitFrequencies() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Visites de supervision'),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: TextFormField(
              controller: _visitFrequenciesController,
              enabled: _isEditing,
              maxLength: 100,
              style: TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Fréquence des visites de l\'enseignant\u00b7e',
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndDate() {
    return Row(
      children: [
        const Text('Date de fin effective :'),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            _isActive
                ? 'Stage en cours'
                : DateFormat.yMMMEd('fr_CA').format(_endDate),
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievedDuration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nombre d\'heures réalisées'),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: TextFormField(
            controller: _achievedDurationController,
            decoration: const InputDecoration(
              labelText: 'Nombre total d\'heures de stage faites',
              labelStyle: TextStyle(color: Colors.black),
            ),
            style: const TextStyle(color: Colors.black),
            enabled: _isEditing,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherNotes() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _teacherNotesController,
            enabled: false,
            style: TextStyle(color: Colors.black),
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Notes de l\'enseignant·e·s',
              labelStyle: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final canTerminate = widget.internship.isActive && !_isEditing;
    final hasActions = canTerminate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions disponibles pour ce stage',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (!hasActions)
          Center(
            child: Text(
              'Aucune action disponible pour le moment.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        if (canTerminate)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: TextButton(
                onPressed: () => showFinalizeInternshipDialog(context,
                    internshipId: widget.internship.id),
                child: Text('Terminer le stage')),
          ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documents générés lors de ce stage',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContractTile(),
              _buildC1Tile(),
              _buildC2Tile(),
              _buildSstTile(),
              _buildEnterpriseTile(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContractTile() => _buildSelectShowPreviousEvaluations(
        title: widget.internship.contracts.isEmpty
            ? 'Aucun contrat de stage généré pour ce stage.'
            : (widget.internship.contracts.length == 1
                ? 'Afficher le contrat de stage du\u00a0: '
                : 'Afficher les contrats de stage du\u00a0: '),
        evaluations: widget.internship.contracts,
        onClickedShowEvaluation: (contractId) =>
            showInternshipEvaluationFormDialog(
          context,
          internshipId: widget.internship.id,
          evaluationId: contractId,
          showEvaluationDialog: (BuildContext context,
                  {required String internshipId, String? evaluationId}) =>
              showManagingContractFormDialog(
            context,
            internship: InternshipsProvider.of(context, listen: false)
                .fromId(internshipId),
            evaluationId: evaluationId,
            isNewContract: false,
          ),
        ),
        onClickedShowEvaluationPdf: (contractId) => showPdfDialog(
          context,
          pdfGeneratorCallback: (context, format) =>
              generateInternshipContractPdf(
            context,
            format,
            internshipId: widget.internship.id,
            contractId: contractId,
          ),
        ),
      );

  Widget _buildC1Tile() => _buildSelectShowPreviousEvaluations(
        title: (widget.internship.skillEvaluations.isEmpty
            ? 'Aucune évaluation de compétences spécifiques du métier (C1) générée pour ce stage.'
            : (widget.internship.skillEvaluations.length == 1
                ? 'Afficher l\'évaluation de compétences spécifiques du métier (C1) du\u00a0: '
                : 'Afficher les évaluations de compétences spécifiques du métier (C1) du\u00a0: ')),
        evaluations: widget.internship.skillEvaluations,
        onClickedShowEvaluation: (evaluationId) =>
            showInternshipEvaluationFormDialog(
          context,
          internshipId: widget.internship.id,
          evaluationId: evaluationId,
          showEvaluationDialog: (BuildContext context,
                  {required String internshipId, String? evaluationId}) =>
              showSkillEvaluationFormDialog(context,
                  internshipId: internshipId, evaluationId: evaluationId),
        ),
        onClickedShowEvaluationPdf: (evaluationId) => showPdfDialog(
          context,
          pdfGeneratorCallback: (context, format) => generateSkillEvaluationPdf(
            context,
            format,
            internshipId: widget.internship.id,
            evaluationId: evaluationId,
          ),
        ),
      );

  Widget _buildC2Tile() => _buildSelectShowPreviousEvaluations(
        title: (widget.internship.attitudeEvaluations.isEmpty
            ? 'Aucune évaluation d\'attitude et de comportement (C2) générée pour ce stage.'
            : (widget.internship.attitudeEvaluations.length == 1
                ? 'Afficher l\'évaluation d\'attitude et de comportement (C2) du\u00a0: '
                : 'Afficher les évaluations d\'attitude et de comportement (C2) du\u00a0: ')),
        evaluations: widget.internship.attitudeEvaluations,
        onClickedShowEvaluation: (evaluationId) =>
            showInternshipEvaluationFormDialog(
          context,
          internshipId: widget.internship.id,
          evaluationId: evaluationId,
          showEvaluationDialog: (BuildContext context,
                  {required String internshipId, String? evaluationId}) =>
              showAttitudeEvaluationFormDialog(context,
                  internshipId: internshipId, evaluationId: evaluationId),
        ),
        onClickedShowEvaluationPdf: (evaluationId) => showPdfDialog(
          context,
          pdfGeneratorCallback: (context, format) =>
              generateAttitudeEvaluationPdf(
            context,
            format,
            internshipId: widget.internship.id,
            evaluationId: evaluationId,
          ),
        ),
      );

  Widget _buildSstTile() => _buildSelectShowPreviousEvaluations(
        title: (widget.internship.sstEvaluations.isEmpty
            ? 'Aucune évaluation de la SST en entreprise générée pour ce stage.'
            : (widget.internship.sstEvaluations.length == 1
                ? 'Afficher l\'évaluation de la SST en entreprise du\u00a0: '
                : 'Afficher les évaluations de la SST en entreprise du\u00a0: ')),
        evaluations: widget.internship.sstEvaluations,
        onClickedShowEvaluation: (evaluationId) =>
            showInternshipEvaluationFormDialog(
          context,
          internshipId: widget.internship.id,
          evaluationId: evaluationId,
          showEvaluationDialog: (BuildContext context,
                  {required String internshipId, String? evaluationId}) =>
              showSstEvaluationFormDialog(context,
                  internshipId: internshipId, evaluationId: evaluationId),
        ),
        onClickedShowEvaluationPdf: (evaluationId) => showPdfDialog(
          context,
          pdfGeneratorCallback: (context, format) => generateSstEvaluationPdf(
            context,
            format,
            internshipId: widget.internship.id,
            evaluationId: evaluationId,
          ),
        ),
      );

  Widget _buildEnterpriseTile() => _buildSelectShowPreviousEvaluations(
        title: (widget.internship.enterpriseEvaluations.isEmpty
            ? 'Aucune évaluation de l\'encadrement de l\'entreprise générée pour ce stage.'
            : (widget.internship.enterpriseEvaluations.length == 1
                ? 'Afficher l\'évaluation de l\'encadrement de l\'entreprise du\u00a0: '
                : 'Afficher les évaluations de l\'encadrement de l\'entreprise du\u00a0: ')),
        evaluations: widget.internship.enterpriseEvaluations,
        onClickedShowEvaluation: (evaluationId) =>
            showInternshipEvaluationFormDialog(
          context,
          internshipId: widget.internship.id,
          evaluationId: evaluationId,
          showEvaluationDialog: (BuildContext context,
                  {required String internshipId, String? evaluationId}) =>
              showEnterpriseEvaluationFormDialog(context,
                  internshipId: internshipId, evaluationId: evaluationId),
        ),
        onClickedShowEvaluationPdf: (evaluationId) => showPdfDialog(
          context,
          pdfGeneratorCallback: (context, format) =>
              generateEnterpriseEvaluationPdf(
            context,
            format,
            internshipId: widget.internship.id,
            evaluationId: evaluationId,
          ),
        ),
      );

  Widget _buildSelectShowPreviousEvaluations({
    required String title,
    required List<InternshipEvaluation> evaluations,
    required Function(String evaluationId) onClickedShowEvaluation,
    required Function(String evaluationId) onClickedShowEvaluationPdf,
  }) {
    final orderedEvaluations = evaluations.sortedBy((e) => e.date).reversed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: orderedEvaluations.map(
                (evaluation) {
                  // Reminder the list is reversed for display
                  return Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(
                          '\u2022 ${DateFormat('dd MMMM yyyy', 'fr_CA').format(evaluation.date)}',
                        ),
                      ),
                      IconButton(
                          onPressed: () =>
                              onClickedShowEvaluation(evaluation.id),
                          color: Theme.of(context).primaryColor,
                          icon: const Icon(Icons.insert_drive_file)),
                      SizedBox(width: 4),
                      IconButton(
                          onPressed: () =>
                              onClickedShowEvaluationPdf(evaluation.id),
                          color: Theme.of(context).primaryColor,
                          icon: const Icon(Icons.picture_as_pdf)),
                    ],
                  );
                },
              ).toList(),
            ),
          )
        ],
      ),
    );
  }
}
