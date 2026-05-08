import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/admins/admin_list_tile.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';

class AddAdminDialog extends StatefulWidget {
  const AddAdminDialog({super.key});

  @override
  State<AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<AddAdminDialog> {
  final _editingKey = GlobalKey();

  Future<void> _onClickedConfirm() async {
    final state = _editingKey.currentState as AdminListTileState;

    // Validate the form
    if (!(await state.validate()) || !mounted) return;
    final newAdmin = state.editedAdmin;

    final isConfirmed = await AdminsProvider.of(context, listen: false)
        .addWithConfirmation(newAdmin);
    if (!mounted) return;

    if (!isConfirmed) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Échec de l\'ajout de l\'administrateur·trice'),
          content: SizedBox(
            width: ResponsiveService.maxBodyWidth * 0.6,
            child: Text(
                'Impossible d\'ajouter l\'administrateur·trice. Assurez-vous que toutes les '
                'informations sont correctes et que le courriel est valide et unique.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }

    if (!mounted) return;
    final admins = AdminsProvider.of(context, listen: false);
    final isSuccess = await admins.addUserToDatabase(
      email: newAdmin.email,
      userType: AccessLevel.admin,
    );

    if (!mounted) return;
    if (!isSuccess) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Échec de l\'envoi du courriel de création de compte'),
          content: SizedBox(
            width: ResponsiveService.maxBodyWidth * 0.6,
            child: Text(
                'L\'administrateur·trice a été ajouté·e à la base de données, '
                'mais l\'envoi du courriel de création de compte a échoué. '
                'Veuillez contacter le support pour résoudre ce problème.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _onClickedCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: ResponsiveService.maxBodyWidth,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  'Nouveau·elle administrateur·trice',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
              Text('Compléter les informations personnelles'),
              const SizedBox(height: 8),
              AdminListTile(
                key: _editingKey,
                admin: Admin.empty,
                forceEditingMode: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: _onClickedCancel, child: Text('Annuler')),
        TextButton(onPressed: _onClickedConfirm, child: Text('Confirmer')),
      ],
    );
  }
}
