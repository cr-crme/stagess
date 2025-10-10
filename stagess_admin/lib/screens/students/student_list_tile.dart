import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:stagess_admin/screens/students/confirm_delete_student_dialog.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/address_list_tile.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/birthday_list_tile.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class StudentListTile extends StatefulWidget {
  const StudentListTile({
    super.key,
    required this.student,
    required this.schoolBoard,
    this.isExpandable = true,
    this.forceEditingMode = false,
    required this.canEdit,
    required this.canDelete,
  });

  final Student student;
  final bool isExpandable;
  final bool forceEditingMode;
  final SchoolBoard schoolBoard;
  final bool canEdit;
  final bool canDelete;

  @override
  State<StudentListTile> createState() => StudentListTileState();
}

class StudentListTileState extends State<StudentListTile> {
  final _formKey = GlobalKey<FormState>();
  final _schoolRadioKey = GlobalKey<FormFieldState>();
  final _programRadioKey = GlobalKey<FormFieldState>();
  Future<bool> validate() async {
    // We do both like so, so all the fields get validated even if one is not valid
    await _addressController.waitForValidation();
    await _contactAddressController.waitForValidation();
    bool isValid = _formKey.currentState?.validate() ?? false;
    isValid = (_schoolRadioKey.currentState?.validate() ?? false) && isValid;
    isValid = (_programRadioKey.currentState?.validate() ?? false) && isValid;
    isValid = _addressController.isValid && isValid;
    isValid = _contactAddressController.isValid && isValid;
    return isValid;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _groupController.dispose();
    _emailController.dispose();
    _contactFirstNameController.dispose();
    _contactLastNameController.dispose();
    _contactLinkController.dispose();
    _contactAddressController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  bool _forceDisabled = false;
  bool _isExpanded = false;
  bool _isEditing = false;

  late String _selectedSchoolId = widget.student.schoolId;
  late final _firstNameController = TextEditingController(
    text: widget.student.firstName,
  );
  late final _lastNameController = TextEditingController(
    text: widget.student.lastName,
  );
  late final _birthController = BirthdayController(
    initialValue: widget.student.dateBirth,
  );
  late final _addressController = AddressController(
    initialValue: widget.student.address,
  );
  late final _phoneController = TextEditingController(
    text: widget.student.phone?.toString() ?? '',
  );
  late final _groupController = TextEditingController(
    text: widget.student.group == '-1' ? '' : widget.student.group,
  );
  late Program _selectedProgram = widget.student.program;
  late final _emailController = TextEditingController(
    text: widget.student.email,
  );
  late final _contactFirstNameController = TextEditingController(
    text: widget.student.contact.firstName,
  );
  late final _contactLastNameController = TextEditingController(
    text: widget.student.contact.lastName,
  );
  late final _contactLinkController = TextEditingController(
    text: widget.student.contactLink,
  );
  late final _contactAddressController = AddressController(
    initialValue: widget.student.contact.address,
  );
  late final _contactPhoneController = TextEditingController(
    text: widget.student.contact.phone?.toString() ?? '',
  );
  late final _contactEmailController = TextEditingController(
    text: widget.student.contact.email,
  );

  Student get editedStudent => widget.student.copyWith(
    schoolBoardId: widget.schoolBoard.id,
    schoolId: _selectedSchoolId,
    firstName: _firstNameController.text,
    lastName: _lastNameController.text,
    dateBirth: _birthController.value,
    group: _groupController.text,
    program: _selectedProgram,
    address:
        _addressController.address ??
        Address.empty.copyWith(id: widget.student.address?.id),
    phone: PhoneNumber.fromString(
      _phoneController.text,
      id: widget.student.phone?.id,
    ),
    email: _emailController.text,
    contactLink: _contactLinkController.text,
    contact: widget.student.contact.copyWith(
      firstName: _contactFirstNameController.text,
      lastName: _contactLastNameController.text,
      address:
          _contactAddressController.address ??
          Address.empty.copyWith(id: widget.student.contact.address?.id),
      phone: PhoneNumber.fromString(
        _contactPhoneController.text,
        id: widget.student.contact.phone?.id,
      ),
      email: _contactEmailController.text,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.forceEditingMode) _onClickedEditing();
  }

  Future<void> _onClickedDeleting() async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });

    final students = StudentsProvider.of(context, listen: false);
    final hasLock = await students.getLockForItem(widget.student);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de supprimer cet élève, car il est en cours de modification par un autre utilisateur.',
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
      builder: (context) => ConfirmDeleteStudentDialog(student: widget.student),
    );
    if (answer == null || !answer || !mounted) {
      await students.releaseLockForItem(widget.student);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    final isSuccess = await students.removeWithConfirmation(widget.student);
    if (mounted) {
      showSnackBar(
        context,
        message:
            isSuccess
                ? 'L\'élève a été supprimé avec succès.'
                : 'Une erreur est survenue lors de la suppression de l\'élève.',
      );
    }
    await students.releaseLockForItem(widget.student);
    setState(() {
      _forceDisabled = false;
    });
  }

  Future<void> _onClickedEditing() async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });

    final students = StudentsProvider.of(context, listen: false);

    if (_isEditing) {
      // Validate the form
      if (!(await validate()) || !mounted) {
        setState(() {
          _forceDisabled = false;
        });
        return;
      }

      // Finish editing
      final newStudent = editedStudent;
      if (newStudent.getDifference(widget.student).isNotEmpty) {
        final isSuccess = await students.replaceWithConfirmation(newStudent);
        if (mounted) {
          showSnackBar(
            context,
            message:
                isSuccess
                    ? 'L\'élève a été modifié avec succès.'
                    : 'Une erreur est survenue lors de la modification de l\'élève.',
          );
        }
      }
      await students.releaseLockForItem(widget.student);
    } else {
      final hasLock = await students.getLockForItem(widget.student);
      if (!hasLock || !mounted) {
        if (mounted) {
          showSnackBar(
            context,
            message:
                'Impossible de modifier cet élève, car il est en cours de modification par un autre utilisateur.',
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
  void didUpdateWidget(covariant StudentListTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_firstNameController.text != widget.student.firstName) {
      _firstNameController.text = widget.student.firstName;
    }
    if (_lastNameController.text != widget.student.lastName) {
      _lastNameController.text = widget.student.lastName;
    }

    if (_birthController.value != widget.student.dateBirth) {
      _birthController.updateValue(widget.student.dateBirth);
    }
    if (_addressController.address != widget.student.address) {
      _addressController.address = widget.student.address;
    }
    if (_phoneController.text != widget.student.phone.toString()) {
      _phoneController.text = widget.student.phone.toString();
    }
    if (_emailController.text != widget.student.email) {
      _emailController.text = widget.student.email.toString();
    }

    if (_groupController.text != widget.student.group) {
      _groupController.text =
          widget.student.group == '-1' ? '' : widget.student.group;
    }
    if (_selectedProgram != widget.student.program) {
      _selectedProgram = widget.student.program;
    }

    if (_contactFirstNameController.text != widget.student.contact.firstName) {
      _contactFirstNameController.text = widget.student.contact.firstName;
    }
    if (_contactLastNameController.text != widget.student.contact.lastName) {
      _contactLastNameController.text = widget.student.contact.lastName;
    }
    if (_contactLinkController.text != widget.student.contactLink) {
      _contactLinkController.text = widget.student.contactLink;
    }
    if (_contactAddressController.address != widget.student.contact.address) {
      _contactAddressController.address = widget.student.contact.address;
    }
    if (_contactPhoneController.text !=
        widget.student.contact.phone.toString()) {
      _contactPhoneController.text = widget.student.contact.phone.toString();
    }
    if (_contactEmailController.text != widget.student.contact.email) {
      _contactEmailController.text = widget.student.contact.email.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      '${widget.student.firstName} ${widget.student.lastName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_isExpanded)
                    Row(
                      children: [
                        if (widget.canDelete)
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: _forceDisabled ? Colors.grey : Colors.red,
                            ),
                            onPressed:
                                _forceDisabled ? null : _onClickedDeleting,
                          ),
                        if (widget.canEdit)
                          IconButton(
                            icon: Icon(
                              _isEditing ? Icons.save : Icons.edit,
                              color:
                                  _forceDisabled
                                      ? Colors.grey
                                      : Theme.of(context).primaryColor,
                            ),
                            onPressed:
                                _forceDisabled ? null : _onClickedEditing,
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
        padding: const EdgeInsets.only(left: 24.0, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSchoolSelection(),
            const SizedBox(height: 8),
            _buildName(),
            const SizedBox(height: 8),
            _buildBirthday(),
            const SizedBox(height: 4),
            _buildAddress(),
            const SizedBox(height: 4),
            _buildPhone(),
            const SizedBox(height: 4),
            _buildEmail(),
            const SizedBox(height: 4),
            _buildGroup(),
            const SizedBox(height: 4),
            _buildProgramSelection(),
            const SizedBox(height: 8),
            _buildContact(),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolSelection() {
    return _isEditing
        ? FormBuilderRadioGroup(
          key: _schoolRadioKey,
          initialValue: widget.student.schoolId,
          name: 'School selection',
          orientation: OptionsOrientation.vertical,
          decoration: InputDecoration(labelText: 'Assigner à une école'),
          onChanged:
              (value) => setState(() => _selectedSchoolId = value ?? '-1'),
          validator: (_) {
            return _selectedSchoolId == '-1' ? 'Sélectionner une école' : null;
          },
          options:
              widget.schoolBoard.schools
                  .map(
                    (e) => FormBuilderFieldOption(
                      value: e.id,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
        )
        : Container();
  }

  Widget _buildName() {
    return _isEditing
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _firstNameController,
              validator:
                  (value) =>
                      value?.isEmpty == true ? 'Le prénom est requis' : null,
              decoration: const InputDecoration(labelText: 'Prénom'),
            ),
            TextFormField(
              controller: _lastNameController,
              validator:
                  (value) =>
                      value?.isEmpty == true ? 'Le nom est requis' : null,
              decoration: const InputDecoration(labelText: 'Nom de famille'),
            ),
          ],
        )
        : Container();
  }

  Widget _buildGroup() {
    return _isEditing
        ? TextFormField(
          controller: _groupController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
          ],
          keyboardType: TextInputType.number,
          validator:
              (value) => value?.isEmpty == true ? 'Le groupe est requis' : null,
          decoration: const InputDecoration(labelText: 'Groupe'),
        )
        : Text('Groupe : ${widget.student.group}');
  }

  Widget _buildProgramSelection() {
    return _isEditing
        ? FormBuilderRadioGroup(
          key: _programRadioKey,
          initialValue: widget.student.program,
          name: 'Program selection',
          enabled: _isEditing,
          orientation: OptionsOrientation.vertical,
          decoration: InputDecoration(labelText: 'Assigner à un programme'),
          onChanged:
              (value) =>
                  setState(() => _selectedProgram = value ?? Program.undefined),
          validator: (_) {
            return _selectedProgram == Program.undefined
                ? 'Sélectionner un programme'
                : null;
          },
          options:
              (widget.forceEditingMode ? Program.values : Program.allowedValues)
                  .map(
                    (e) => FormBuilderFieldOption(
                      value: e,
                      child: Text(e.toString()),
                    ),
                  )
                  .toList(),
        )
        : Text('Programme : ${widget.student.program.toString()}');
  }

  Widget _buildBirthday() {
    return BirthdayListTile(
      title: 'Date de naissance',
      controller: _birthController,
      enabled: _isEditing,
      isMandatory: false,
      onSaved: (value) => setState(() {}),
    );
  }

  Widget _buildAddress() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: AddressListTile(
        title: 'Adresse',
        addressController: _addressController,
        isMandatory: false,
        enabled: _isEditing,
      ),
    );
  }

  Widget _buildPhone() {
    return PhoneListTile(
      controller: _phoneController,
      isMandatory: false,
      enabled: _isEditing,
      title: 'Téléphone',
    );
  }

  Widget _buildEmail() {
    return EmailListTile(
      controller: _emailController,
      isMandatory: false,
      enabled: _isEditing,
      title: 'Courriel',
    );
  }

  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isEditing
            ? Text('Contact')
            : Text(
              'Contact : ${widget.student.contact.toString()} (${widget.student.contactLink})',
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
                  controller: _contactLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Lien avec l\'élève',
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Le lien du contact est requis';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 4),
              AddressListTile(
                title: 'Adresse du contact',
                addressController: _contactAddressController,
                isMandatory: false,
                enabled: _isEditing,
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
}
