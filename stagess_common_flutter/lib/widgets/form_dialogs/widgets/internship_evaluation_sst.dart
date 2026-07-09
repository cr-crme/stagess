import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/forms/show_forms.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/forms/sst_evaluation_form_dialog.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/pdf/evaluation_sst_pdf_template.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/widgets/internship_evaluation_card.dart';

final _logger = Logger('InternshipEvaluationSst');

class EvaluationSst extends StatelessWidget {
  const EvaluationSst({super.key, required this.internshipId});

  final String internshipId;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building EvaluationSst for job: $internshipId');

    final internship =
        InternshipsProvider.of(context, listen: true).fromId(internshipId);

    return InternshipEvaluationCard(
        title: 'SST en entreprise',
        internshipId: internshipId,
        evaluateButtonText: 'Évaluer la SST',
        reevaluateButtonText: 'Réévaluer la SST',
        isInitiallyExpanded: false,
        evaluations: internship.sstEvaluations,
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
