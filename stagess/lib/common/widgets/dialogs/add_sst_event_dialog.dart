import 'package:flutter/material.dart';
import 'package:stagess/common/widgets/form_fields/text_with_form.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

enum SstEventType {
  severe,
  verbal,
  minor;

  String get description {
    switch (this) {
      case SstEventType.severe:
        return 'Blessure grave : l\'élève a dû aller à l\'hôpital pour recevoir des soins';
      case SstEventType.verbal:
        return 'Agression verbale ou harcèlement par des collègues ou des clients';
      case SstEventType.minor:
        return 'Blessure mineure de l\'élève\n(p. ex. brûlure légère)';
    }
  }
}

class AddSstEventDialog extends StatefulWidget {
  const AddSstEventDialog({super.key});

  @override
  State<AddSstEventDialog> createState() => _AddSstEventDialogState();
}

class _AddSstEventDialogState extends State<AddSstEventDialog> {
  final _formKey = GlobalKey<FormState>();

  SstEventType? _eventType;
  String? _description;

  void _onCancel() {
    Navigator.pop(context);
  }

  void _onConfirm() {
    if (_eventType == null) {
      showSnackBar(context, message: 'Sélectionner un type d\'incident.');
      return;
    }

    if (FormService.validateForm(
      _formKey,
      save: true,
      showSnackbarError: true,
    )) {
      Navigator.pop(context, {
        'eventType': _eventType,
        'description': _description,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Signaler un incident'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: RadioGroup(
            groupValue: _eventType,
            onChanged: (value) => setState(() => _eventType = value),
            child: Column(
              children: [
                RadioListTile(
                  title: Text(
                    SstEventType.severe.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: SstEventType.severe,
                ),
                RadioListTile(
                  title: Text(
                    SstEventType.verbal.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: SstEventType.verbal,
                ),
                RadioListTile(
                  title: Text(
                    SstEventType.minor.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: SstEventType.minor,
                ),
                const SizedBox(height: 12),
                TextWithForm(
                  title: 'Raconter ce qu\'il s\'est passé:',
                  onSaved: (text) => setState(() => _description = text),
                  validator:
                      (text) =>
                          text?.isEmpty ?? true ? 'Que s\'est-il passé?' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: _onCancel, child: const Text('Annuler')),
        TextButton(onPressed: _onConfirm, child: const Text('Confirmer')),
      ],
    );
  }
}
