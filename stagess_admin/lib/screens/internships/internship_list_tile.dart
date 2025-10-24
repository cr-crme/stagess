import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stagess_admin/screens/internships/confirm_delete_internship_dialog.dart';
import 'package:stagess_admin/screens/internships/schedule_list_tile.dart';
import 'package:stagess_admin/widgets/enterprise_picker_tile.dart';
import 'package:stagess_admin/widgets/teacher_picker_tile.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/configuration_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/schedule_selector.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';
import 'package:stagess_common_flutter/widgets/student_picker_tile.dart';

class InternshipListTile extends StatefulWidget {
  const InternshipListTile({
    super.key,
    required this.internship,
    this.forceEditingMode = false,
    required this.canEdit,
    required this.canDelete,
  });

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
    schoolBoardId: widget.internship.schoolBoardId,
    initial: StudentsProvider.of(
      context,
      listen: false,
    ).firstWhereOrNull((student) => student.id == widget.internship.studentId),
  );
  late final _teacherPickerController = TeacherPickerController(
    initial: TeachersProvider.of(context, listen: false).firstWhereOrNull(
      (teacher) => teacher.id == widget.internship.signatoryTeacherId,
    ),
  );
  late final _enterprisePickerController = EnterprisePickerController(
    initialEnterprise: EnterprisesProvider.of(
      context,
      listen: false,
    ).firstWhereOrNull(
      (enterprise) => enterprise.id == widget.internship.enterpriseId,
    ),
  );
  late final _contactFirstNameController = TextEditingController(
    text:
        widget.internship.hasVersions
            ? widget.internship.supervisor.firstName
            : '',
  );
  late final _contactLastNameController = TextEditingController(
    text:
        widget.internship.hasVersions
            ? widget.internship.supervisor.lastName
            : '',
  );
  late final _contactPhoneController = TextEditingController(
    text:
        widget.internship.hasVersions
            ? widget.internship.supervisor.phone?.toString()
            : '',
  );
  late final _contactEmailController = TextEditingController(
    text:
        widget.internship.hasVersions ? widget.internship.supervisor.email : '',
  );
  late final _weeklySchedulesController = WeeklySchedulesController(
    dateRange: widget.internship.hasVersions ? widget.internship.dates : null,
    weeklySchedules:
        widget.internship.hasVersions
            ? widget.internship.weeklySchedules
            : null,
  );
  late final _expectedDurationController = TextEditingController(
    text:
        widget.internship.expectedDuration > 0
            ? widget.internship.expectedDuration.toString()
            : '',
  );
  late final _transportations =
      widget.internship.hasVersions
          ? [...widget.internship.transportations]
          : <Transportation>[];
  late final _visitFrequenciesController = TextEditingController(
    text:
        widget.internship.hasVersions ? widget.internship.visitFrequencies : '',
  );
  late DateTime _endDate = widget.internship.endDate;
  bool get _isActive => _endDate == DateTime(0);
  late final _achievedDurationController = TextEditingController(
    text:
        widget.internship.achievedDuration > 0
            ? widget.internship.achievedDuration.toString()
            : '',
  );
  late final _teacherNotesController = TextEditingController(
    text: widget.internship.teacherNotes,
  );

  Internship get editedInternship {
    var internship = widget.internship.copyWith(
      studentId: _studentPickerController.student?.id,
      signatoryTeacherId: _teacherPickerController.teacher?.id ?? '',
      enterpriseId:
          widget.forceEditingMode
              ? _enterprisePickerController.enterprise.id
              : null,
      jobId:
          widget.forceEditingMode ? _enterprisePickerController.job.id : null,
      teacherNotes: _teacherNotesController.text,
      expectedDuration: int.tryParse(_expectedDurationController.text) ?? 0,
      achievedDuration: int.tryParse(_achievedDurationController.text) ?? -1,
      endDate: _endDate,
    );

    final schedulesHasChanged =
        !widget.internship.hasVersions || _weeklySchedulesController.hasChanged;

    final transportationsChanged = areListsNotEqual(
      widget.internship.hasVersions ? widget.internship.transportations : [],
      _transportations,
    );
    final visitFrequenciesChanged =
        (widget.internship.hasVersions
            ? widget.internship.visitFrequencies
            : '') !=
        _visitFrequenciesController.text;

    final previousSupervisor =
        widget.internship.hasVersions
            ? widget.internship.supervisor
            : Person.empty;
    final supervisor = previousSupervisor.copyWith(
      firstName: _contactFirstNameController.text,
      lastName: _contactLastNameController.text,
      phone: PhoneNumber.fromString(
        _contactPhoneController.text,
        id: previousSupervisor.phone?.id,
      ),
      email: _contactEmailController.text,
    );

    if (schedulesHasChanged ||
        visitFrequenciesChanged ||
        transportationsChanged ||
        previousSupervisor.getDifference(supervisor).isNotEmpty) {
      // If a mutable has changed, we cannot edit it from here. We have to
      // create a deep copy of the internship and modify this new instance.
      // The easiest way to do this is to serialize, modify and then deserialize.
      final serialized = internship.serialize();
      final newVersion = InternshipMutableElements(
        creationDate: DateTime.now(),
        supervisor: supervisor,
        dates: _weeklySchedulesController.dateRange!,
        weeklySchedules: InternshipHelpers.copySchedules(
          _weeklySchedulesController.weeklySchedules,
          keepId: false,
        ),
        transportations: _transportations,
        visitFrequencies: _visitFrequenciesController.text,
      );
      (serialized['mutables'] as List).add(newVersion.serialize());
      internship = Internship.fromSerialized(serialized);
    }

    return internship;
  }

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
      builder:
          (context) =>
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
        message:
            isSuccess
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
        final isSuccess = await internships.replaceWithConfirmation(
          newInternship,
        );
        if (mounted) {
          showSnackBar(
            context,
            message:
                isSuccess
                    ? 'Stage modifié avec succès.'
                    : 'Échec de la modification du stage.',
          );
        }
      }
      await internships.releaseLockForItem(widget.internship);
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

  // TODO Fix not possible to modify the internships anymore
  @override
  void didUpdateWidget(covariant InternshipListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final teachers = TeachersProvider.of(context, listen: false);

    if (_teacherPickerController.teacher?.id !=
        widget.internship.signatoryTeacherId) {
      _teacherPickerController.teacher = teachers.fromIdOrNull(
        widget.internship.signatoryTeacherId,
      );
    }

    final supervisor =
        widget.internship.hasVersions
            ? widget.internship.supervisor
            : Person.empty;
    if (_contactFirstNameController.text != supervisor.firstName) {
      _contactFirstNameController.text = supervisor.firstName;
    }
    if (_contactLastNameController.text != supervisor.lastName) {
      _contactLastNameController.text = supervisor.lastName;
    }
    if (_contactPhoneController.text != (supervisor.phone?.toString() ?? '')) {
      _contactPhoneController.text = supervisor.phone?.toString() ?? '';
    }
    if (_contactEmailController.text != supervisor.email) {
      _contactEmailController.text = supervisor.email ?? '';
    }

    final dates =
        widget.internship.hasVersions ? widget.internship.dates : null;
    if (_weeklySchedulesController.dateRange != dates) {
      _weeklySchedulesController.dateRange = dates;
    }
    final weeklySchedules =
        widget.internship.hasVersions
            ? widget.internship.weeklySchedules
            : <WeeklySchedule>[];
    if (!InternshipHelpers.areSchedulesEqual(
      _weeklySchedulesController.weeklySchedules,
      weeklySchedules,
    )) {
      _weeklySchedulesController.weeklySchedules =
          InternshipHelpers.copySchedules(weeklySchedules, keepId: true);
    }

    if (_expectedDurationController.text !=
        widget.internship.expectedDuration.toString()) {
      _expectedDurationController.text =
          widget.internship.expectedDuration.toString();
    }
    final transportations =
        widget.internship.hasVersions
            ? widget.internship.transportations
            : <Transportation>[];
    if (_transportations.toSet() != transportations.toSet()) {
      _transportations
        ..clear()
        ..addAll(transportations);
    }
    final visitFrequencies =
        widget.internship.hasVersions ? widget.internship.visitFrequencies : '';
    if (_visitFrequenciesController.text != visitFrequencies) {
      _visitFrequenciesController.text = visitFrequencies;
    }

    if (_endDate != widget.internship.endDate) {
      _endDate = widget.internship.endDate;
    }
    if (_achievedDurationController.text !=
        (widget.internship.achievedDuration < 0
            ? ''
            : widget.internship.achievedDuration.toString())) {
      _achievedDurationController.text =
          widget.internship.achievedDuration.toString();
    }

    if (_teacherNotesController.text != widget.internship.teacherNotes) {
      _teacherNotesController.text = widget.internship.teacherNotes;
    }
  }

  Future<void> _fetchData() async {
    if (_isExpanded) {
      await InternshipsProvider.of(
        context,
        listen: false,
      ).fetchData(id: widget.internship.id, fields: FetchableFields.all);
      _fetchFullDataCompleter.complete();
    } else {
      await Future.delayed(ConfigurationService.expandingTileDuration);
      _fetchFullDataCompleter = Completer<void>();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
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
          header:
              (ctx, isExpanded) => Row(
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
                      builder:
                          (context, snapshot) =>
                              snapshot.connectionState == ConnectionState.done
                                  ? Row(
                                    children: [
                                      if (widget.canDelete)
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color:
                                                _forceDisabled
                                                    ? Colors.grey
                                                    : Colors.red,
                                          ),
                                          onPressed:
                                              _forceDisabled
                                                  ? null
                                                  : _onClickedDeleting,
                                        ),
                                      if (widget.canEdit)
                                        IconButton(
                                          icon: Icon(
                                            _isEditing
                                                ? Icons.save
                                                : Icons.edit,
                                            color:
                                                _forceDisabled
                                                    ? Colors.grey
                                                    : Theme.of(
                                                      context,
                                                    ).primaryColor,
                                          ),
                                          onPressed:
                                              _forceDisabled
                                                  ? null
                                                  : _onClickedEditing,
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
                if (widget.forceEditingMode)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudent(),
                      const SizedBox(height: 8),
                      _buildEnterprise(),
                      const SizedBox(height: 8),
                    ],
                  ),
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
                _buildEndDate(),
                const SizedBox(height: 8.0),
                _buildAchievedDuration(),
                const SizedBox(height: 8),
                _buildTeacherNotes(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudent() {
    _studentPickerController.student =
        StudentsProvider.of(context, listen: true).firstWhereOrNull(
          (student) => student.id == widget.internship.studentId,
        ) ??
        Student.empty;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: StudentPickerTile(
        title: 'Élève',
        controller: _studentPickerController,
        editMode: _isEditing,
      ),
    );
  }

  Widget _buildEnterprise() {
    _enterprisePickerController.enterprise =
        EnterprisesProvider.of(context, listen: true).firstWhereOrNull(
          (enterprise) => enterprise.id == widget.internship.enterpriseId,
        ) ??
        Enterprise.empty;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: EnterprisePickerTile(
        title: 'Entreprise',
        schoolBoardId: widget.internship.schoolBoardId,
        controller: _enterprisePickerController,
        editMode: _isEditing,
      ),
    );
  }

  Widget _buildSupervisingTeacher() {
    _teacherPickerController.teacher =
        TeachersProvider.of(context, listen: true).firstWhereOrNull(
          (teacher) => teacher.id == widget.internship.signatoryTeacherId,
        ) ??
        Teacher.empty;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: TeacherPickerTile(
        title: 'Enseignant·e responsable',
        schoolBoardId: widget.internship.schoolBoardId,
        controller: _teacherPickerController,
        editMode: _isEditing,
        isMandatory: true,
      ),
    );
  }

  Widget _buildSupervisorContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isEditing && _isActive
            ? Text('Contact')
            : Text(
              'Contact : ${widget.internship.hasVersions ? widget.internship.supervisor.toString() : ''}',
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
                        decoration: const InputDecoration(labelText: 'Prénom'),
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
                          labelText: 'Nom de famille',
                        ),
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
                enabled: _isEditing && _isActive,
              ),
              const SizedBox(height: 4),
              EmailListTile(
                controller: _contactEmailController,
                isMandatory: false,
                enabled: _isEditing && _isActive,
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
            validator:
                (text) =>
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

  Future<void> _promptEndDate() async {
    final date = await showCustomDatePicker(
      helpText: 'Sélectionner la date de fin',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      context: context,
      initialDate: _isActive ? DateTime.now() : _endDate,
      initialEntryMode: DatePickerEntryMode.calendar,
      firstDate: DateTime(widget.internship.dates.start.year - 1),
      lastDate: DateTime(widget.internship.dates.start.year + 2),
    );
    if (date == null) return;
    _endDate = date;
    setState(() {});
  }

  Widget _buildTransportation() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transport vers l\'entreprise'),
          _Transportations(
            isEditing: _isEditing,
            transportations: _transportations,
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
        if (_isEditing)
          Row(
            children: [
              if (!_isActive)
                IconButton(
                  onPressed: () => setState(() => _endDate = DateTime(0)),
                  icon: Icon(Icons.delete, color: Colors.red),
                ),
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.blue,
                ),
                onPressed: _promptEndDate,
              ),
            ],
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
            enabled: _isEditing,
            style: TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              labelText: 'Notes de l\'enseignant·e·s',
              labelStyle: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _Transportations extends StatefulWidget {
  const _Transportations({
    required this.isEditing,
    required this.transportations,
  });

  final bool isEditing;
  final List<Transportation> transportations;

  @override
  State<_Transportations> createState() => _TransportationsState();
}

class _TransportationsState extends State<_Transportations> {
  @override
  void didUpdateWidget(covariant _Transportations oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEditing != widget.isEditing) setState(() {});
  }

  void _updateTransportations(Transportation transportation) {
    if (!widget.transportations.contains(transportation)) {
      widget.transportations.add(transportation);
    } else {
      widget.transportations.remove(transportation);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            Transportation.values.map((e) {
              return MouseRegion(
                cursor:
                    widget.isEditing
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                child: GestureDetector(
                  onTap:
                      widget.isEditing ? () => _updateTransportations(e) : null,
                  child: Row(
                    children: [
                      Text(e.toString()),
                      Checkbox(
                        value: widget.transportations.contains(e),
                        side: WidgetStateBorderSide.resolveWith(
                          (states) => BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2.0,
                          ),
                        ),
                        fillColor: WidgetStatePropertyAll(Colors.transparent),
                        checkColor: Colors.black,
                        onChanged:
                            widget.isEditing
                                ? (value) => _updateTransportations(e)
                                : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
