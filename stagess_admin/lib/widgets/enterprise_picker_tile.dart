import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/widgets/autocomplete_options_builder.dart';

class EnterprisePickerController {
  TextEditingController? _enterpriseTextController;

  Enterprise _selectedEnterprise;
  Enterprise get enterprise => _selectedEnterprise;
  set enterprise(Enterprise value) {
    _selectedEnterprise = value;
    _enterpriseTextController?.text = value.name;
    _enterpriseFormKey.currentState?.didChange(value);
    _jobFormKey.currentState?.didChange(Job.empty);
  }

  Job? _job;
  Job get job => _job ?? Job.empty;
  void setJob(Specialization? specialization) {
    if (specialization == null) {
      _job = null;
      _jobFormKey.currentState?.didChange(Job.empty);
      return;
    }
    _job = _selectedEnterprise.jobs
        .firstWhereOrNull((job) => job.specialization.id == specialization.id);
  }

  EnterprisePickerController({
    required Enterprise? initialEnterprise,
    required String? initialSelectedSpecializationId,
  }) : _selectedEnterprise = initialEnterprise ?? Enterprise.empty {
    enterprise = _selectedEnterprise;
    setJob(initialSelectedSpecializationId != null
        ? _selectedEnterprise.jobs
            .firstWhereOrNull((job) =>
                job.specialization.id == initialSelectedSpecializationId)
            ?.specialization
        : (_selectedEnterprise.jobs.length == 1
            ? _selectedEnterprise.jobs.first.specialization
            : null));
  }

  final _enterpriseFormKey = GlobalKey<FormFieldState<Enterprise>>();
  final _jobFormKey = GlobalKey<FormFieldState<Job>>();

  void dispose() {
    // Since _textController is managed by the FormField, we don't need to
    // dispose of it here.
  }
}

class EnterprisePickerTile extends StatelessWidget {
  const EnterprisePickerTile({
    super.key,
    this.title,
    required this.schoolBoardId,
    required this.controller,
    required this.editMode,
    this.onChanged,
  });

  final String? title;
  final String schoolBoardId;
  final EnterprisePickerController controller;
  final bool editMode;
  final Function(Enterprise?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormField<Enterprise>(
          key: controller._enterpriseFormKey,
          initialValue: controller._selectedEnterprise,
          builder: (field) => _enterpriseBuilder(context, field),
          enabled: editMode,
        ),
        FormField<Job>(
          key: controller._jobFormKey,
          builder: (field) => _jobBuilder(context, field),
          enabled: editMode,
        ),
      ],
    );
  }

  Widget _enterpriseBuilder(
    BuildContext context,
    FormFieldState<Enterprise> state,
  ) {
    final enterprises = EnterprisesProvider.of(context, listen: true).where(
      (enterprise) =>
          enterprise.schoolBoardId == schoolBoardId &&
          enterprise.jobs.isNotEmpty,
    );

    return Autocomplete<Enterprise>(
      initialValue: TextEditingValue(text: controller._selectedEnterprise.name),
      optionsBuilder: (textEditingValue) {
        // We kind of hijack this builder to test the current status of the text.
        // If it fits a enterprise, or if it is empty, we set that value to the
        // current selection.
        if (textEditingValue.text.isEmpty) {
          controller._selectedEnterprise = Enterprise.empty;
          controller.setJob(null);
          if (onChanged != null) onChanged!(null);
        } else {
          final selectedEnterprise = enterprises.firstWhereOrNull(
            (enterprise) =>
                enterprise.name.toLowerCase() ==
                textEditingValue.text.toLowerCase(),
          );
          if (selectedEnterprise != null) {
            controller._selectedEnterprise = selectedEnterprise;
            if (controller._selectedEnterprise.jobs.length == 1) {
              controller.setJob(
                  controller._selectedEnterprise.jobs.first.specialization);
            } else {
              controller.setJob(null);
            }

            if (onChanged != null) onChanged!(selectedEnterprise);
          }
        }

        // We show everything if there is no text. Otherwise, we show only if
        // the names containing that approach the text.
        if (textEditingValue.text.isEmpty) return enterprises;
        return enterprises.where(
          (enterprise) =>
              enterprise.name.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ) &&
              enterprise.name.toLowerCase() !=
                  textEditingValue.text.toLowerCase(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) =>
          OptionsBuilderForAutocomplete(
        onSelected: onSelected,
        options: options,
        optionToString: (Enterprise e) => e.name,
      ),
      onSelected: (item) {
        controller.enterprise = item;
        if (controller.enterprise.jobs.length == 1) {
          controller.setJob(controller.enterprise.jobs.first.specialization);
        } else {
          controller.setJob(null);
        }
        if (onChanged != null) onChanged!(item);
      },
      fieldViewBuilder: (_, textController, focusNode, onSubmitted) {
        controller._enterpriseTextController = textController;

        return TextField(
          controller: controller._enterpriseTextController,
          focusNode: focusNode,
          readOnly: false,
          enabled: editMode,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: title ?? 'Sélectionner une entreprise',
            labelStyle: const TextStyle(color: Colors.black),
            errorText: state.errorText,
            suffixIcon: IconButton(
              onPressed: () {
                if (focusNode.hasFocus) focusNode.previousFocus();
                controller.enterprise = Enterprise.empty;
                textController.clear();
                state.didChange(Enterprise.empty);
              },
              icon: const Icon(Icons.clear),
            ),
          ),
        );
      },
    );
  }

  Widget _jobBuilder(BuildContext context, FormFieldState<Job> state) {
    return controller._selectedEnterprise.jobs.isEmpty
        ? Container()
        : FormBuilderRadioGroup(
            name: 'job',
            validator: (value) =>
                value == null ? 'Sélectionner un métier' : null,
            initialValue: controller._job?.specialization.name ??
                (controller._selectedEnterprise.jobs.length == 1
                    ? controller
                        ._selectedEnterprise.jobs.first.specialization.name
                    : null),
            enabled: editMode,
            onChanged: (value) => controller.setJob(controller
                ._selectedEnterprise.jobs
                .firstWhere((job) => job.specialization.name == value)
                .specialization),
            options: controller._selectedEnterprise.jobs
                .map(
                  (job) =>
                      FormBuilderFieldOption(value: job.specialization.name),
                )
                .toList(),
          );
  }
}
