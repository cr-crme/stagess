import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/itemized_text.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('AdminProfileListTile');

class AdminProfileListTile extends StatefulWidget {
  const AdminProfileListTile({
    super.key,
    required this.admin,
    this.forceEditingMode = false,
  });

  final Admin admin;
  final bool forceEditingMode;

  @override
  State<AdminProfileListTile> createState() => _AdminProfileListTileState();
}

class _AdminProfileListTileState extends State<AdminProfileListTile> {
  final _formKey = GlobalKey<FormState>();
  Future<bool> validate() async {
    // We do both like so, so all the fields get validated even if one is not valid
    bool isValid = _formKey.currentState?.validate() ?? false;
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

  bool _forceDisabled = false;
  bool _isEditing = false;

  late final _firstNameController = TextEditingController(
    text: widget.admin.firstName,
  );
  late final _lastNameController = TextEditingController(
    text: widget.admin.lastName,
  );
  late final _phoneController = TextEditingController(
    text: widget.admin.phone.toString(),
  );
  late final _emailController = TextEditingController(
    text: widget.admin.email,
  );

  Admin get editedAdmin => widget.admin.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        address: Address.empty.copyWith(id: widget.admin.address.id),
        phone: PhoneNumber.fromString(_phoneController.text,
            id: widget.admin.phone.id),
        email: _emailController.text,
      );

  @override
  void initState() {
    super.initState();
    if (widget.forceEditingMode) _onClickedEditing();
  }

  Future<void> _onClickedEditing() async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });

    final admins = AdminsProvider.of(context, listen: false);

    if (_isEditing) {
      _logger.info('Finishing editing for admin ${widget.admin.id}');
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
        await admins.replaceWithConfirmation(newAdmin);

        _logger.fine('Admin ${widget.admin.id} updated');
      }
      await admins.releaseLockForItem(widget.admin);
      if (!mounted) {
        setState(() {
          _forceDisabled = false;
        });
        return;
      }
      showSnackBar(context, message: 'Admininistrateur·trice mis à jour');
    } else {
      final hasLock = await admins.getLockForItem(widget.admin);
      if (!hasLock || !mounted) {
        _logger.warning('Could not get lock for admin ${widget.admin.id}');
        if (mounted) {
          showSnackBar(
            context,
            message:
                'Impossible de modifier cet·te administrateur·trice, car iel est en cours de modification par un autre utilisateur.',
          );
        }
        setState(() {
          _forceDisabled = false;
        });
        return;
      }
    }

    setState(() {
      _isEditing = !_isEditing;
      _forceDisabled = false;
    });
  }

  @override
  void didUpdateWidget(covariant AdminProfileListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.admin.getDifference(editedAdmin).isEmpty) return;

    _firstNameController.text = widget.admin.firstName;
    _lastNameController.text = widget.admin.lastName;
    _phoneController.text = widget.admin.phone.toString();
    _emailController.text = widget.admin.email;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedExpandingCard(
      initialExpandedState: true,
      elevation: 0.0,
      onTapHeader: null,
      canChangeExpandedState: false,
      header: (ctx, isExpanded) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8, bottom: 8),
            child: Text(
              '${widget.admin.firstName} ${widget.admin.lastName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.save : Icons.edit,
                  color: _forceDisabled
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
    );
  }

  Widget _buildEditingForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildName(),
            const SizedBox(height: 8),
            _buildPhone(),
            const SizedBox(height: 8),
            _buildEmail(),
            const SizedBox(height: 8),
            _buildAccessLevelDisplayer(),
            const SizedBox(height: 8),
            _buildChangePasswordButton(),
          ],
        ),
      ),
    );
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
                decoration: const InputDecoration(labelText: 'Prénom'),
                maxLength: 50,
              ),
              TextFormField(
                controller: _lastNameController,
                validator: (value) =>
                    value?.isEmpty == true ? 'Le nom est requis' : null,
                decoration: const InputDecoration(labelText: 'Nom de famille'),
                maxLength: 50,
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
      title: 'Téléphone professionnel',
    );
  }

  Widget _buildEmail() {
    return EmailListTile(
      controller: _emailController,
      isMandatory: true,
      enabled: false,
      title: 'Courriel',
    );
  }

  Widget _buildAccessLevelDisplayer() {
    return Text(
      'Le niveau d\'accès de ce compte est : ${switch (widget.admin.accessLevel) {
        AccessLevel.superAdmin => 'Super administrateur',
        AccessLevel.schoolBoardAdmin =>
          'Administrateur de Centre de services scolaire',
        AccessLevel.schoolAdmin => 'Administrateur d\'école',
        AccessLevel.teacherAdmin => 'Administrateur enseignant',
        AccessLevel.teacher => 'Enseignant',
        AccessLevel.self => 'Utilisateur',
        AccessLevel.invalid => 'Invalide',
      }}',
    );
  }

  Future<void> _changePasswordDialog() async {
    _logger.info(
      'Change password dialog opened for admin ${widget.admin.id}',
    );

    final formKey = GlobalKey<FormState>();
    final authProvider = AuthProvider.of(context, listen: false);
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final response = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Entrer l\'ancien mot de passe',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'L\'ancien mot de passe est requis';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.0),
                Text('Le mot de passe doit contenir\u00a0:'),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ItemizedText([
                    'Au moins 8 caractères',
                    'Au moins 1 lettre majuscule',
                    'Au moins 1 lettre minuscule',
                    'Au moins 1 chiffre',
                    'Au moins 1 caractère spécial',
                  ]),
                ),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Entrer le nouveau mot de passe',
                  ),
                  obscureText: true,
                  validator: (value) {
                    return FormService.strongPasswordValidator(value);
                  },
                ),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                // Validate the form
                if (!(formKey.currentState!.validate()) || !mounted) return;

                // Reconnected
                try {
                  await authProvider.signInWithEmailAndPassword(
                    email: widget.admin.email,
                    password: oldPasswordController.text,
                  );
                } catch (_) {
                  _logger.severe('Failed to reauthenticate user');
                  if (!context.mounted) return;
                  showSnackBar(
                    context,
                    message: 'L\'ancien mot de passe est incorrect',
                  );
                  return;
                }
                if (!context.mounted) return;

                final isSuccess = await authProvider
                    .updatePassword(newPasswordController.text);
                if (!context.mounted) return;

                if (isSuccess) {
                  Navigator.of(context).pop(true);
                } else {
                  _logger.severe('Failed to update password');
                  showSnackBar(
                    context,
                    message:
                        'Une erreur est survenue lors de la mise à jour du mot de passe',
                  );
                }
              },
              child: Text('Confirmer'),
            ),
          ],
        );
      },
    );
    if (response == null || !mounted) return;

    _logger.info('Changing password for admin ${widget.admin.id}');
  }

  Widget _buildChangePasswordButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: TextButton(
          onPressed: _changePasswordDialog,
          child: const Text('Changer le mot de passe'),
        ),
      ),
    );
  }
}
