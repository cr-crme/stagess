import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/schedule_selector.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('InternshipDetails');

class _InternshipController {
  _InternshipController(Internship internship)
    : supervisor = internship.supervisor.copyWith(),
      _achievedLength = internship.achievedDuration,
      weeklyScheduleController = WeeklySchedulesController(
        weeklySchedules: InternshipHelpers.copySchedules(
          internship.weeklySchedules,
        ),
        dateRange: internship.dates,
      ),
      transportations =
          internship.hasVersions ? [...internship.transportations] : [],
      visitFrequenciesController = TextEditingController(
        text: internship.hasVersions ? internship.visitFrequencies : '',
      );

  bool get hasChanged =>
      weeklyScheduleController.hasChanged || supervisorChanged;

  Person supervisor;
  bool get supervisorChanged =>
      supervisor.firstName != supervisorFirstNameController.text ||
      supervisor.lastName != supervisorLastNameController.text ||
      supervisor.phone.toString() != supervisorPhoneController.text ||
      (supervisor.email ?? '') != supervisorEmailController.text;
  final supervisorFormKey = GlobalKey<FormState>();
  late final supervisorFirstNameController = TextEditingController(
    text: supervisor.firstName,
  );
  late final supervisorLastNameController = TextEditingController(
    text: supervisor.lastName,
  );
  late final supervisorPhoneController = TextEditingController(
    text: supervisor.phone.toString(),
  );
  late final supervisorEmailController = TextEditingController(
    text: supervisor.email ?? '',
  );

  bool achievedLengthChanged = false;
  int _achievedLength;
  int get achievedLength => _achievedLength;
  set achievedLength(int newLength) {
    _achievedLength = newLength;
    achievedLengthChanged = true;
  }

  WeeklySchedulesController weeklyScheduleController;
  final List<Transportation> transportations;
  final TextEditingController visitFrequenciesController;

  void dispose() {
    supervisorFirstNameController.dispose();
    supervisorLastNameController.dispose();
    supervisorPhoneController.dispose();
    supervisorEmailController.dispose();
    visitFrequenciesController.dispose();
  }
}

class InternshipDetails extends StatefulWidget {
  const InternshipDetails({super.key, required this.internshipId});

  final String internshipId;

  @override
  State<InternshipDetails> createState() => InternshipDetailsState();
}

class InternshipDetailsState extends State<InternshipDetails> {
  bool _isExpanded = false;
  bool _editMode = false;
  bool _forceDisabled = false;
  bool get editMode => _editMode;

  late Internship _internship;
  late _InternshipController _internshipController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _internship = InternshipsProvider.of(
      context,
    ).firstWhere((e) => e.id == widget.internshipId);

