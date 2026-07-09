import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/enterprises/enterprise_list_tile.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/widgets/dialogs/help_dialog.dart';

class AddEnterpriseDialog extends StatefulWidget {
  const AddEnterpriseDialog({super.key, required this.schoolBoard});

  final SchoolBoard schoolBoard;

  @override
  State<AddEnterpriseDialog> createState() => _AddEnterpriseDialogState();
}

class _AddEnterpriseDialogState extends State<AddEnterpriseDialog> {
  final _editingKey = GlobalKey();

  Future<void> _onClickedConfirm() async {
    final state = _editingKey.currentState as EnterpriseListTileState;

    // Validate the form
    final isValid = await state.validate();
    if (!isValid || !mounted) return;

    final isSuccess = await EnterprisesProvider.of(
      context,
      listen: false,
    ).addWithConfirmation(state.editedEnterprise);
    if (!mounted) return;

    if (!isSuccess) {
      await showHelpDialog(
        context,
        title: 'Échec de l\'ajout de l\'entreprise',
        content: Text(
            'Impossible d\'ajouter l\'entreprise. Assurez-vous que toutes les informations '
            'sont correctes et que vous avez le droit de faire cette action.'),
      );
      return;
    }

    Navigator.of(context).pop(isSuccess);
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
                  'Nouvelle entreprise',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
              Text('Compléter les informations'),
              const SizedBox(height: 8),
              EnterpriseListTile(
                key: _editingKey,
                enterprise: Enterprise.empty
                    .copyWith(schoolBoardId: widget.schoolBoard.id),
                forceEditingMode: true,
                canEdit: false,
                canDelete: false,
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: _onClickedCancel, child: Text('Annuler')),
        TextButton(onPressed: _onClickedConfirm, child: Text('Enregistrer')),
      ],
    );
  }
}
