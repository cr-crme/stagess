import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/enterprise_extension.dart';
import 'package:stagess/common/extensions/students_extension.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/add_job_button.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/enterprise_job_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/student_picker_tile.dart';

final _logger = Logger('GeneralInformationsStep');

List<Student> _studentsWithoutInternship(
    BuildContext context, List<Student> students) {
  final List<Student> out = [];
  for (final student in students) {
    if (!student.hasActiveInternship(context)) out.add(student);
  }

  return out;
}

class CaracteristicsStep extends StatefulWidget {
  const CaracteristicsStep({
    super.key,
    required this.enterprise,
    this.specifiedSpecialization,
  });

  final Enterprise enterprise;
  final List<Specialization>? specifiedSpecialization;

  @override
  State<CaracteristicsStep> createState() => CaracteristicsStepState();
}

class CaracteristicsStepState extends State<CaracteristicsStep> {
  final formKey = GlobalKey<FormState>();

  late final studentController = StudentPickerController(
    schoolBoardId: AuthProvider.of(context, listen: false).schoolBoardId!,
    studentWhiteList: _studentsWithoutInternship(
      context,
      StudentsHelpers.studentsInMyGroups(context),
    ),
  );
  Enterprise get enterprise => widget.enterprise;
  Student? get student => studentController.student;

  late final primaryJobController = EnterpriseJobListController(
    context: context,
    enterpriseStatus: EnterpriseStatus.active,
    job: widget.enterprise.availablejobs(context).length == 1
        ? widget.enterprise.availablejobs(context).first
        : Job.empty,
    specializationWhiteList: widget.specifiedSpecialization ??
        widget.enterprise
            .jobsWithRemainingPositions(
              context,
              schoolId: AuthProvider.of(context, listen: false).schoolId!,
              listen: false,
            )
            .map((job) => job.specialization)
            .toList(),
  );
  final extraJobControllers = <EnterpriseJobListController>[];

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? get supervisorFirstName =>
      _firstNameController.text.isEmpty ? null : _firstNameController.text;
  String? get supervisorLastName =>
      _lastNameController.text.isEmpty ? null : _lastNameController.text;
  String? get supervisorPhone =>
      _phoneController.text.isEmpty ? null : _phoneController.text;
  String? get supervisorEmail =>
      _emailController.text.isEmpty ? null : _emailController.text;

