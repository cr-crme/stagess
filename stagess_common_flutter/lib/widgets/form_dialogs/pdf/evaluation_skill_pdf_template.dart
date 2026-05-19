import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/internships/task_appreciation.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/forms/skill_evaluation_form_dialog.dart';
import 'package:stagess_common_flutter/widgets/pdf_widgets/pdf_check_boxes.dart';
import 'package:stagess_common_flutter/widgets/pdf_widgets/pdf_evaluation_date.dart';
import 'package:stagess_common_flutter/widgets/pdf_widgets/pdf_radio_buttons.dart';
import 'package:stagess_common_flutter/widgets/pdf_widgets/pdf_text_box.dart';
import 'package:stagess_common_flutter/widgets/pdf_widgets/pdf_theme.dart';
import 'package:stagess_common_flutter/widgets/pdf_widgets/pdf_were_present.dart';

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

  Specialization specialization = ActivitySectorsService.specializationOrNull(
      internship.currentContract?.specializationId)!;

  List<Specialization> extraSpecializations = internship
          .currentContract?.extraSpecializationIds
          .map((id) => ActivitySectorsService.specializationOrNull(id))
          .where((e) => e != null)
          .cast<Specialization>()
          .toList() ??
      [];

  final document = pw.Document(pageMode: PdfPageMode.outlines);

  document.addPage(
    pw.MultiPage(
      build: (pw.Context context) => [
        pw.Center(child: PdfTheme.titleLarge('Évaluation des compétences')),
        pw.SizedBox(height: 12),
        PdfTheme.titleMedium('Informations générales'),
        PdfEvaluationDate(evaluationDate: controller.evaluationDate),
        pw.SizedBox(height: 12),
        PdfWerePresentAtMeeting(
            werePresent: controller.wereAtMeeting,
            studentName: student.fullName),
        pw.SizedBox(height: 12),
        _buildSkillsCheckboxes(
            title: 'Métier principal',
            controller: controller,
            specialization: specialization),
        ...extraSpecializations.asMap().entries.map((entry) => pw.Padding(
            padding: pw.EdgeInsets.only(top: 24),
            child: _buildSkillsCheckboxes(
              title: 'Métier supplémentaire ${entry.key + 1}',
              controller: controller,
              specialization: entry.value,
            ))),
        pw.SizedBox(height: 12),
        _evaluationType(controller: controller),
        pw.SizedBox(height: 24),
        ...controller.skillResults().expand((e) => [
              pw.NewPage(),
              pw.Padding(
                  padding: pw.EdgeInsets.only(top: 24),
                  child: switch (controller.evaluationGranularity) {
                    SkillEvaluationGranularity.global =>
                      _buildSkillTileGlobal(skill: e, controller: controller),
                    SkillEvaluationGranularity.byTask =>
                      _buildSkillTileByTask(skill: e, controller: controller),
                  }),
            ]),
        pw.SizedBox(height: 24),
        _buildGeneralComments(controller: controller),
      ],
    ),
  );

  return document.save();
}

pw.Widget _buildSkillHeader({required Skill skill}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      PdfTheme.titleMedium(skill.name),
      PdfTheme.titleSmall('Niveau\u00a0: ${skill.complexity}'),
      PdfTheme.titleSmall('Critères de performance:'),
      ...skill.criteria.map(
        (e) => pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfTheme.bodyMedium('\u00b7 '),
              pw.Flexible(child: PdfTheme.bodyMedium(e)),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: 8),
    ],
  );
}

pw.Widget _buildSkillFooter(
    {required SkillEvaluationFormController controller, required Skill skill}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      PdfTheme.titleSmall('Commentaires'),
      PdfTheme.bodyMedium(controller.skillCommentsControllers[skill.id]!.text),
      pw.SizedBox(height: 8),
      PdfTheme.titleSmall('Appréciation générale de la compétence'),
      PdfTheme.bodyMedium(
          controller.appreciations[skill.id]?.name ?? 'Non évaluée'),
    ],
  );
}

pw.Widget _buildSkillTileGlobal({
  required Skill skill,
  required SkillEvaluationFormController controller,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _buildSkillHeader(skill: skill),
      PdfTheme.titleSmall('L\'élève a réussi les tâches suivantes'),
      pw.SizedBox(height: 4),
      PdfCheckBoxes(
          options: controller.taskCompleted[skill.id]!.map(
              (task, taskAppreciation) => MapEntry(task.toString(),
                  taskAppreciation == TaskAppreciationLevel.evaluated))),
      if (controller.skillCommentsControllers[skill.id]?.text != null)
        pw.SizedBox(height: 8),
      _buildSkillFooter(controller: controller, skill: skill),
    ],
  );
}

pw.Widget _buildSkillTileByTask({
  required Skill skill,
  required SkillEvaluationFormController controller,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _buildSkillHeader(skill: skill),
      PdfTheme.titleSmall('L\'élève a réussi les tâches suivantes'),
      pw.SizedBox(height: 4),
      ...controller.taskCompleted[skill.id]!.keys.map((task) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfTheme.bodyMedium(task.toString()),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8.0, left: 24.0),
                child: PdfRadioButtons(
                  options: byTaskAppreciationLevel.asMap().map((_, value) =>
                      MapEntry(value.abbreviation().toString(),
                          controller.taskCompleted[skill.id]![task]! == value)),
                  direction: pw.Axis.horizontal,
                ),
              ),
            ],
          )),
      if (controller.skillCommentsControllers[skill.id]?.text != null)
        pw.SizedBox(height: 8),
      _buildSkillFooter(controller: controller, skill: skill),
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

pw.Widget _buildSkillsCheckboxes({
  required String title,
  required SkillEvaluationFormController controller,
  required Specialization specialization,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      PdfTheme.titleMedium(title),
      PdfTheme.titleSmall(specialization.idWithName),
      ...specialization.skills.map((skill) => PdfCheckBoxes(
            options: {skill.idWithName: controller.isSkillToEvaluate(skill.id)},
          )),
    ],
  );
}

pw.Widget _evaluationType({required SkillEvaluationFormController controller}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      PdfTheme.titleMedium('Type d\'évaluation'),
      PdfRadioButtons(
          options: SkillEvaluationGranularity.values.asMap().map((e, value) =>
              MapEntry(value.toString(),
                  controller.evaluationGranularity == value))),
    ],
  );
}
