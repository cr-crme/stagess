import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/common/widgets/numbered_text.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/persons/student_visa.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';

final _logger = Logger('VisaFormDialog');

Future<Student?> showVisaEvaluationFormDialog(
  BuildContext context, {
  required String studentId,
  String? evaluationId,
}) async {
  final newEvaluation = await showDialog<StudentVisa>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: _VisaEvaluationScreen(
        studentId: studentId,
        evaluationId: evaluationId,
      ),
    ),
  );
  if (newEvaluation == null || !context.mounted) return null;

  final student = StudentsProvider.of(context, listen: false).fromId(studentId);

  // Erase the previous visa and replace it by the new one
  return Student.fromSerialized(student.serialize())
    ..allVisa.clear()
    ..allVisa.add(newEvaluation);
}

class VisaFormController {
  static const _formVersion = '1.0.0';

  final String studentId;
  final String? evaluationId;
  final bool canModify;
  final Map<Type, VisaCategoryEnum?> responses = {};

  VisaFormController(
    BuildContext context, {
    required this.studentId,
    this.evaluationId,
    required this.canModify,
  }) {
    if (evaluationId != null) {
      _fillFromPreviousEvaluation(context, previousEvaluationId: evaluationId!);
    }
  }

  void _fillFromPreviousEvaluation(BuildContext context,
      {required String previousEvaluationId}) {
    // Clear previous responses before filling from previous evaluation
    responses.clear();

    final student =
        StudentsProvider.of(context, listen: false).fromId(studentId);
    final visa =
        student.allVisa.firstWhereOrNull((e) => e.id == previousEvaluationId);
    if (visa == null) {
      _logger.warning(
          'No previous evaluation found for student $studentId with evaluationId $previousEvaluationId');
      return;
    }

    responses[Inattendance] = visa.form.inattendance;
    responses[Ponctuality] = visa.form.ponctuality;
    responses[Sociability] = visa.form.sociability;
    responses[Politeness] = visa.form.politeness;
    responses[Motivation] = visa.form.motivation;
    responses[DressCode] = visa.form.dressCode;
    responses[QualityOfWork] = visa.form.qualityOfWork;
    responses[Productivity] = visa.form.productivity;
    responses[Autonomy] = visa.form.autonomy;
    responses[Cautiousness] = visa.form.cautiousness;
    responses[GeneralAppreciation] = visa.form.generalAppreciation;
  }

  StudentVisa toVisa() {
    return StudentVisa(
      form: VisaEvaluation(
        inattendance: responses[Inattendance]! as Inattendance,
        ponctuality: responses[Ponctuality]! as Ponctuality,
        sociability: responses[Sociability]! as Sociability,
        politeness: responses[Politeness]! as Politeness,
        motivation: responses[Motivation]! as Motivation,
        dressCode: responses[DressCode]! as DressCode,
        qualityOfWork: responses[QualityOfWork]! as QualityOfWork,
        productivity: responses[Productivity]! as Productivity,
        autonomy: responses[Autonomy]! as Autonomy,
        cautiousness: responses[Cautiousness]! as Cautiousness,
        generalAppreciation:
            responses[GeneralAppreciation]! as GeneralAppreciation,
      ),
      formVersion: _formVersion,
    );
  }
}

class _VisaEvaluationScreen extends StatefulWidget {
  const _VisaEvaluationScreen({
    required this.studentId,
    required this.evaluationId,
  });

  final String studentId;
  final String? evaluationId;

  @override
  State<_VisaEvaluationScreen> createState() => _VisaEvaluationScreenState();
}

class _VisaEvaluationScreenState extends State<_VisaEvaluationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _controller = widget.evaluationId == null
      ? VisaFormController(context,
          studentId: widget.studentId,
          evaluationId: StudentsProvider.of(context, listen: false)
              .fromId(widget.studentId)
              .allVisa
              .lastOrNull
              ?.id,
          canModify: true)
      : (StudentsProvider.of(context, listen: false)
                  .fromId(widget.studentId)
                  .allVisa
                  .firstWhereOrNull((e) => e.id == widget.evaluationId) ==
              null
          ? VisaFormController(context,
              studentId: widget.studentId, canModify: false)
          : VisaFormController(context,
              studentId: widget.studentId,
              evaluationId: widget.evaluationId!,
              canModify: false));

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building AttitudeEvaluationScreen for student: ${widget.studentId}',
    );

    final student = StudentsHelpers.studentsInMyGroups(context)
        .firstWhereOrNull((e) => e.id == widget.studentId);

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            student == null
                ? 'En attente des informations'
                : 'Génération du visa pour ${student.firstName} ${student.lastName}',
          ),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: student == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildExperiencesAndAptitude(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _controlBuilder(),
                ],
              ),
      ),
    );
  }

  Future<void> _submit() async {
    _logger.info('Submitting attitude evaluation form');

    if (!_controller.canModify) {
      Navigator.of(context).pop();
      return;
    }

    if (!(_formKey.currentState?.validate() ?? true)) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => const AlertDialog(
          title: Text('Formulaire incomplet'),
          content: Text('Répondre à toutes les questions.'),
        ),
      );
      return;
    }

    _logger.fine('Visa evaluation form submitted successfully');
    Navigator.of(context).pop(_controller.toVisa());
  }

  void _cancel() async {
    _logger.info('Cancel called');

    if (_controller.canModify) {
      final answer = await ConfirmExitDialog.show(
        context,
        content: const Text('Toutes les modifications seront perdues.'),
      );
      if (!mounted || !answer) return;
    }

    _logger.fine('User confirmed exit, navigating back');
    Navigator.of(context).pop(null);
  }

  Widget _controlBuilder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_controller.canModify)
            OutlinedButton(
              onPressed: _cancel,
              child: const Text('Annuler'),
            ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: _submit,
            child: Text(_controller.canModify ? 'Enregistrer' : 'Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildExperiencesAndAptitude() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubTitle('Expériences et aptitudes', left: 0.0),
        Text(
          'Expériences et aptitudes personnelles et scolaires complémentaires au '
          'profil d’employabilité',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8.0),
        NumberedText([
          'Inscrire les activités scolaires, parascolaires et extrascolaires '
              'pertinentes en employabilité en donnant des précisions, telles que '
              'le nom de l’organisme ou l’entreprise concernée et l’année.',
          'Cocher celles à afficher dans le VISA en PDF (maximum de 8 items).'
        ]),
      ],
    );
  }
}