  List<Transportation> transportations = [];

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building GeneralInformationsStep for enterprise: ${enterprise.id}',
    );

    return FocusScope(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GeneralInformations(
              studentController: studentController,
              setState: setState,
            ),
            const SizedBox(height: 10),
            _MainJob(
              controller: primaryJobController,
              extraJobControllers: extraJobControllers,
            ),
            if (student != null && student!.program == Program.fpt)
              _ExtraSpecialization(
                controllers: extraJobControllers,
                setState: setState,
              ),
            _SupervisonInformation(
              enterprise: widget.enterprise,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              phoneController: _phoneController,
              emailController: _emailController,
            ),
            TransportationsCheckBoxes(
              withTitle: true,
              editMode: true,
              transportations: transportations,
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralInformations extends StatelessWidget {
  const _GeneralInformations({
    required this.studentController,
    required this.setState,
  });
  final StudentPickerController studentController;

  final Function(Function()) setState;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building _GeneralInformations with selected student: ${studentController.student?.id}',
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
                controller: studentController,
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
  const _MainJob({required this.controller, required this.extraJobControllers});

  final EnterpriseJobListController controller;
  final List<EnterpriseJobListController> extraJobControllers;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building _MainJob with controller job: ${controller.job.id}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Métier', left: 0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (extraJobControllers.isNotEmpty)
              Text(
                'Métier principal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            EnterpriseJobListTile(
              controller: controller,
              schools: [
                SchoolBoardsProvider.of(context, listen: false).currentSchool!,
              ],
              editMode: true,
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
    required this.controllers,
    required this.setState,
  });

  final List<EnterpriseJobListController> controllers;
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
            SizedBox(
              width: 35,
              height: 35,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () => setState(() => controllers.removeAt(index)),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
            ),
          ],
        ),
        EnterpriseJobListTile(
          controller: controllers[index],
          schools: [
            SchoolBoardsProvider.of(context, listen: false).currentSchool!,
          ],
          editMode: true,
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
      'Building _ExtraSpecialization with ${controllers.length} controllers',
    );

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...controllers.asMap().keys.map<Widget>(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: _extraJobTileBuilder(context, i),
                ),
              ),
          Text(
            'Besoin d\'ajouter des compétences d\'un autre métier pour ce stage?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          AddJobButton(
            controllers: controllers,
            onJobAdded: () => setState(() {}),
            style: Theme.of(context).textButtonTheme.style!.copyWith(
                  backgroundColor: Theme.of(context)
                      .elevatedButtonTheme
                      .style!
                      .backgroundColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _SupervisonInformation extends StatefulWidget {
  const _SupervisonInformation({
    required this.enterprise,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.emailController,
  });

  final Enterprise? enterprise;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;

  @override
  State<_SupervisonInformation> createState() => _SupervisonInformationState();
}

class _SupervisonInformationState extends State<_SupervisonInformation> {
  bool _useContactInfo = false; // Start at false, but call toggle on init

  @override
  void initState() {
    super.initState();
    _toggleUseContactInfo();
  }

  void _toggleUseContactInfo() {
    _useContactInfo = !_useContactInfo;
    if (_useContactInfo) {
      widget.firstNameController.text =
          widget.enterprise?.contact.firstName ?? '';
      widget.lastNameController.text =
          widget.enterprise?.contact.lastName ?? '';
      widget.phoneController.text =
          widget.enterprise?.contact.phone.toString() ?? '';
      widget.emailController.text = widget.enterprise?.contact.email ?? '';
    } else {
      widget.firstNameController.text = '';
      widget.lastNameController.text = '';
      widget.phoneController.text = '';
      widget.emailController.text = '';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building _SupervisionInformation for enterprise: ${widget.enterprise?.id} '
      'and contact id: ${widget.enterprise?.contact.id}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Responsable en milieu de stage', left: 0),
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
              onChanged: widget.enterprise == null
                  ? null
                  : (newValue) => _toggleUseContactInfo(),
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
                    controller: widget.firstNameController,
                    decoration: const InputDecoration(
                      labelText: '* Prénom',
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    validator: (text) =>
                        text!.isEmpty ? 'Ajouter un prénom.' : null,
                    enabled: !_useContactInfo,
                  ),
                  TextFormField(
                    controller: widget.lastNameController,
                    decoration: const InputDecoration(
                      labelText: '* Nom de famille',
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    style: TextStyle(color: Colors.black),
                    validator: (text) =>
                        text!.isEmpty ? 'Ajouter un nom de famille.' : null,
                    enabled: !_useContactInfo,
                  ),
                ],
              ),
              PhoneListTile(
                controller: widget.phoneController,
                isMandatory: true,
                canCall: false,
                enabled: !_useContactInfo,
              ),
              EmailListTile(
                controller: widget.emailController,
                isMandatory: true,
                enabled: !_useContactInfo,
                canMail: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TransportationsCheckBoxes extends StatefulWidget {
  const TransportationsCheckBoxes({
    super.key,
    required this.withTitle,
    required this.transportations,
    required this.editMode,
  });

  final bool withTitle;
  final List<Transportation> transportations;
  final bool editMode;

  @override
  State<TransportationsCheckBoxes> createState() =>
      _TransportationsCheckBoxesState();
}

class _TransportationsCheckBoxesState extends State<TransportationsCheckBoxes> {
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
        if (widget.withTitle)
          const SubTitle('Transport de l\'élève vers l\'entreprise', left: 0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: Transportation.values.map((e) {
            return InkWell(
              onTap: widget.editMode ? () => _updateTransportations(e) : null,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 8.0),
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
                      onChanged: widget.editMode
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
