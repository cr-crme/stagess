import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/admins/admin_list_tile.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';

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
    Navigator.of(context).pop(state.editedAdmin);
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
