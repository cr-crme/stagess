import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:stagess_admin/screens/teachers/confirm_delete_teacher_dialog.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/configuration_service.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/address_list_tile.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class TeacherListTile extends StatefulWidget {
  const TeacherListTile({
    super.key,
    required this.teacher,
    required this.schoolBoard,
    this.forceEditingMode = false,
    required this.canEdit,
    required this.canDelete,
  });

  final Teacher teacher;
  final SchoolBoard schoolBoard;
  final bool forceEditingMode;
  final bool canEdit;
  final bool canDelete;

  @override
  State<TeacherListTile> createState() => TeacherListTileState();
}

class TeacherListTileState extends State<TeacherListTile> {
  final _formKey = GlobalKey<FormState>();
  final _radioKey = GlobalKey<FormFieldState>();
  Future<bool> validate() async {
    // We do both like so, so all the fields get validated even if one is not valid
    await _addressController.waitForValidation();
    bool isValid = _formKey.currentState?.validate() ?? false;
    isValid = (_radioKey.currentState?.validate() ?? false) && isValid;
    isValid = _addressController.isValid && isValid;
    return isValid;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    for (var controller in _currentGroups) {
      controller.dispose();
    }
    super.dispose();
  }

  var _fetchFullDataCompleter = Completer<void>();
  bool _forceDisabled = false;
  bool _isExpanded = false;
  bool _isEditing = false;

  late String _selectedSchoolId = widget.teacher.schoolId;
  late final _firstNameController = TextEditingController(
    text: widget.teacher.firstName,
  );
  late final _lastNameController = TextEditingController(
    text: widget.teacher.lastName,
  );
  late final List<TextEditingController> _currentGroups = [
    for (var group in widget.teacher.groups) TextEditingController(text: group),
  ];
  late final _addressController = AddressController(
    initialValue: widget.teacher.address,
  );
  late final _phoneController = TextEditingController(
    text: widget.teacher.phone?.toString() ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.teacher.email,
  );

  Teacher get editedTeacher => widget.teacher.copyWith(
    schoolId: _selectedSchoolId,
    schoolBoardId: widget.schoolBoard.id,
    firstName: _firstNameController.text,
    lastName: _lastNameController.text,
    address:
        _addressController.address ??
        Address.empty.copyWith(id: widget.teacher.address?.id),
    phone: PhoneNumber.fromString(
      _phoneController.text,
      id: widget.teacher.phone?.id,
    ),
    email: _emailController.text,
    groups:
        _currentGroups.map((e) => e.text).where((e) => e.isNotEmpty).toList(),
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

    final teachers = TeachersProvider.of(context, listen: false);
    final hasLock = await teachers.getLockForItem(widget.teacher);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de supprimer cet enseignant, car il est en cours de modification par un autre utilisateur',
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
      builder: (context) => ConfirmDeleteTeacherDialog(teacher: widget.teacher),
    );
    if (answer == null || !answer || !mounted) {
      await teachers.releaseLockForItem(widget.teacher);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    final isSuccess = await teachers.removeWithConfirmation(widget.teacher);
    if (mounted) {
      showSnackBar(
        context,
        message:
            isSuccess
                ? 'Enseignant supprimé avec succès'
                : 'Échec de la suppression de l\'enseignant',
      );
    }
    await teachers.releaseLockForItem(widget.teacher);
    if (!mounted) return;
    setState(() {
      _forceDisabled = false;
    });
  }

