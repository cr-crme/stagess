import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:stagess_admin/screens/admins/confirm_delete_admin_dialog.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class AdminListTile extends StatefulWidget {
  const AdminListTile({
    super.key,
    required this.admin,
    this.isExpandable = true,
    this.forceEditingMode = false,
  });

  final Admin admin;
  final bool isExpandable;
  final bool forceEditingMode;

  @override
  State<AdminListTile> createState() => AdminListTileState();
}

class AdminListTileState extends State<AdminListTile> {
  final _formKey = GlobalKey<FormState>();
  final _radioKey = GlobalKey<FormFieldState>();
  Future<bool> validate() async {
    // We do both like so, so all the fields get validated even if one is not valid
    bool isValid = _formKey.currentState?.validate() ?? false;
    isValid = (_radioKey.currentState?.validate() ?? false) && isValid;
    return isValid;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _forceDisabled = false;
  bool _isExpanded = false;
  bool _isEditing = false;

  late String _selectedSchoolId = widget.admin.schoolBoardId;
  late final _firstNameController = TextEditingController(
    text: widget.admin.firstName,
  );
  late final _lastNameController = TextEditingController(
    text: widget.admin.lastName,
  );
  late final _emailController = TextEditingController(text: widget.admin.email);

  Admin get editedAdmin => widget.admin.copyWith(
    schoolBoardId: _selectedSchoolId,
    firstName: _firstNameController.text,
    lastName: _lastNameController.text,
    email: _emailController.text,
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

    final admins = AdminsProvider.of(context, listen: false);
    final hasLock = await admins.getLockForItem(widget.admin);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de supprimer cet administrateur, car il est en cours de modification par un autre utilisateur.',
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
        message:
            isSuccess
                ? 'L\'administrateur a été supprimé avec succès.'
                : 'Une erreur est survenue lors de la suppression de l\'administrateur.',
      );
    }
    await admins.releaseLockForItem(widget.admin);
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
            message:
                isSuccess
                    ? 'L\'administrateur a été modifié avec succès.'
                    : 'Une erreur est survenue lors de la modification de l\'administrateur.',
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
                'Impossible de modifier cet administrateur, car il est en cours de modification par un autre utilisateur.',
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
    if (_isEditing) return;

    if (_firstNameController.text != widget.admin.firstName) {
      _firstNameController.text = widget.admin.firstName;
    }
    if (_lastNameController.text != widget.admin.lastName) {
      _lastNameController.text = widget.admin.lastName;
    }
    if (_emailController.text != widget.admin.email) {
      _emailController.text = widget.admin.email.toString();
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
                      '${widget.admin.firstName} ${widget.admin.lastName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_isExpanded)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: _forceDisabled ? Colors.grey : Colors.red,
                          ),
                          onPressed: _forceDisabled ? null : _onClickedDeleting,
                        ),
                        IconButton(
                          icon: Icon(
                            _isEditing ? Icons.save : Icons.edit,
                            color:
                                _forceDisabled
                                    ? Colors.grey
                                    : Theme.of(context).primaryColor,
                          ),
                          onPressed: _forceDisabled ? null : _onClickedEditing,
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
            _buildSchoolBoardSelection(),
            const SizedBox(height: 8),
            _buildName(),
            const SizedBox(height: 8),
            _buildEmail(),
            if (!_isEditing &&
                widget.admin.email != null &&
                widget.admin.email!.isNotEmpty)
              Column(
                children: [const SizedBox(height: 8), _buildCreateUserButton()],
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolBoardSelection() {
    final schoolBoards = SchoolBoardsProvider.of(context, listen: true);

    return _isEditing
        ? FormBuilderRadioGroup(
          key: _radioKey,
          initialValue: widget.admin.schoolBoardId,
          name: 'School board selection',
          orientation: OptionsOrientation.vertical,
          decoration: InputDecoration(
            labelText: 'Assigner à un centre de services scolaire',
          ),
          onChanged:
              (value) => setState(() => _selectedSchoolId = value ?? '-1'),
          validator: (_) {
            return _selectedSchoolId == '-1'
                ? 'Sélectionner un centre de services scolaire'
                : null;
          },
          options:
              schoolBoards
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
          if (widget.admin.hasNotRegisteredAccount)
            TextButton(
              onPressed: () async {
                final admins = AdminsProvider.of(context, listen: false);
                final isSuccess = await admins.addUserToDatabase(
                  email: _emailController.text,
                  userType: AccessLevel.admin,
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
          if (widget.admin.hasRegisteredAccount)
            TextButton(
              onPressed: () async {
                final admins = AdminsProvider.of(context, listen: false);
                final isSuccess = await admins.deleteUserFromDatabase(
                  email: _emailController.text,
                  userType: AccessLevel.admin,
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
