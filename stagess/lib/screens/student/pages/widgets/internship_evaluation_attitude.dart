import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/screens/internship_forms/student_steps/attitude_evaluation_form_dialog.dart';
import 'package:stagess/screens/student/pages/pdf/evaluation_attitude_pdf_template.dart';
import 'package:stagess/screens/student/pages/widgets/internship_evaluation_card.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

final _logger = Logger('InternshipEvaluationAttitude');

class EvaluationAttitude extends StatelessWidget {
  const EvaluationAttitude({super.key, required this.internshipId});

  final String internshipId;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building AttitudeEvaluation for internship: $internshipId');

    return InternshipEvaluationCard(
        title: 'C2. Attitudes et comportements',
        internshipId: internshipId,
        evaluateButtonText: 'Évaluer l\'élève',
        reevaluateButtonText: 'Évaluer de nouveau',
        evaluations: InternshipsProvider.of(context, listen: true)
            .fromId(internshipId)
            .attitudeEvaluations,
        onClickedNewEvaluation: () => showInternshipEvaluationFormDialog(
            context,
            internshipId: internshipId,
            showEvaluationDialog: showAttitudeEvaluationDialog),
        onClickedShowEvaluation: (evaluationId) =>
            showInternshipEvaluationFormDialog(context,
                internshipId: internshipId,
                evaluationId: evaluationId,
                showEvaluationDialog: showAttitudeEvaluationDialog),
        onClickedShowEvaluationPdf: (evaluationId) => showPdfDialog(
              context,
              pdfGeneratorCallback: (context, format) =>
                  generateAttitudeEvaluationPdf(context, format,
                      internshipId: internshipId, evaluationId: evaluationId),
            ));
  }
}
