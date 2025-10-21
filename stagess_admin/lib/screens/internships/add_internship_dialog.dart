import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/internships/internship_list_tile.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';

class AddInternshipDialog extends StatefulWidget {
  const AddInternshipDialog({super.key, required this.schoolBoard});

  final SchoolBoard schoolBoard;

  @override
  State<AddInternshipDialog> createState() => _AddInternshipDialogState();
}

class _AddInternshipDialogState extends State<AddInternshipDialog> {
  final _editingKey = GlobalKey();

  Future<void> _onClickedConfirm() async {
    final state = _editingKey.currentState as InternshipListTileState;

    // Validate the form
    if (!(await state.validate()) || !mounted) return;
    Navigator.of(context).pop(state.editedInternship);
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
                  'Nouveau stage',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 12),
              Text('Compléter les informations'),
              const SizedBox(height: 8),
              InternshipListTile(
                key: _editingKey,
                internship: Internship.empty.copyWith(
                  schoolBoardId: widget.schoolBoard.id,
                ),
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
        TextButton(onPressed: _onClickedConfirm, child: Text('Confirmer')),
      ],
    );
  }
}
