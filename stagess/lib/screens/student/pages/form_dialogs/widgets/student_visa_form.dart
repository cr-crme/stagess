import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/screens/student/pages/form_dialogs/forms/show_forms.dart';
import 'package:stagess/screens/student/pages/form_dialogs/forms/visa_evaluation_form_dialog.dart';
import 'package:stagess/screens/student/pages/form_dialogs/pdf/visa_pdf_template.dart';
import 'package:stagess_common/models/persons/student_visa.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('StudentVisaForm');

class StudentVisaForm extends StatefulWidget {
  const StudentVisaForm({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentVisaForm> createState() => _StudentVisaFormState();
}

class _StudentVisaFormState extends State<StudentVisaForm> {
  static const _interline = 12.0;

  List<StudentVisa> get _evaluations =>
      StudentsProvider.of(context, listen: false)
          .fromId(widget.studentId)
          .allVisa;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building StudentVisaForm for ${widget.studentId}',
    );

    final evaluation = _evaluations.lastOrNull;

    return AnimatedExpandingCard(
      header: (ctx, isExpanded) => ListTile(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            'VISA et certifications',
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(color: Colors.black),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, top: 8.0, right: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _evaluations.isEmpty
                  ? 'Aucune information renseignée.'
                  : 'Des informations ont été ajoutées au VISA.\n'
                      'Dernière modification le\u00a0: ${DateFormat.yMMMEd('fr_CA').format(evaluation!.date)}',
            ),
            SizedBox(height: 16.0),
            _buildModifyFormButton(),
            SizedBox(height: 16),
            _buildSelectShowPreviousEvaluations(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModifyFormButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline, right: _interline * 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () async => await _showEvaluationDialog(
              evaluationId: _evaluations.lastOrNull?.id, canModify: true),
          child: const Text('Modifier'),
        ),
      ),
    );
  }

  Widget _buildSelectShowPreviousEvaluations() {
    final orderedEvaluations = _evaluations.sortedBy((e) => e.date).reversed;

    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (orderedEvaluations.isNotEmpty)
            Text('Voir les versions du VISA',
                style: TextStyle(fontWeight: FontWeight.bold)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: orderedEvaluations.map(
              (evaluation) {
                // Reminder the list is reversed for display
                return Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        '\u2022 ${DateFormat('dd MMMM yyyy', 'fr_CA').format(evaluation.date)}',
                      ),
                    ),
                    IconButton(
                        onPressed: () => _showEvaluationDialog(
                            evaluationId: evaluation.id, canModify: false),
                        color: Theme.of(context).primaryColor,
                        icon: const Icon(Icons.insert_drive_file)),
                    SizedBox(width: 4),
                    IconButton(
                        onPressed: () => showPdfDialog(context,
                            pdfGeneratorCallback: (context, format) =>
                                generateVisaPdf(context, format,
                                    studentId: widget.studentId,
                                    studentVisa: evaluation)),
                        color: Theme.of(context).primaryColor,
                        icon: const Icon(Icons.picture_as_pdf)),
                  ],
                );
              },
            ).toList(),
          )
        ],
      ),
    );
  }

  Future<void> _showEvaluationDialog(
      {required String? evaluationId, required bool canModify}) async {
    await showStudentEvaluationFormDialog(context,
        studentId: widget.studentId,
        evaluationId: evaluationId,
        canModify: canModify,
        showEvaluationDialog: showVisaEvaluationFormDialog);
  }
}