  Future<void> _onClickedEditing() async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });

    final teachers = TeachersProvider.of(context, listen: false);

    if (_isEditing) {
      // Validate the form
      if (!(await validate()) || !mounted) {
        setState(() {
          _forceDisabled = false;
        });
        return;
      }

      // Finish editing
      final newTeacher = editedTeacher;
      if (newTeacher.getDifference(widget.teacher).isNotEmpty) {
        final isSuccess = await teachers.replaceWithConfirmation(newTeacher);
        if (mounted) {
          showSnackBar(
            context,
            message:
                isSuccess
                    ? 'Enseignant modifié avec succès'
                    : 'Échec de la modification de l\'enseignant',
          );
        }
      }
      await teachers.releaseLockForItem(widget.teacher);
    } else {
      final hasLock = await teachers.getLockForItem(widget.teacher);
      if (!hasLock || !mounted) {
        if (mounted) {
          showSnackBar(
            context,
            message:
                'Impossible de modifier cet enseignant, car il est en cours de modification par un autre utilisateur.',
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
  void didUpdateWidget(covariant TeacherListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEditing) return;

    if (_firstNameController.text != widget.teacher.firstName) {
      _firstNameController.text = widget.teacher.firstName;
    }
    if (_lastNameController.text != widget.teacher.lastName) {
      _lastNameController.text = widget.teacher.lastName;
    }

    if (_addressController.address != widget.teacher.address) {
      if (widget.teacher.address == null) {
        _addressController.address = null;
      } else {
        _addressController.setAddressAndForceValidated(widget.teacher.address!);
      }
    }
    if (_phoneController.text != (widget.teacher.phone?.toString() ?? '')) {
      _phoneController.text = widget.teacher.phone?.toString() ?? '';
    }
    if (_emailController.text != widget.teacher.email) {
      _emailController.text = widget.teacher.email.toString();
    }

    if (areListsNotEqual(
      _currentGroups.map((e) => e.text).toList(),
      widget.teacher.groups,
    )) {
      for (var controller in _currentGroups) {
        controller.dispose();
      }
      _currentGroups.clear();
      for (var group in widget.teacher.groups) {
        _currentGroups.add(TextEditingController(text: group));
      }
    }
  }

  Future<void> _fetchData() async {
    if (_isExpanded) {
      await TeachersProvider.of(
        context,
        listen: false,
      ).fetchData(id: widget.teacher.id, fields: FetchableFields.all);
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
                      '${widget.teacher.firstName} ${widget.teacher.lastName}',
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
                                  : const SizedBox.shrink(),
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
                _buildSchoolSelection(),
                const SizedBox(height: 8),
                _buildName(),
                const SizedBox(height: 8),
                _buildAddress(),
                const SizedBox(height: 8),
                _buildPhone(),
                const SizedBox(height: 8),
                _buildEmail(),
                const SizedBox(height: 8),
                _buildGroups(),
                if (!_isEditing &&
                    widget.teacher.email != null &&
                    widget.teacher.email!.isNotEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildCreateUserButton(),
                    ],
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSchoolSelection() {
    return _isEditing
        ? FormBuilderRadioGroup(
          key: _radioKey,
          initialValue: widget.teacher.schoolId,
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

  Widget _buildGroups() {
    if (widget.teacher.groups.isEmpty && !_isEditing) {
      return const Text('Aucun groupe');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isEditing)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _currentGroups.length; i++)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currentGroups[i],
                        keyboardType: TextInputType.number,
                        decoration:
                            i == 0
                                ? const InputDecoration(labelText: 'Groupes')
                                : null,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          () => setState(() => _currentGroups.removeAt(i)),
                      icon: Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed:
                        () => setState(
                          () => _currentGroups.add(TextEditingController()),
                        ),
                    child: const Text('Ajouter un groupe'),
                  ),
                ),
              ),
            ],
          ),
        if (!_isEditing) Text('Groupes : ${widget.teacher.groups.join(', ')}'),
      ],
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
      isMandatory: true,
      enabled: _isEditing,
      title: 'Courriel',
    );
  }

  Widget _buildCreateUserButton() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.teacher.hasNotRegisteredAccount)
            TextButton(
              onPressed: () async {
                final admins = AdminsProvider.of(context, listen: false);
                final isSuccess = await admins.addUserToDatabase(
                  email: _emailController.text,
                  userType: AccessLevel.teacher,
                );
                if (!mounted) return;

                showSnackBar(
                  context,
                  message:
                      isSuccess
                          ? 'Compte utilisateur créé avec succès.'
                          : 'Échec de la création du compte utilisateur.',
                );
              },
              child: const Text('Créer un compte'),
            ),
          if (widget.teacher.hasRegisteredAccount)
            TextButton(
              onPressed: () async {
                final admins = AdminsProvider.of(context, listen: false);
                final isSuccess = await admins.deleteUserFromDatabase(
                  email: _emailController.text,
                  userType: AccessLevel.teacher,
                );
                if (!mounted) return;

                showSnackBar(
                  context,
                  message:
                      isSuccess
                          ? 'Compte utilisateur supprimé avec succès.'
                          : 'Échec de la suppression du compte utilisateur.',
                );
              },
              child: const Text('Supprimer un compte'),
            ),
        ],
      ),
    );
  }
}
