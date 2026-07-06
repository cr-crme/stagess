import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/teachers/teacher_list_tile.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/dialogs/help_dialog.dart';

class AddTeacherDialog extends StatefulWidget {
  const AddTeacherDialog({super.key, required this.schoolBoardId});

  final String schoolBoardId;

  @override
  State<AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<AddTeacherDialog> {
  final _editingKey = GlobalKey();

  Future<void> _onClickedConfirm() async {
    final state = _editingKey.currentState as TeacherListTileState;

    // Validate the form
    if (!(await state.validate()) || !mounted) return;
    final newTeacher = state.editedTeacher;

    final isConfirmed = await TeachersProvider.of(context, listen: false)
        .addWithConfirmation(newTeacher);
    if (!mounted) return;

    if (!isConfirmed) {
      await showHelpDialog(
        context,
        title: 'Échec de l\'ajout de l\'enseignant·e',
        content: Text(
            'Impossible d\'ajouter l\'enseignant·e. Assurez-vous que toutes les '
            'informations sont correctes et que le courriel est valide et unique.'),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _onClickedCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: false);

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
                  'Nouveau·elle enseignant·e',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
              Text('Compléter les informations personnelles'),
              const SizedBox(height: 8),
              TeacherListTile(
                key: _editingKey,
                teacher: Teacher.empty.copyWith(
                    schoolBoardId: widget.schoolBoardId,
                    schoolId: authProvider.databaseAccessLevel <
                            AccessLevel.schoolBoardAdmin
                        ? authProvider.schoolId
                        : null),
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
