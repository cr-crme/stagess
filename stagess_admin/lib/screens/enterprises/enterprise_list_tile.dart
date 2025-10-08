import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stagess_admin/screens/enterprises/confirm_delete_enterprise_dialog.dart';
import 'package:stagess_admin/widgets/teacher_picker_tile.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/enterprises/job_list.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/address_list_tile.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/enterprise_activity_type_list_tile.dart';
import 'package:stagess_common_flutter/widgets/enterprise_job_list_tile.dart';
import 'package:stagess_common_flutter/widgets/entity_picker_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/radio_with_follow_up.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';
import 'package:stagess_common_flutter/widgets/web_site_list_tile.dart';

class EnterpriseListTile extends StatefulWidget {
  const EnterpriseListTile({
    super.key,
    required this.enterprise,
    this.isExpandable = true,
    this.forceEditingMode = false,
  });

  final Enterprise enterprise;
  final bool isExpandable;
  final bool forceEditingMode;

  @override
  State<EnterpriseListTile> createState() => EnterpriseListTileState();
}

class EnterpriseListTileState extends State<EnterpriseListTile> {
  final _formKey = GlobalKey<FormState>();
  Future<bool> validate() async {
    if (!_wasDetailsExpanded) return true;

    // We do both like so, so all the fields get validated even if one is not valid
    await _addressController.waitForValidation();
    await _headquartersAddressController.waitForValidation();
    bool isValid = _formKey.currentState?.validate() ?? false;
    isValid = _addressController.isValid && isValid;
    isValid = _headquartersAddressController.isValid && isValid;
    return isValid;
  }

  SchoolBoard? get _currentSchoolBoard =>
      SchoolBoardsProvider.of(context, listen: false).firstWhereOrNull(
        (schoolboard) => schoolboard.id == widget.enterprise.schoolBoardId,
      );
  @override
  void dispose() {
    _nameController.dispose();
    _activityTypeController.dispose();
    _teacherPickerController.dispose();
    _phoneController.dispose();
    _faxController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _headquartersAddressController.dispose();
    _contactFirstNameController.dispose();
    _contactLastNameController.dispose();
    _contactFunctionController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _neqController.dispose();
    super.dispose();
  }

  bool _wasDetailsExpanded = false;
  bool _isExpanded = false;
  bool _isEditing = false;

  late final _nameController = TextEditingController(
    text: widget.enterprise.name,
  );
  late final _enterpriseStatusController =
      RadioWithFollowUpController<EnterpriseStatus>(
        initialValue: widget.enterprise.status,
      );
  late final _activityTypeController = EnterpriseActivityTypeListController(
    initial: widget.enterprise.activityTypes,
  );
  late final _jobControllers = Map.fromEntries(
    widget.enterprise.jobs.map(
      (job) => MapEntry(
        job.id,
        EnterpriseJobListController(
          context: context,
          enterpriseStatus:
              _enterpriseStatusController.value ?? EnterpriseStatus.active,
          job: job.copyWith(),
          reservedForPickerController: EntityPickerController(
            allElementsTitle: 'Tous les enseignant\u00b7e\u00b7s',
            schools: [],
            teachers: [...TeachersProvider.of(context, listen: false)],
            initialId: job.reservedForId,
          ),
        ),
      ),
    ),
  );
  late final _teacherPickerController = TeacherPickerController(
    initial: TeachersProvider.of(context, listen: true).firstWhereOrNull(
      (teacher) => teacher.id == widget.enterprise.recruiterId,
    ),
  );
  late final _phoneController = TextEditingController(
    text: widget.enterprise.phone?.toString(),
  );
  late final _faxController = TextEditingController(
    text: widget.enterprise.fax?.toString(),
  );
  late final _websiteController = TextEditingController(
    text: widget.enterprise.website,
  );
  late final _addressController = AddressController(
    initialValue: widget.enterprise.address,
  );
  late final _headquartersAddressController = AddressController(
    initialValue: widget.enterprise.headquartersAddress,
  );
  late final _contactFirstNameController = TextEditingController(
    text: widget.enterprise.contact.firstName,
  );
  late final _contactLastNameController = TextEditingController(
    text: widget.enterprise.contact.lastName,
  );
  late final _contactFunctionController = TextEditingController(
    text: widget.enterprise.contactFunction,
  );
  late final _contactPhoneController = TextEditingController(
    text: widget.enterprise.contact.phone?.toString(),
  );
  late final _contactEmailController = TextEditingController(
    text: widget.enterprise.contact.email,
  );
  late final _neqController = TextEditingController(
    text: widget.enterprise.neq,
  );

