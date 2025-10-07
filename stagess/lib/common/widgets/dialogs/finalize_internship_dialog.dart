import 'package:flutter/material.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

Future<void> showFinalizeInternshipDialog(
  BuildContext context, {
  required String internshipId,
}) async {
  final internships = InternshipsProvider.of(context, listen: false);
  final internship = internships[internshipId];

  final hasLock = await internships.getLockForItem(internship);
  if (!hasLock || !context.mounted) {
    if (context.mounted) {
      showSnackBar(
        context,
        message:
            'Impossible de modifier ce stage, il est peut-être en cours de modification ailleurs.',
      );
    }
    return;
  }

  final editedInternship = await showDialog(
    context: context,
    builder: (context) => FinalizeInternshipDialog(internshipId: internshipId),
  );
  if (editedInternship == null) {
    await internships.releaseLockForItem(internship);
    return;
  }
  await internships.replaceWithConfirmation(editedInternship);

  if (context.mounted) {
    showSnackBar(context, message: 'Le stage a été mis à jour');
  }
  await internships.releaseLockForItem(internship);
}

class FinalizeInternshipDialog extends StatelessWidget {
  const FinalizeInternshipDialog({super.key, required this.internshipId});

  final String internshipId;

  void _saveInternship(
    context,
    GlobalKey<FormState> formKey,
    TextEditingController textController,
  ) async {
    final internship =
        InternshipsProvider.of(context, listen: false)[internshipId];
    if (!formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      internship.copyWith(
        endDate: DateTime.now(),
        achievedDuration: int.parse(textController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final internship =
        InternshipsProvider.of(context, listen: false)[internshipId];
    final hourController = TextEditingController(
      text:
          internship.achievedDuration < 0
              ? '0'
              : internship.achievedDuration.toString(),
    );

    return PopScope(
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: AlertDialog(
            title: const Text('Mettre fin au stage?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Attention, les informations pour ce stage ne seront plus modifiables.\n\n'
                  'Bien vous assurer que le nombre d\'heures réalisées est correct\n',
                ),
                Row(
                  children: [
                    const Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(right: 24.0),
                        child: Text('Nombre d\'heures de stage faites'),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        validator: (value) {
                          return int.tryParse(hourController.text) == null ||
                                  int.parse(hourController.text) == 0
                              ? 'Entrer une valeur'
                              : null;
                        },
                        textAlign: TextAlign.right,
                        controller: hourController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const Text('h'),
                  ],
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Non'),
              ),
              TextButton(
                onPressed:
                    () => _saveInternship(context, formKey, hourController),
                child: const Text('Oui'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