    _internshipController = _InternshipController(_internship);
  }

  Future<void> _toggleEditMode({bool save = true}) async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });
    final internships = InternshipsProvider.of(context, listen: false);

    if (_editMode) {
      _editMode = false;
      if (!save) {
        await internships.releaseLockForItem(_internship);
        setState(() {
          _forceDisabled = false;
        });
        return;
      }
    } else {
      final hasLock = await internships.getLockForItem(_internship);
      if (!hasLock) {
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

      _editMode = true;
      _internshipController = _InternshipController(_internship);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }
    _logger.info('Validating internship before toggling edit mode');

    // Validate before starting to save
    if (_internshipController.supervisorChanged) {
      if (!_internshipController.supervisorFormKey.currentState!.validate()) {
        // Prevent from exiting the edit mode if the field can't be validated
        _editMode = true;
        showSnackBar(context, message: 'Remplir tous les champs avec un *.');
        setState(() {
          _forceDisabled = false;
        });
        return;
      }
    }

    // Saving the values that do not require an extra version
    bool hasChanged = false;
    if (_internshipController.achievedLengthChanged) {
      _internship = _internship.copyWith(
        achievedDuration: _internshipController._achievedLength,
      );
      hasChanged = true;
    }

    final transportationsHasChanged = areListsNotEqual(
      _internship.transportations,
      _internshipController.transportations,
    );
    final visitFrequenciesHasChanged =
        _internship.visitFrequencies !=
        _internshipController.visitFrequenciesController.text;

    // Saving the values that require an extra version
    if (_internshipController.hasChanged ||
        visitFrequenciesHasChanged ||
        transportationsHasChanged) {
      _internship.addVersion(
        creationDate: DateTime.now(),
        supervisor: _internship.supervisor.copyWith(
          firstName: _internshipController.supervisorFirstNameController.text,
          lastName: _internshipController.supervisorLastNameController.text,
          phone: PhoneNumber.fromString(
            _internshipController.supervisorPhoneController.text,
          ),
          email: _internshipController.supervisorEmailController.text,
        ),
        dates: _internshipController.weeklyScheduleController.dateRange!,
        transportations: _internshipController.transportations,
        visitFrequencies: _internshipController.visitFrequenciesController.text,
        weeklySchedules:
            _internshipController.weeklyScheduleController.weeklySchedules
                .map((e) => e.duplicate())
                .toList(),
      );

      hasChanged = true;
    }

    if (hasChanged) {
      await internships.replaceWithConfirmation(_internship);
      _logger.fine('Internship updated: ${_internship.id}');
    }
    await internships.releaseLockForItem(_internship);
    setState(() {
      _forceDisabled = false;
    });
  }

  void _promptDateRange() async {
    final range = await showCustomDateRangePicker(
      helpText: 'Sélectionner les dates',
      saveText: 'Confirmer',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      context: context,
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDateRange:
          _internshipController.weeklyScheduleController.dateRange,
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (range == null) return;

    _internshipController.weeklyScheduleController.dateRange = range;
    setState(() {});
  }

  Future<bool> preventClosingIfEditing() async {
    _logger.finer('Preventing closing if editing, edit mode: $_editMode');

    final shouldQuit = await ConfirmExitDialog.show(
      context,
      content: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text:
                  '** Vous quittez la page sans avoir '
                  'cliqué sur Enregistrer ',
            ),
            WidgetSpan(
              child: SizedBox(
                height: 22,
                width: 22,
                child: Icon(Icons.save, color: Theme.of(context).primaryColor),
              ),
            ),
            const TextSpan(
              text: '. **\n\nToutes vos modifications seront perdues.',
            ),
          ],
        ),
      ),
      isEditing: editMode,
    );
    if (shouldQuit) _toggleEditMode(save: false);
    return !shouldQuit;
  }

  @override
  void dispose() {
    _internshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building InternshipDetails for ID: ${widget.internshipId}');

    final myId = TeachersProvider.of(context).currentTeacher?.id;
    if (myId == null) {
      return const Center(child: Text('Vous n\'êtes pas connecté.'));
    }
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: ExpansionPanelList(
        elevation: 0,
        expansionCallback: (index, isExpanded) async {
          if (_isExpanded && _editMode) {
            if (await preventClosingIfEditing()) return;
          }
          setState(() => _isExpanded = !_isExpanded);
        },
        children: [
          ExpansionPanel(
            isExpanded: _isExpanded,
            canTapOnHeader: true,
            headerBuilder:
                (context, isExpanded) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Détails du stage',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge!.copyWith(color: Colors.black),
                    ),
                    if (_isExpanded &&
                        _internship.isActive &&
                        _internship.supervisingTeacherIds.contains(myId))
                      IconButton(
                        onPressed: _forceDisabled ? null : _toggleEditMode,
                        icon: Icon(
                          editMode ? Icons.save : Icons.edit,
                          color:
                              _forceDisabled
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                        ),
                      ),
                  ],
                ),
            body: _InternshipBody(
              internship: _internship,
              editMode: _editMode,
              onSave: _toggleEditMode,
              onRequestChangedDates: _promptDateRange,
              internshipController: _internshipController,
            ),
          ),
        ],
      ),
    );
  }
}

class _InternshipBody extends StatelessWidget {
  const _InternshipBody({
    required this.internship,
    required this.editMode,
    required this.onSave,
    required this.onRequestChangedDates,
    required this.internshipController,
  });

  final Internship internship;
  final bool editMode;

  final Function() onSave;
  final Function() onRequestChangedDates;
  final _InternshipController internshipController;

  static const TextStyle _titleStyle = TextStyle(fontWeight: FontWeight.bold);
  static const _interline = 12.0;

