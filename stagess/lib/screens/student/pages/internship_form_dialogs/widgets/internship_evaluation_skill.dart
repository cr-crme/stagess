import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/forms/skill_evaluation_form_dialog.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/pdf/evaluation_skill_pdf_template.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/widgets/internship_evaluation_card.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

final _logger = Logger('InternshipEvaluationSkill');

class EvaluationSkill extends StatelessWidget {
  const EvaluationSkill({
    super.key,
    required this.internshipId,
  });

  final String internshipId;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building EvaluationSkill for internship: $internshipId');

    return InternshipEvaluationCard(
        title: 'C1. Compétences spécifiques du métier',
        internshipId: internshipId,
        evaluateButtonText: 'Évaluer l\'élève',
        reevaluateButtonText: 'Évaluer de nouveau',
        evaluations: InternshipsProvider.of(context, listen: true)
            .fromId(internshipId)
            .skillEvaluations,
        onClickedNewEvaluation: () => showInternshipEvaluationFormDialog(
            context,
            internshipId: internshipId,
            showEvaluationDialog: showSkillEvaluationFormDialog),
        onClickedShowEvaluation: (evaluationId) =>
            showInternshipEvaluationFormDialog(context,
                internshipId: internshipId,
                evaluationId: evaluationId,
                showEvaluationDialog: showSkillEvaluationFormDialog),
        onClickedShowEvaluationPdf: (evaluationId) => showPdfDialog(
              context,
              pdfGeneratorCallback: (context, format) =>
                  generateSkillEvaluationPdf(context, format,
                      internshipId: internshipId, evaluationId: evaluationId),
            ));
  }
}
