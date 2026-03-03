import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/forms/enterprise_evaluation_form_dialog.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/pdf/evaluation_enterprise_template.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/widgets/internship_evaluation_card.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

final _logger = Logger('InternshipEvaluationPost');

class EvaluationPost extends StatelessWidget {
  const EvaluationPost({super.key, required this.internshipId});

  final String internshipId;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building EvaluationPost for job: $internshipId');

    return InternshipEvaluationCard(
        title: 'Évaluation de l\'entreprise',
        internshipId: internshipId,
        evaluateButtonText: 'Évaluer l\'entreprise',
        reevaluateButtonText: 'Évaluer de nouveau',
        evaluations: InternshipsProvider.of(context)
            .fromId(internshipId)
            .enterpriseEvaluations,
        onClickedNewEvaluation: () => showInternshipEvaluationFormDialog(
            context,
            internshipId: internshipId,
            showEvaluationDialog: showEnterpriseEvaluationFormDialog),
        onClickedShowEvaluation: (evaluationId) =>
            showInternshipEvaluationFormDialog(context,
                internshipId: internshipId,
                evaluationId: evaluationId,
                showEvaluationDialog: showEnterpriseEvaluationFormDialog),
        onClickedShowEvaluationPdf: (evaluationId) => showPdfDialog(
              context,
              pdfGeneratorCallback: (context, format) =>
                  generateEnterpriseEvaluationPdf(context, format,
                      internshipId: internshipId, evaluationId: evaluationId),
            ));
  }
}
