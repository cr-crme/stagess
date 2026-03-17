import 'package:flutter/material.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';

class AddTextDialog extends StatefulWidget {
  const AddTextDialog({
    super.key,
    required this.title,
    this.maxLength,
  });

  final String title;
  final int? maxLength;

  @override
  State<AddTextDialog> createState() => _AddTextDialogState();
}

class _AddTextDialogState extends State<AddTextDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _comment;

  void _onCancel() {
    Navigator.pop(context);
  }

  void _onConfirm() {
    if (FormService.validateForm(_formKey,
        save: true, showSnackbarError: false)) {
      Navigator.pop(context, _comment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          onSaved: (text) => _comment = text,
          validator: FormService.textNotEmptyValidator,
          keyboardType: TextInputType.multiline,
          minLines: 4,
          maxLines: null,
          maxLength: widget.maxLength,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _onCancel,
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _onConfirm,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
