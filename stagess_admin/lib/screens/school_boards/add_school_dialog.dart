import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/school_boards/school_list_tile.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';

class AddSchoolDialog extends StatefulWidget {
  const AddSchoolDialog({super.key, required this.schoolBoard});

  final SchoolBoard schoolBoard;

  @override
  State<AddSchoolDialog> createState() => _AddSchoolDialogState();
}

class _AddSchoolDialogState extends State<AddSchoolDialog> {
  final _editingKey = GlobalKey();

  Future<void> _onClickedConfirm() async {
    final state = _editingKey.currentState as SchoolListTileState;

    // Validate the form
    if (!(await state.validate()) || !mounted) return;
    Navigator.of(context).pop(state.editedSchool);
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
                  'Nouvelle école',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
              Text('Compléter les informations'),
              const SizedBox(height: 8),
              SchoolListTile(
                key: _editingKey,
                school: School.empty,
                schoolBoard: widget.schoolBoard,
                isExpandable: false,
                forceEditingMode: true,
                canDelete: false,
                canEdit: false,
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
