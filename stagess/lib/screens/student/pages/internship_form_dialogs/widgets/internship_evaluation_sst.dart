import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/forms/sst_evaluation_form_dialog.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/pdf/evaluation_sst_pdf_template.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/widgets/internship_evaluation_card.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

final _logger = Logger('InternshipEvaluationSst');

// TODO Card is opened if they need to do something
class EvaluationSst extends StatelessWidget {
  const EvaluationSst({super.key, required this.internshipId});

  final String internshipId;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building EvaluationSst for job: $internshipId');

    return InternshipEvaluationCard(
        title: 'SST en entreprise',
        internshipId: internshipId,
        evaluateButtonText: 'Évaluer l\'entreprise',
        reevaluateButtonText: 'Évaluer de nouveau',
        evaluations: InternshipsProvider.of(context, listen: true)
            .fromId(internshipId)
            .sstEvaluations,
        onClickedNewEvaluation: () => showInternshipEvaluationFormDialog(
            context,
            internshipId: internshipId,
            showEvaluationDialog: showSstEvaluationFormDialog),
        onClickedShowEvaluation: (evaluationId) =>
            showInternshipEvaluationFormDialog(context,
                internshipId: internshipId,
                evaluationId: evaluationId,
                showEvaluationDialog: showSstEvaluationFormDialog),
        onClickedShowEvaluationPdf: (evaluationId) => showPdfDialog(
              context,
              pdfGeneratorCallback: (context, format) =>
                  generateSstEvaluationPdf(context, format,
                      internshipId: internshipId, evaluationId: evaluationId),
            ));
  }
}
