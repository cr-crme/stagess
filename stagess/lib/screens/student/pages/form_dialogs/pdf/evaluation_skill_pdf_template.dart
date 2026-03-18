import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/common/pdf_widgets/pdf_check_boxes.dart';
import 'package:stagess/common/pdf_widgets/pdf_evaluation_date.dart';
import 'package:stagess/common/pdf_widgets/pdf_text_box.dart';
import 'package:stagess/common/pdf_widgets/pdf_theme.dart';
import 'package:stagess/common/pdf_widgets/pdf_were_present.dart';
import 'package:stagess/screens/student/pages/form_dialogs/forms/skill_evaluation_form_dialog.dart';
import 'package:stagess_common/models/internships/task_appreciation.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';

final _logger = Logger('GenerateSkillEvaluationPdf');

Future<Uint8List> generateSkillEvaluationPdf(
    BuildContext context, PdfPageFormat format,
    {required String internshipId, required String evaluationId}) async {
  _logger.info('Generating skill evaluation PDF for internship: $internshipId');

  final controller = SkillEvaluationFormController.fromInternshipId(
    context,
    internshipId: internshipId,
    evaluationId: evaluationId,
    canModify: false,
  );
  final internship = controller.internship(context, listen: false);
  final student =
      StudentsProvider.of(context, listen: false).fromId(internship.studentId);

  final document = pw.Document(pageMode: PdfPageMode.outlines);

  document.addPage(
    pw.MultiPage(
      build: (pw.Context context) => [
        pw.Center(child: PdfTheme.titleLarge('Évaluation de l\'attitude')),
        pw.SizedBox(height: 12),
        PdfTheme.titleMedium('Informations générales'),
        PdfEvaluationDate(evaluationDate: controller.evaluationDate),
        pw.SizedBox(height: 12),
        PdfWerePresentAtMeeting(
            werePresent: controller.wereAtMeeting,
            studentName: student.fullName),
        pw.SizedBox(height: 24),
        ...controller.skillResults().expand((e) => [
              pw.NewPage(),
              pw.Padding(
                  padding: pw.EdgeInsets.only(top: 24),
                  child: _buildSkillTile(skill: e, controller: controller)),
            ]),
        pw.SizedBox(height: 24),
        _buildGeneralComments(controller: controller),
      ],
    ),
  );

  return document.save();
}

pw.Widget _buildSkillTile({
  required Skill skill,
  required SkillEvaluationFormController controller,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      PdfTheme.titleMedium(skill.name),
      PdfTheme.titleSmall('L\'élève a réussi les tâches suivantes'),
      pw.SizedBox(height: 4),
      PdfCheckBoxes(
          options: controller.taskCompleted[skill.id]!.map(
              (task, taskAppreciation) => MapEntry(task.toString(),
                  taskAppreciation == TaskAppreciationLevel.evaluated))),
      if (controller.skillCommentsControllers[skill.id]?.text != null)
        pw.SizedBox(height: 8),
      PdfTheme.titleSmall('Commentaires'),
      PdfTheme.bodyMedium(controller.skillCommentsControllers[skill.id]!.text),
      pw.SizedBox(height: 8),
      PdfTheme.titleSmall('Appréciation générale de la compétence'),
      PdfTheme.bodyMedium(
          controller.appreciations[skill.id]?.name ?? 'Non évaluée'),
    ],
  );
}

pw.Widget _buildGeneralComments(
    {required SkillEvaluationFormController controller}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      PdfTheme.titleMedium('Commentaires généraux'),
      PdfTextBox(
          child: PdfTheme.bodyMedium(controller.commentsController.text)),
    ],
  );
}
