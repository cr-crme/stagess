import 'package:flutter/material.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common_flutter/widgets/jobs_expansion_panels/enterprise_job_list_tile.dart';

class AddJobButton extends StatelessWidget {
  const AddJobButton({
    super.key,
    required this.controllers,
    this.onJobAdded,
    this.style,
  });

  final List<EnterpriseJobListController> controllers;
  final ButtonStyle? style;
  final Function()? onJobAdded;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
        key: key,
        onPressed: () {
          controllers.add(EnterpriseJobListController(
              context: context,
              enterpriseStatus: EnterpriseStatus.active,
              job: Job.empty));
          if (onJobAdded != null) {
            onJobAdded!();
          }
        },
        style: style,
        icon: const Icon(Icons.business_center_rounded),
        label: Text(controllers.isEmpty
            ? 'Ajouter un métier'
            : 'Ajouter un autre métier'));
  }
}
