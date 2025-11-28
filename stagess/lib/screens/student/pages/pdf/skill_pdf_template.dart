import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/screens/internship_forms/student_steps/skill_evaluation_form_controller.dart';
import 'package:stagess_common/models/internships/task_appreciation.dart';
import 'package:stagess_common/services/job_data_file_service.dart';

final _logger = Logger('GenerateAttitudePdf');

final _textStyle = pw.TextStyle(font: pw.Font.times());
final _textStyleBold = pw.TextStyle(font: pw.Font.timesBold());
final _textStyleBoldItalic = pw.TextStyle(font: pw.Font.timesBoldItalic());

Future<Uint8List> generateSkillEvaluationPdf(
    BuildContext context, PdfPageFormat format,
    {required SkillEvaluationFormController controller}) async {
  _logger.info(
      'Generating skill evaluation PDF for internship: ${controller.internshipId}');

  final document = pw.Document(pageMode: PdfPageMode.outlines);

  document.addPage(
    pw.Page(
      build: (pw.Context context) =>
          pw.Center(child: pw.Text('Évaluation des compétences')),
    ),
  );

  document.addPage(
    pw.MultiPage(
      build: (pw.Context context) => [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _buildPersonsPresent(controller: controller),
          ...controller.skillResults().map((e) => pw.Padding(
              padding: pw.EdgeInsets.only(top: 24),
              child: _buildSkillTile(skill: e, controller: controller))),
          pw.SizedBox(height: 24),
          _buildGeneralComments(controller: controller),
        ])
      ],
    ),
  );

  return document.save();
}

pw.Widget _buildPersonsPresent({
  required SkillEvaluationFormController controller,
}) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Text(
        'Personnes présentes à l\'évaluation du ${DateFormat(
          'dd MMMM yyyy',
          'fr_CA',
        ).format(controller.evaluationDate)} :',
        style: _textStyleBold),
    ...controller.wereAtMeeting.map(
      (e) => pw.Padding(
          padding: pw.EdgeInsets.only(top: 8),
          child: pw.Text('- $e', style: _textStyle)),
    ),
  ]);
}

pw.Widget _buildSkillTile({
  required Skill skill,
  required SkillEvaluationFormController controller,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: 'Pour la compétence « ', style: _textStyleBold),
          pw.TextSpan(text: skill.name, style: _textStyleBoldItalic),
          pw.TextSpan(text: ' »', style: _textStyleBold)
        ]),
      ),
      pw.SizedBox(height: 8),
      pw.Text('Tâches réussies :', style: _textStyle),
      pw.SizedBox(height: 4),
      ...(controller.taskCompleted[skill.id]?.keys.map((task) =>
              controller.taskCompleted[skill.id]?[task] ==
                      TaskAppreciationLevel.evaluated
                  ? pw.Text('- $task', style: _textStyle)
                  : pw.Container()) ??
          []),
      if (controller.skillCommentsControllers[skill.id]?.text != null)
        pw.SizedBox(height: 8),
      pw.Text(
          'Commentaires : ${controller.skillCommentsControllers[skill.id]!.text}',
          style: _textStyle),
      pw.SizedBox(height: 8),
      pw.Text(
          'Appréciation générale de la compétence : ${controller.appreciations[skill.id]?.name ?? 'Non évaluée'}',
          style: _textStyle),
    ],
  );
}

pw.Widget _buildGeneralComments(
    {required SkillEvaluationFormController controller}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Commentaires généraux :', style: _textStyleBold),
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black),
        ),
        child: pw.Padding(
            padding: pw.EdgeInsets.all(8),
            child:
                pw.Text(controller.commentsController.text, style: _textStyle)),
      ),
    ],
  );
}
