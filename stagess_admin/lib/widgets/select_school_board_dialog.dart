import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

Future<SchoolBoard?> showSelectSchoolBoardDialog(BuildContext context) async {
  final authProvider = AuthProvider.of(context, listen: false);
  var schoolBoardId = authProvider.schoolBoardId;
  if (schoolBoardId == null || schoolBoardId.isEmpty) {
    if (authProvider.databaseAccessLevel == AccessLevel.superAdmin) {
      final answer = await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => SelectSchoolBoardDialog(),
      );
      if (answer is! String || !context.mounted) return null;
      schoolBoardId = answer;
    } else {
      showSnackBar(
        context,
        message:
            'Aucun Centre de services scolaire n\'est associé à votre compte.',
      );
      return null;
    }
  }

  final schoolBoard = SchoolBoardsProvider.of(
    context,
  ).firstWhereOrNull((e) => e.id == schoolBoardId);
  if (schoolBoard == null) {
    showSnackBar(context, message: 'Centre de services scolaire introuvable.');
    return null;
  }

  return schoolBoard;
}

class SelectSchoolBoardDialog extends StatefulWidget {
  const SelectSchoolBoardDialog({super.key});

  @override
  State<SelectSchoolBoardDialog> createState() =>
      _SelectSchoolBoardDialogState();
}

class _SelectSchoolBoardDialogState extends State<SelectSchoolBoardDialog> {
  final _formKey = GlobalKey<FormState>();

  String _selectedSchoolBoardId = '';

  Future<void> _onClickedConfirm() async {
    // Validate the form
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    Navigator.of(context).pop(_selectedSchoolBoardId);
  }

  void _onClickedCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final schoolBoards = SchoolBoardsProvider.of(context, listen: false);

    return AlertDialog(
      content: Form(
        key: _formKey,
        child: FormBuilderRadioGroup(
          name: 'School board selection',
          orientation: OptionsOrientation.vertical,
          decoration: InputDecoration(
            labelText: 'Sélectionner un Centre de services scolaire',
          ),
          onChanged: (value) =>
              setState(() => _selectedSchoolBoardId = value ?? '-1'),
          validator: (_) {
            return _selectedSchoolBoardId == ''
                ? 'Sélectionner un Centre de services scolaire'
                : null;
          },
          options: schoolBoards
              .map(
                (e) => FormBuilderFieldOption(
                  value: e.id,
                  child: Text(e.name),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: _onClickedCancel, child: Text('Annuler')),
        TextButton(onPressed: _onClickedConfirm, child: Text('Confirmer')),
      ],
    );
  }
}