  Widget _buildTeachers({
    required List<String> supervisors,
    required String signatoryTeacher,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enseignant\u00b7e\u00b7s superviseur\u00b7e\u00b7s de stage\u00a0:',
          style: _titleStyle,
        ),
        ItemizedText(supervisors),
        const SizedBox(height: 12),
        const Text('Signataire du contrat de stage\u00a0:', style: _titleStyle),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: _interline),
          child: Text(signatoryTeacher),
        ),
      ],
    );
  }

  Widget _buildSupervisorInfo() {
    return Form(
      key: internshipController.supervisorFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Responsable en milieu de stage', style: _titleStyle),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: _interline),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                editMode
                    ? Column(
                      children: [
                        TextFormField(
                          controller:
                              internshipController
                                  .supervisorFirstNameController,
                          decoration: const InputDecoration(
                            label: Text('* Prénom'),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Ajouter un prénom' : null,
                        ),
                        TextFormField(
                          controller:
                              internshipController.supervisorLastNameController,
                          decoration: const InputDecoration(
                            label: Text('* Nom'),
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Ajouter un nom' : null,
                        ),
                      ],
                    )
                    : Text(internship.supervisor.fullName),
                const SizedBox(height: 8),
                PhoneListTile(
                  isMandatory: false,
                  enabled: editMode,
                  controller: internshipController.supervisorPhoneController,
                ),
                const SizedBox(height: 8),
                EmailListTile(
                  controller: internshipController.supervisorEmailController,
                  enabled: editMode,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDates() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dates du stage', style: _titleStyle),
            Padding(
              padding: const EdgeInsets.only(bottom: _interline),
              child: Table(
                children: [
                  const TableRow(
                    children: [Text('Date de début :'), Text('Date de fin :')],
                  ),
                  TableRow(
                    children: [
                      Text(
                        DateFormat.yMMMEd('fr_CA').format(
                          internshipController
                                  .weeklyScheduleController
                                  .dateRange
                                  ?.start ??
                              DateTime.now(),
                        ),
                      ),
                      Text(
                        DateFormat.yMMMEd('fr_CA').format(
                          internshipController
                                  .weeklyScheduleController
                                  .dateRange
                                  ?.end ??
                              DateTime.now(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (editMode)
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.blue),
            onPressed: onRequestChangedDates,
          ),
      ],
    );
  }

  Widget _buildTime() {
    final achievedDuration =
        internshipController.achievedLength < 0
            ? 0
            : internshipController.achievedLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nombre d\'heures de stage', style: _titleStyle),
        Padding(
          padding: const EdgeInsets.only(bottom: _interline),
          child: Table(
            children: [
              TableRow(
                children: [
                  Text('Total prévu : ${internship.expectedDuration}h'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total fait : '),
                      editMode
                          ? SizedBox(
                            width: 45,
                            child: TextFormField(
                              textAlign: TextAlign.right,
                              initialValue: achievedDuration.toString(),
                              onChanged:
                                  (newValue) =>
                                      internshipController.achievedLength =
                                          newValue == ''
                                              ? 0
                                              : int.parse(newValue),
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                            ),
                          )
                          : Text(achievedDuration.toString()),
                      const Text('h'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedule() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Horaire du stage', style: _titleStyle),
          ScheduleSelector(
            editMode: editMode,
            scheduleController: internshipController.weeklyScheduleController,
            leftPadding: 0,
            periodTextSize: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitFrequencies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fréquence des visites de l\'enseignant\u00b7e',
          style: _titleStyle,
        ),
        editMode
            ? Padding(
              padding: const EdgeInsets.only(top: 2, bottom: _interline),
              child: TextFormField(
                controller: internshipController.visitFrequenciesController,
              ),
            )
            : Padding(
              padding: const EdgeInsets.only(top: 2, bottom: _interline),
              child: Text(internship.visitFrequencies),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building _InternshipBody for internship: ${internship.id}');

    final teachers = TeachersProvider.of(context);

    final supervisors = teachers.where(
      (e) => internship.supervisingTeacherIds.contains(e.id),
    );
    final signatoryTeacher = teachers.firstWhere(
      (e) => e.id == internship.signatoryTeacherId,
    );

    _logger.finer(
      'with ${supervisors.length} supervisors and signatory teacher: ${signatoryTeacher.id}',
    );

    return FocusScope(
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSupervisorInfo(),
            _buildDates(),
            _buildTime(),
            _buildSchedule(),
            _Transportations(
              editMode: editMode,
              transportations: internshipController.transportations,
            ),
            _buildVisitFrequencies(),
            _buildTeachers(
              supervisors: supervisors.map((e) => e.fullName).toList(),
              signatoryTeacher: signatoryTeacher.fullName,
            ),
            if (editMode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSave,
                  child: Text('Sauvegarder'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Transportations extends StatefulWidget {
  const _Transportations({
    required this.editMode,
    required this.transportations,
  });

  final bool editMode;
  final List<Transportation> transportations;

  @override
  State<_Transportations> createState() => _TransportationsState();
}

class _TransportationsState extends State<_Transportations> {
  @override
  void didUpdateWidget(covariant _Transportations oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editMode != widget.editMode) setState(() {});
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transport vers l\'entreprise',
          style: _InternshipBody._titleStyle,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              Transportation.values.map((e) {
                return MouseRegion(
                  cursor:
                      widget.editMode
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap:
                        widget.editMode
                            ? () => _updateTransportations(e)
                            : null,
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
                              widget.editMode
                                  ? (value) => _updateTransportations(e)
                                  : null,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