  Enterprise get editedEnterprise => widget.enterprise.copyWith(
    name: _nameController.text,
    status: _enterpriseStatusController.value,
    activityTypes: _activityTypeController.activityTypes,
    recruiterId: _teacherPickerController.teacher?.id ?? '',
    phone: PhoneNumber.fromString(
      _phoneController.text,
      id: widget.enterprise.phone?.id,
    ),
    fax: PhoneNumber.fromString(
      _faxController.text,
      id: widget.enterprise.fax?.id,
    ),
    jobs:
        JobList()..addAll(
          _jobControllers.values.map((jobController) => jobController.job),
        ),
    website: _websiteController.text,
    address: _addressController.address,
    headquartersAddress: _headquartersAddressController.address,
    contact: widget.enterprise.contact.copyWith(
      firstName: _contactFirstNameController.text,
      lastName: _contactLastNameController.text,
      phone: PhoneNumber.fromString(
        _contactPhoneController.text,
        id: widget.enterprise.contact.phone?.id,
      ),
      email: _contactEmailController.text,
    ),
    contactFunction: _contactFunctionController.text,
    neq: _neqController.text,
  );

  @override
  void initState() {
    super.initState();
    if (widget.forceEditingMode) _onClickedEditing();
  }

  Future<void> _onClickedDeleting() async {
    final enterprises = EnterprisesProvider.of(context, listen: false);
    final hasLock = await enterprises.getLockForItem(widget.enterprise);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de supprimer l\'entreprise, car elle est en cours de modification par un autre utilisateur.',
        );
      }
      return;
    }

    // Show confirmation dialog
    final answer = await showDialog(
      context: context,
      builder:
          (context) =>
              ConfirmDeleteEnterpriseDialog(enterprise: widget.enterprise),
    );
    if (answer == null || !answer || !mounted) {
      await enterprises.releaseLockForItem(widget.enterprise);
      return;
    }

    final isSuccess = await enterprises.removeWithConfirmation(
      widget.enterprise,
    );
    if (mounted) {
      showSnackBar(
        context,
        message:
            isSuccess
                ? 'Entreprise supprimée avec succès'
                : 'Échec de la suppression de l\'entreprise',
      );
    }
    await enterprises.releaseLockForItem(widget.enterprise);
  }

  Future<void> _onClickedEditing() async {
    final enterprises = EnterprisesProvider.of(context, listen: false);

    if (_isEditing) {
      // Validate the form
      if (!(await validate()) || !mounted) return;

      // Finish editing
      final newEnterprise = editedEnterprise;
      if (newEnterprise.getDifference(widget.enterprise).isNotEmpty) {
        final isSuccess = await enterprises.replaceWithConfirmation(
          newEnterprise,
        );
        if (mounted) {
          showSnackBar(
            context,
            message:
                isSuccess
                    ? 'Entreprise mise à jour avec succès'
                    : 'Échec de la mise à jour de l\'entreprise',
          );
        }
      }
      await enterprises.releaseLockForItem(widget.enterprise);
    } else {
      final hasLock = await enterprises.getLockForItem(widget.enterprise);
      if (!hasLock || !mounted) {
        if (mounted) {
          showSnackBar(
            context,
            message:
                'Impossible de modifier l\'entreprise, car elle est en cours de modification par un autre utilisateur.',
          );
        }
        return;
      }
    }

    if (mounted) setState(() => _isEditing = !_isEditing);
  }

  @override
  void didUpdateWidget(covariant EnterpriseListTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_enterpriseStatusController.value != widget.enterprise.status) {
      _enterpriseStatusController.forceSet(widget.enterprise.status);
    }
    for (final job in widget.enterprise.jobs) {
      if (!_jobControllers.containsKey(job.id)) {
        _jobControllers[job.id] = EnterpriseJobListController(
          context: context,
          enterpriseStatus:
              _enterpriseStatusController.value ?? EnterpriseStatus.active,
          job: job.copyWith(),
          reservedForPickerController: EntityPickerController(
            allElementsTitle: 'Tous les enseignant·e·s',
            schools: [],
            teachers: [...TeachersProvider.of(context, listen: false)],
            initialId: job.reservedForId,
          ),
        );
      }
    }
    for (final key in _jobControllers.keys) {
      final job = widget.enterprise.jobs.firstWhereOrNull(
        (job) => job.id == key,
      );
      if (job == null) {
        // This job has been removed
        _jobControllers.remove(key);
        return;
      }
      final serializedOldJob = _jobControllers[key]!.job.serialize();
      final serializedNewJob = job.serialize();

      if (areMapsNotEqual(serializedOldJob, serializedNewJob)) {
        _jobControllers[key] = EnterpriseJobListController(
          context: context,
          enterpriseStatus:
              _enterpriseStatusController.value ?? EnterpriseStatus.active,
          job: job.copyWith(),
          reservedForPickerController: EntityPickerController(
            allElementsTitle: 'Tous les enseignant·e·s',
            schools: [],
            teachers: [...TeachersProvider.of(context, listen: false)],
            initialId: job.reservedForId,
          ),
        );
      }
    }

    if (_nameController.text != widget.enterprise.name) {
      _nameController.text = widget.enterprise.name;
    }
    if (_teacherPickerController.teacher?.id != widget.enterprise.recruiterId) {
      _teacherPickerController.teacher = TeachersProvider.of(
        context,
        listen: false,
      ).firstWhereOrNull(
        (teacher) => teacher.id == widget.enterprise.recruiterId,
      );
    }
    if (_addressController.address != widget.enterprise.address) {
      _addressController.address = widget.enterprise.address;
    }
    if (_phoneController.text != widget.enterprise.phone?.toString()) {
      _phoneController.text = widget.enterprise.phone?.toString() ?? '';
    }
    if (_faxController.text != widget.enterprise.fax?.toString()) {
      _faxController.text = widget.enterprise.fax?.toString() ?? '';
    }
    if (_websiteController.text != widget.enterprise.website) {
      _websiteController.text = widget.enterprise.website ?? '';
    }
    if (_headquartersAddressController.address !=
        widget.enterprise.headquartersAddress) {
      _headquartersAddressController.address =
          widget.enterprise.headquartersAddress;
    }
    if (_contactFirstNameController.text !=
        widget.enterprise.contact.firstName) {
      _contactFirstNameController.text = widget.enterprise.contact.firstName;
    }
    if (_contactLastNameController.text != widget.enterprise.contact.lastName) {
      _contactLastNameController.text = widget.enterprise.contact.lastName;
    }
    if (_contactFunctionController.text != widget.enterprise.contactFunction) {
      _contactFunctionController.text = widget.enterprise.contactFunction;
    }
    if (_contactPhoneController.text !=
        widget.enterprise.contact.phone?.toString()) {
      _contactPhoneController.text =
          widget.enterprise.contact.phone?.toString() ?? '';
    }
    if (_contactEmailController.text != widget.enterprise.contact.email) {
      _contactEmailController.text = widget.enterprise.contact.email ?? '';
    }
    if (_neqController.text != widget.enterprise.neq) {
      _neqController.text = widget.enterprise.neq ?? '';
    }
    if (areSetsNotEqual(
      _activityTypeController.activityTypes,
      widget.enterprise.activityTypes,
    )) {
      _activityTypeController.updateActivityTypes({
        ...widget.enterprise.activityTypes,
      }, refresh: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final internships = InternshipsProvider.of(context, listen: true);
    final hasInternship = internships.any(
      (internship) => internship.enterpriseId == widget.enterprise.id,
    );

    return widget.isExpandable
        ? AnimatedExpandingCard(
          initialExpandedState: _isExpanded,
          onTapHeader: (isExpanded) => setState(() => _isExpanded = isExpanded),
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
                      widget.enterprise.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_isExpanded)
                    Row(
                      children: [
                        if (!hasInternship)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: _onClickedDeleting,
                          ),
                        IconButton(
                          icon: Icon(
                            _isEditing ? Icons.save : Icons.edit,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: _onClickedEditing,
                        ),
                      ],
                    ),
                ],
              ),
          child: _buildEditingForm(),
        )
        : _buildEditingForm();
  }

  Widget _buildEditingForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, bottom: 24.0, right: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnterpriseStatus(),
            const SizedBox(height: 8),
            _buildJobs(),
            const SizedBox(height: 8),
            AnimatedExpandingCard(
              elevation: 0.0,
              onTapHeader: (newState) => _wasDetailsExpanded = true,
              header:
                  (ctx, isExpanded) => Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      isExpanded
                          ? 'Détails de l\'entreprise'
                          : 'Plus de détails sur l\'entreprise...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildName(),
                    const SizedBox(height: 8),
                    _buildRecruiter(),
                    const SizedBox(height: 8),
                    _buildAddress(),
                    const SizedBox(height: 8),
                    _buildPhone(),
                    const SizedBox(height: 8),
                    _buildFax(),
                    const SizedBox(height: 8),
                    _buildWebsite(),
                    const SizedBox(height: 8),
                    _buildHeadquartersAddress(),
                    const SizedBox(height: 8),
                    _buildContact(),
                    const SizedBox(height: 8),
                    _buildNeq(),
                    const SizedBox(height: 8),
                    _buildActivityTypes(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildName() {
    return _isEditing
        ? Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Le nom de l\'entreprise est requis'
                            : null,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'entreprise',
                ),
              ),
            ],
          ),
        )
        : Container();
  }

  Widget _buildEnterpriseStatus() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: RadioWithFollowUp(
        elements: EnterpriseStatus.values,
        controller: _enterpriseStatusController,
        enabled: _isEditing,
        onChanged:
            (value) => setState(() {
              _jobControllers.forEach((_, controller) {
                controller.enterpriseStatus =
                    _enterpriseStatusController.value!;
              });
            }),
      ),
    );
  }

  Widget _buildActivityTypes() {
    return EnterpriseActivityTypeListTile(
      controller: _activityTypeController,
      editMode: _isEditing,
    );
  }

  void _addJob() {
    final job = Job.empty;
    setState(
      () =>
          _jobControllers[job.id] = EnterpriseJobListController(
            context: context,
            enterpriseStatus: _enterpriseStatusController.value!,
            job: job,
            reservedForPickerController: EntityPickerController(
              allElementsTitle: 'Tous les enseignant\u00b7e\u00b7s',
              schools: _currentSchoolBoard?.schools ?? [],
              teachers: [...TeachersProvider.of(context, listen: false)],
              initialId: job.reservedForId,
            ),
          ),
    );
  }

  void _deleteJob(String id) {
    setState(() => _jobControllers.remove(id));
  }

  Widget _buildJobs() {
    return Column(
      children: [
        if (_isEditing)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
              child: TextButton(
                onPressed: _addJob,
                child: const Text('Ajouter un nouveau métier'),
              ),
            ),
          ),
        _jobControllers.isEmpty
            ? Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 4.0),
              child: Text('Aucun métier proposé pour le moment.'),
            )
            : Column(
              children: [
                ..._jobControllers.keys.map((jobId) {
                  final hasInternship = InternshipsProvider.of(
                    context,
                    listen: true,
                  ).any(
                    (internship) =>
                        internship.enterpriseId == widget.enterprise.id &&
                        internship.jobId == jobId,
                  );

                  return EnterpriseJobListTile(
                    key: ValueKey(jobId),
                    controller: _jobControllers[jobId]!,
                    schools: _currentSchoolBoard?.schools ?? [],
                    editMode: _isEditing,
                    onRequestDelete:
                        hasInternship ? null : () => _deleteJob(jobId),
                    initialExpandedState:
                        _jobControllers[jobId]!.specialization?.idWithName ==
                        null,
                  );
                }),
              ],
            ),
      ],
    );
  }

  Widget _buildRecruiter() {
    _teacherPickerController.teacher =
        TeachersProvider.of(context, listen: false).firstWhereOrNull(
          (teacher) => teacher.id == widget.enterprise.recruiterId,
        ) ??
        Teacher.empty;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: TeacherPickerTile(
        title: 'Enseignant·e ayant démarché l\'entreprise',
        schoolBoardId: widget.enterprise.schoolBoardId,
        controller: _teacherPickerController,
        editMode: _isEditing,
      ),
    );
  }

  Widget _buildPhone() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: PhoneListTile(
        title: 'Téléphone',
        controller: _phoneController,
        isMandatory: false,
        enabled: _isEditing,
      ),
    );
  }

  Widget _buildFax() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: PhoneListTile(
        title: 'Fax',
        controller: _faxController,
        isMandatory: false,
        enabled: _isEditing,
      ),
    );
  }

  Widget _buildWebsite() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: WebSiteListTile(
        controller: _websiteController,
        title: 'Site web de l\'entreprise',
        enabled: _isEditing,
      ),
    );
  }

  Widget _buildAddress() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: AddressListTile(
        title: 'Adresse de l\'entreprise',
        addressController: _addressController,
        isMandatory: true,
        enabled: _isEditing,
      ),
    );
  }

  Widget _buildHeadquartersAddress() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: AddressListTile(
        title: 'Adresse du siège social',
        addressController: _headquartersAddressController,
        isMandatory: false,
        enabled: _isEditing,
      ),
    );
  }

  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isEditing
            ? Text('Contact')
            : Text(
              'Contact : ${widget.enterprise.contact.toString()} (${widget.enterprise.contactFunction})',
            ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditing)
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
              if (_isEditing)
                TextFormField(
                  controller: _contactFunctionController,
                  decoration: const InputDecoration(
                    labelText: 'Fonction dans l\'entreprise',
                  ),
                ),
              const SizedBox(height: 4),
              PhoneListTile(
                controller: _contactPhoneController,
                isMandatory: false,
                enabled: _isEditing,
              ),
              const SizedBox(height: 4),
              EmailListTile(
                controller: _contactEmailController,
                isMandatory: false,
                enabled: _isEditing,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeq() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: TextFormField(
        controller: _neqController,
        enabled: _isEditing,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'Numéro d\'entreprise (NEQ)',
          labelStyle: TextStyle(color: Colors.black),
        ),
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}
