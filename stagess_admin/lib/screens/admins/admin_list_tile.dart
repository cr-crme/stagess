import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:stagess_admin/screens/admins/confirm_delete_admin_dialog.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/configuration_service.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class AdminListTile extends StatefulWidget {
  const AdminListTile({
    super.key,
    required this.admin,
    this.forceEditingMode = false,
    required this.canEdit,
    required this.canDelete,
  });

  final Admin admin;
  final bool forceEditingMode;
  final bool canEdit;
  final bool canDelete;

  @override
  State<AdminListTile> createState() => AdminListTileState();
}

class AdminListTileState extends State<AdminListTile> {
  final _formKey = GlobalKey<FormState>();
  final _radioKey = GlobalKey<FormFieldState>();
  Future<bool> validate() async {
    // We do both like so, so all the fields get validated even if one is not valid
    bool isValid = _formKey.currentState?.validate() ?? false;
    isValid =
        (_showSchoolSelection ? _radioKey.currentState!.validate() : true) &&
            isValid;
    return isValid;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  var _fetchFullDataCompleter = Completer<void>();
  bool _forceDisabled = false;
  bool _isExpanded = false;
  bool _isEditing = false;

  bool get _showSchoolSelection =>
      (widget.admin.accessLevel < AccessLevel.schoolBoardAdmin &&
          AuthProvider.of(context, listen: false).databaseAccessLevel >
              AccessLevel.schoolAdmin) ||
      (AuthProvider.of(context, listen: false).databaseAccessLevel >=
          AccessLevel.superAdmin);

  late String _selectedSchoolId = widget.admin.schoolId;
  late final _firstNameController = TextEditingController(
    text: widget.admin.firstName,
  );
  late final _lastNameController = TextEditingController(
    text: widget.admin.lastName,
  );
  late final _phoneController =
      TextEditingController(text: widget.admin.phone.toString());
  late final _emailController = TextEditingController(text: widget.admin.email);

  Admin get editedAdmin => widget.admin.copyWith(
        schoolBoardId: widget.admin.schoolBoardId,
        schoolId: _selectedSchoolId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: PhoneNumber.fromString(_phoneController.text,
            id: widget.admin.phone.id),
        email: _emailController.text,
        accessLevel: widget.admin.schoolBoardId.isEmpty
            ? AccessLevel.superAdmin
            : _selectedSchoolId.isEmpty
                ? AccessLevel.schoolBoardAdmin
                : AccessLevel.schoolAdmin,
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

    final admins = AdminsProvider.of(context, listen: false);
    final hasLock = await admins.getLockForItem(widget.admin);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de supprimer cet administrateur·trice, car il est en cours de modification par un autre utilisateur·trice.',
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
      builder: (context) => ConfirmDeleteAdminDialog(admin: widget.admin),
    );
    if (answer == null || !answer || !mounted) {
      await admins.releaseLockForItem(widget.admin);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    final isSuccess = await admins.removeWithConfirmation(widget.admin);
    if (mounted) {
      showSnackBar(
        context,
        message: isSuccess
            ? 'L\'administrateur·trice a été supprimé·e avec succès. Attention uniquement les données ont été supprimées. '
                'Pour supprimer complètement l\'administrateur·trice, il faut aussi supprimer son compte utilisateur associé via la console de Firebase.'
            : 'Une erreur est survenue lors de la suppression de l\'administrateur·trice.',
      );
    }
    await admins.releaseLockForItem(widget.admin);
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
    final admins = AdminsProvider.of(context, listen: false);

    if (_isEditing) {
      // Validate the form
      if (!(await validate()) || !mounted) {
        setState(() {
          _forceDisabled = false;
        });
        return;
      }
      // Finish editing
      final newAdmin = editedAdmin;
      if (newAdmin.getDifference(widget.admin).isNotEmpty) {
        final isSuccess = await admins.replaceWithConfirmation(newAdmin);
        if (mounted) {
          showSnackBar(
            context,
            message: isSuccess
                ? 'L\'administrateur·trice a été modifié·e avec succès.'
                : 'Une erreur est survenue lors de la modification de l\'administrateur·trice.',
          );
        }
      }
      await admins.releaseLockForItem(widget.admin);
    } else {
      final hasLock = await admins.getLockForItem(widget.admin);
      if (!hasLock || !mounted) {
        if (mounted) {
          showSnackBar(
            context,
            message:
                'Impossible de modifier cet administrateur·trice, car il est en cours de modification par un autre utilisateur·trice.',
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
  void didUpdateWidget(covariant AdminListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.admin.getDifference(editedAdmin).isEmpty) return;

    _firstNameController.text = widget.admin.firstName;
    _lastNameController.text = widget.admin.lastName;
    _phoneController.text = widget.admin.phone.toString();
    _emailController.text = widget.admin.email.toString();
  }

  Future<void> _fetchData() async {
    if (_isExpanded) {
      await AdminsProvider.of(
        context,
        listen: false,
      ).fetchData(id: widget.admin.id, fields: FetchableFields.all);
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
                    '${widget.admin.firstName} ${widget.admin.lastName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_isExpanded)
                  FutureBuilder(
                    future: _fetchFullDataCompleter.future,
                    builder: (context, snapshot) =>
                        snapshot.connectionState == ConnectionState.done
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
                                      onPressed: _forceDisabled
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
                _buildSchoolBoardSelection(),
                const SizedBox(height: 8),
                _buildName(),
                const SizedBox(height: 8),
                _buildPhone(),
                const SizedBox(height: 8),
                _buildEmail(),
                if (!_isEditing && widget.admin.email.isNotEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      _sendResetEmailButton(),
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

  Widget _buildSchoolBoardSelection() {
    if (!_showSchoolSelection) {
      return SizedBox.shrink();
    }

    final schoolBoard = SchoolBoardsProvider.of(context, listen: false)
        .firstWhereOrNull((e) => e.id == widget.admin.schoolBoardId);

    if (schoolBoard == null) return SizedBox.shrink();

    return _isEditing
        ? FormBuilderRadioGroup(
            key: _radioKey,
            initialValue: widget.admin.schoolId,
            name: 'School selection',
            orientation: OptionsOrientation.vertical,
            decoration: InputDecoration(
              labelText: 'Assigner à une école',
            ),
            onChanged: (value) =>
                setState(() => _selectedSchoolId = value ?? ''),
            options: [
              ...(AuthProvider.of(context, listen: false).databaseAccessLevel >=
                      AccessLevel.superAdmin
                  ? [null]
                  : []),
              ...schoolBoard.schools
            ]
                .map(
                  (e) => FormBuilderFieldOption(
                    value: e?.id ?? '',
                    child: Text(e?.name ?? 'Centre de service scolaire'),
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
                validator: (value) =>
                    value?.isEmpty == true ? 'Le prénom est requis' : null,
                maxLength: 50,
                decoration: const InputDecoration(labelText: '* Prénom'),
              ),
              TextFormField(
                controller: _lastNameController,
                validator: (value) =>
                    value?.isEmpty == true ? 'Le nom est requis' : null,
                maxLength: 50,
                decoration:
                    const InputDecoration(labelText: '* Nom de famille'),
              ),
            ],
          )
        : Container();
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
      enabled: _isEditing && widget.forceEditingMode,
      title: 'Courriel',
    );
  }

  Widget _sendResetEmailButton() {
    final authProvider = AuthProvider.of(context, listen: false);
    if (authProvider.databaseAccessLevel <= widget.admin.accessLevel) {
      return SizedBox.shrink();
    }

    final emailType = widget.admin.hasNotRegisteredAccount
        ? 'courriel d\'invitation'
        : 'courriel de réinitialisation du mot de passe';

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () async {
              final admins = AdminsProvider.of(context, listen: false);
              final isSuccess = await admins.addUserToDatabase(
                email: _emailController.text,
                userType: widget.admin.schoolBoardId.isEmpty
                    ? AccessLevel.schoolBoardAdmin
                    : AccessLevel.schoolAdmin,
              );
              if (!mounted) return;

              showSnackBar(
                context,
                message: isSuccess
                    ? 'Un $emailType a été envoyé à ${_emailController.text}.'
                    : 'Échec de l\'envoi du $emailType.',
              );
            },
            child: Text(
              'Envoyer un $emailType',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
