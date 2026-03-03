import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_contract.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';

final _logger = Logger('InternshipManagingContractFormDialog');

Future<Internship?> showManagingContractFormDialog(
  BuildContext context, {
  required String internshipId,
  String? evaluationId,
}) async {
  final newContract = await showDialog<InternshipContract?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (ctx) => Dialog(
          child: _InternshipDetailsScreen(
            rootContext: context,
            internshipId: internshipId,
            contractId: evaluationId,
          ),
        ),
      ),
    ),
  );
  if (newContract == null || !context.mounted) return null;

  final internship =
      InternshipsProvider.of(context, listen: false).fromId(internshipId);
  return Internship.fromSerialized(internship.serialize())
    ..contracts.add(newContract);
}

class InternshipContractFormController {
  DateTime creationDate = DateTime.now();
  InternshipContractFormController({required this.internshipId});
  final String internshipId;
  Internship internship(BuildContext context, {bool listen = true}) =>
      InternshipsProvider.of(context, listen: listen)[internshipId];

  factory InternshipContractFormController.fromInternshipId(
    BuildContext context, {
    required String internshipId,
    required String contractId,
  }) {
    Internship internship =
        InternshipsProvider.of(context, listen: false)[internshipId];
    InternshipContract contract =
        internship.contracts.firstWhere((e) => e.id == contractId);

    final controller = InternshipContractFormController(
      internshipId: internshipId,
    );

    controller.creationDate = contract.date;

    return controller;
  }

  bool get isCompleted => true;

  InternshipContract toInternshipEvaluation() {
    return InternshipContract(
      date: creationDate,
      formVersion: InternshipContract.currentVersion,
    );
  }
}

class _InternshipDetailsScreen extends StatefulWidget {
  const _InternshipDetailsScreen({
    required this.rootContext,
    required this.internshipId,
    required this.contractId,
  });

  final BuildContext rootContext;
  final String internshipId;
  final String? contractId;

  @override
  State<_InternshipDetailsScreen> createState() =>
      _InternshipDetailsScreenState();
}

class _InternshipDetailsScreenState extends State<_InternshipDetailsScreen> {
  bool get _editMode => widget.contractId == null;

  late final _formController = _editMode
      ? InternshipContractFormController(internshipId: widget.internshipId)
      : InternshipContractFormController.fromInternshipId(context,
          internshipId: widget.internshipId, contractId: widget.contractId!);

  void _cancel() async {
    _logger.info('Cancelling InternshipDetailsDialog');
    final answer = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
      isEditing: _editMode,
    );
    if (!mounted || !answer) return;

    _logger.fine('User confirmed cancellation, closing dialog');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(null);
  }

  Future<void> _submit() async {
    _logger.info('Submitting internship contract form');
    if (!_editMode) {
      Navigator.of(widget.rootContext).pop(null);
      return;
    }

    if (!_formController.isCompleted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => const AlertDialog(
          title: Text('Formulaire incomplet'),
          content: Text('Répondre à toutes les questions avec un *.'),
        ),
      );
      return;
    }

    _logger.fine('Internship contract form submitted successfully');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext)
        .pop(_formController.toInternshipEvaluation());
  }

  Widget _controlBuilder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_editMode)
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: OutlinedButton(
                  onPressed: _cancel, child: const Text('Annuler')),
            ),
          TextButton(
              onPressed: _submit,
              child: Text(_editMode ? 'Enregistrer' : 'Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building InternshipContractScreen for internship: ${_formController.internshipId}',
    );

    final internship =
        InternshipsProvider.of(context)[_formController.internshipId];
    final student = StudentsHelpers.studentsInMyGroups(
      context,
    ).firstWhereOrNull((e) => e.id == internship.studentId);

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${student == null ? 'En attente des informations' : 'Évaluation de ${student.fullName}'}\nC2. Attitudes - Comportements',
          ),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: student == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CreationDate(
                                formController: _formController,
                                editMode: _editMode),
                            const SubTitle('Situation de travail', left: 0.0),
                          ],
                        ),
                      ),
                    ),
                    _controlBuilder(),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CreationDate extends StatefulWidget {
  const _CreationDate({required this.formController, required this.editMode});

  final InternshipContractFormController formController;
  final bool editMode;

  @override
  State<_CreationDate> createState() => _CreationDateState();
}

class _CreationDateState extends State<_CreationDate> {
  void _promptDate(BuildContext context) async {
    final newDate = await showCustomDatePicker(
      helpText: 'Sélectionner la date',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      context: context,
      initialDate: widget.formController.creationDate,
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (newDate == null) return;

    widget.formController.creationDate = newDate;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Date de création du contrat', left: 0.0),
        Row(
          children: [
            Text(
              DateFormat(
                'dd MMMM yyyy',
                'fr_CA',
              ).format(widget.formController.creationDate),
            ),
            if (widget.editMode)
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.blue,
                ),
                onPressed: () => _promptDate(context),
              ),
          ],
        ),
      ],
    );
  }
}
