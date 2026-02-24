import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('TeacherListTile');

class TeacherListTile extends StatefulWidget {
  const TeacherListTile({
    super.key,
    required this.teacher,
    this.forceEditingMode = false,
  });

  final Teacher teacher;
  final bool forceEditingMode;

  @override
  State<TeacherListTile> createState() => TeacherListTileState();
}

class TeacherListTileState extends State<TeacherListTile> {
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
    for (var controller in _currentGroups) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _forceDisabled = false;
  bool _isEditing = false;

  late final _firstNameController = TextEditingController(
    text: widget.teacher.firstName,
  );
  late final _lastNameController = TextEditingController(
    text: widget.teacher.lastName,
  );
  late final List<TextEditingController> _currentGroups = [
    for (var group in widget.teacher.groups) TextEditingController(text: group),
  ];
  late final _phoneController = TextEditingController(
    text: widget.teacher.phone?.toString() ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.teacher.email,
  );

  Teacher get editedTeacher => widget.teacher.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        address: Address.empty.copyWith(id: widget.teacher.address?.id),
        phone: PhoneNumber.fromString(
          _phoneController.text,
          id: widget.teacher.phone?.id,
        ),
        email: _emailController.text,
        groups: _currentGroups
            .map((e) => e.text)
            .where((e) => e.isNotEmpty)
            .toList(),
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

    final teachers = TeachersProvider.of(context, listen: false);

    if (_isEditing) {
      _logger.info('Finishing editing for teacher ${widget.teacher.id}');
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
        await teachers.replaceWithConfirmation(newTeacher);

        _logger.fine('Teacher ${widget.teacher.id} updated');
      }
      await teachers.releaseLockForItem(widget.teacher);
      if (!mounted) {
        setState(() {
          _forceDisabled = false;
        });
        return;
      }
      showSnackBar(context, message: 'Enseignant·e mis à jour');
    } else {
      final hasLock = await teachers.getLockForItem(widget.teacher);
      if (!hasLock || !mounted) {
        _logger.warning('Could not get lock for teacher ${widget.teacher.id}');
        if (mounted) {
          showSnackBar(
            context,
            message:
                'Impossible de modifier cet·te enseignant·e, car iel est en cours de modification par un autre utilisateur.',
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
  void didUpdateWidget(covariant TeacherListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.teacher.getDifference(editedTeacher).isEmpty) return;

    _firstNameController.text = widget.teacher.firstName;
    _lastNameController.text = widget.teacher.lastName;
    _phoneController.text = widget.teacher.phone?.toString() ?? '';
    _emailController.text = widget.teacher.email ?? '';
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
              '${widget.teacher.firstName} ${widget.teacher.lastName}',
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
            _buildGroups(),
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
              ),
              TextFormField(
                controller: _lastNameController,
                validator: (value) =>
                    value?.isEmpty == true ? 'Le nom est requis' : null,
                decoration: const InputDecoration(labelText: 'Nom de famille'),
              ),
            ],
          )
        : Container();
  }

  Widget _buildGroups() {
    return Text(
      widget.teacher.groups.isEmpty
          ? 'Aucun groupe ne vous est assigné'
          : 'Groupes : ${widget.teacher.groups.join(', ')}',
    );
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

  Future<void> _changePasswordDialog() async {
    _logger.info(
      'Change password dialog opened for teacher ${widget.teacher.id}',
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
                Text(
                  'Le mot de passe doit contenir au moins 8 caractères.',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Entrer le nouveau mot de passe',
                  ),
                  obscureText: true,
                  validator: (value) {
                    return FormService.passwordValidator(value);
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
                    email: widget.teacher.email ?? '',
                    password: oldPasswordController.text,
                  );
                } catch (e) {
                  _logger.severe('Failed to reauthenticate user: $e');
                  if (!context.mounted) return;
                  showSnackBar(
                    context,
                    message: 'L\'ancien mot de passe est incorrect',
                  );
                  return;
                }
                if (!context.mounted) return;

                await authProvider.updatePassword(newPasswordController.text);
                if (!context.mounted) return;
                Navigator.of(context).pop(true);
              },
              child: Text('Confirmer'),
            ),
          ],
        );
      },
    );
    if (response == null || !mounted) return;

    _logger.info('Changing password for teacher ${widget.teacher.id}');
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
