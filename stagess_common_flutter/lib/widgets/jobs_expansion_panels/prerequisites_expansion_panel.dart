import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/itemized_text.dart';
import 'package:stagess_common_flutter/widgets/jobs_expansion_panels/enterprise_job_list_tile.dart';

final _logger = Logger('PrerequisitesExpansionPanel');

class PrerequisitesExpansionPanel extends StatefulWidget {
  const PrerequisitesExpansionPanel({
    required super.key,
    required this.job,
    required this.enterprise,
    required this.isEditing,
    required this.onClickSave,
    required this.onClickCancel,
  });

  final Job job;
  final Enterprise enterprise;
  final bool isEditing;
  final Function() onClickSave;
  final Function() onClickCancel;

  @override
  State<PrerequisitesExpansionPanel> createState() =>
      PrerequisitesExpansionPanelState();
}

class PrerequisitesExpansionPanelState
    extends State<PrerequisitesExpansionPanel> {
  late final _ageController = TextEditingController(
    text: widget.job.minimumAge.toString(),
  );
  int get minimumAge =>
      _ageController.text.isEmpty ? -1 : int.parse(_ageController.text);

  late final _preInternshipRequestKey = ValueKey(
    '${widget.job.id}_preinternship_requests',
  );
  late final _preInternshipRequestsController = CheckboxWithOtherController(
    elements: PreInternshipRequestTypes.values,
    initialValues: [
      ...widget.job.preInternshipRequests.requests.map((e) => e.toString()),
      widget.job.preInternshipRequests.other ?? '',
    ],
  );
  List<String> get prerequisites => _preInternshipRequestsController.values;

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing) return;

    if (_ageController.text != widget.job.minimumAge.toString()) {
      _ageController.text = widget.job.minimumAge.toString();
    }

    _preInternshipRequestsController.forceSetIfDifferent(
      comparator: CheckboxWithOtherController(
        elements: PreInternshipRequestTypes.values,
        initialValues: [
          ...widget.job.preInternshipRequests.requests.map((e) => e.toString()),
          widget.job.preInternshipRequests.other ?? '',
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building PrerequisitesExpansionPanel for job: ${widget.job.specialization.name}',
    );

    return AnimatedExpandingCard(
      elevation: 0.0,
      onTapHeader: (nextState) {
        final previousState = !nextState;
        if (widget.isEditing && previousState) widget.onClickCancel();
      },
      tappingPermitted: (isExpanded) => _tappingIsPermitted(context,
          isExpanded: isExpanded, isEditing: widget.isEditing),
      header: (context, isExpanded) => ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Prérequis et équipements'),
            Visibility(
              visible: isExpanded,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: InkWell(
                onTap: widget.onClickSave,
                borderRadius: BorderRadius.circular(25),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    widget.isEditing ? Icons.save : Icons.edit,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMinimumAge(),
            const SizedBox(height: 12),
            _buildEntepriseRequests(),
            const SizedBox(height: 12),
            if (widget.isEditing)
              Center(
                  child: TextButton(
                      onPressed: widget.onClickSave,
                      child: const Text('Enregistrer'))),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimumAge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Âge minimum',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        widget.isEditing
            ? Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 35,
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final current = int.tryParse(value!);
                        if (current == null) return 'Préciser';
                        if (current < 15 || current > 30) {
                          return 'Minimum 15 ans';
                        }
                        return null;
                      },
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const Text(' ans'),
                ],
              )
            : Text('${widget.job.minimumAge} ans'),
      ],
    );
  }

  Widget _buildEntepriseRequests() {
    final requests = widget.job.preInternshipRequests.requests
        .map((e) => e.toString())
        .toList();
    if (widget.job.preInternshipRequests.other != null) {
      requests.add(widget.job.preInternshipRequests.other!);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exigences de l\'entreprise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        widget.isEditing
            ? BuildPrerequisitesCheckboxes(
                checkboxKey: _preInternshipRequestKey,
                controller: _preInternshipRequestsController,
                hideTitle: true,
              )
            : requests.isEmpty
                ? const Text('Aucune exigence particulière')
                : ItemizedText(requests),
      ],
    );
  }
}

Future<bool> _tappingIsPermitted(BuildContext context,
    {required bool isExpanded, required bool isEditing}) async {
  if (!isEditing) return true;

  return await ConfirmExitDialog.show(
    context,
    content: Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: '** Vous quittez la page sans avoir '
                'cliqué sur Enregistrer ',
          ),
          WidgetSpan(
            child: SizedBox(
              height: 22,
              width: 22,
              child: Icon(
                Icons.save,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const TextSpan(
            text: '. **\n\nToutes vos modifications seront perdues.',
          ),
        ],
      ),
    ),
  );
}
