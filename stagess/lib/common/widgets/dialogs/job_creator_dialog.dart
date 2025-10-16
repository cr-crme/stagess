import 'package:flutter/material.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/enterprise_job_list_tile.dart';

class JobCreatorDialog extends StatefulWidget {
  const JobCreatorDialog({super.key, required this.enterprise});

  final Enterprise enterprise;

  @override
  State<JobCreatorDialog> createState() => _JobCreatorDialogState();
}

class _JobCreatorDialogState extends State<JobCreatorDialog> {
  final _formKey = GlobalKey<FormState>();

  void _onCancel() {
    Navigator.pop(context);
  }

  void _onConfirm() {
    if (FormService.validateForm(
      _formKey,
      save: true,
      showSnackbarError: true,
    )) {
      Navigator.pop(context, controller.job);
    }
  }

  late final controller = EnterpriseJobListController(
    context: context,
    enterpriseStatus: widget.enterprise.status,
    job: Job.empty,
    specializationBlackList:
        widget.enterprise.jobs.map((e) => e.specialization).toList(),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PopScope(
        child: AlertDialog(
          title: const Text('Ajouter un nouveau poste'),
          content: Form(
            key: _formKey,
            child: EnterpriseJobListTile(
              controller: controller,
              schools: [
                SchoolBoardsProvider.of(context, listen: false).currentSchool!,
              ],
              elevation: 0,
              canChangeExpandedState: false,
              initialExpandedState: true,
              editMode: true,
              showHeader: false,
              availabilityIsMandatory: true,
            ),
          ),
          actions: [
            OutlinedButton(onPressed: _onCancel, child: const Text('Annuler')),
            TextButton(onPressed: _onConfirm, child: const Text('Confirmer')),
          ],
        ),
      ),
    );
  }
}
