import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/screens/internship_forms/student_steps/attitude_evaluation_form_controller.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart';

final _logger = Logger('GenerateAttitudePdf');

final _textStyle = pw.TextStyle(font: pw.Font.times());
final _textStyleBold = pw.TextStyle(font: pw.Font.timesBold());

Future<Uint8List> generateAttitudePdf(
    BuildContext context, PdfPageFormat format,
    {required AttitudeEvaluationFormController controller}) async {
  _logger.info(
      'Generating attitude PDF for internship: ${controller.internshipId}');

  final document = pw.Document(pageMode: PdfPageMode.outlines);

  document.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Center(child: pw.Text('ATTITUDE')),
    ),
  );

  document.addPage(
    pw.MultiPage(
      build: (pw.Context context) => [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _buildPersonsPresent(controller: controller),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '1. ${Inattendance.title}',
              controller: controller,
              elements: Inattendance.values),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '2. ${Ponctuality.title}',
              controller: controller,
              elements: Ponctuality.values),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '3. ${Sociability.title}',
              controller: controller,
              elements: Sociability.values),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '4. ${Politeness.title}',
              controller: controller,
              elements: Politeness.values),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '5. ${Motivation.title}',
              controller: controller,
              elements: Motivation.values),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '6. ${DressCode.title}',
              controller: controller,
              elements: DressCode.values),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '7. ${QualityOfWork.title}',
              controller: controller,
              elements: QualityOfWork.values),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '8. ${Productivity.title}',
              controller: controller,
              elements: Productivity.values),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '9. ${Autonomy.title}',
              controller: controller,
              elements: Autonomy.values),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '10. ${Cautiousness.title}',
              controller: controller,
              elements: Cautiousness.values),
          pw.SizedBox(height: 24),
          _buildAttitudeTile(
              title: '11. ${GeneralAppreciation.title}',
              controller: controller,
              elements: GeneralAppreciation.values),
          pw.SizedBox(height: 24),
          _buildGeneralComments(controller: controller),
        ])
      ],
    ),
  );

  return document.save();
}

pw.Widget _buildPersonsPresent({
  required AttitudeEvaluationFormController controller,
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

pw.Widget _buildAttitudeTile({
  required String title,
  required List<AttitudeCategoryEnum> elements,
  required AttitudeEvaluationFormController controller,
}) {
  return controller.responses[elements[0].runtimeType] == null
      ? pw.Container()
      : pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('$title :', style: _textStyleBold),
            ...elements.map((element) => pw.Padding(
                padding: pw.EdgeInsets.only(top: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 12,
                      height: 12,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: PdfColors.black),
                      ),
                      child:
                          controller.responses[element.runtimeType] == element
                              ? pw.Center(
                                  child: pw.Container(
                                    width: 6,
                                    height: 6,
                                    decoration: pw.BoxDecoration(
                                      shape: pw.BoxShape.circle,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                )
                              : pw.Container(),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(element.name, style: _textStyle),
                  ],
                ))),
          ],
        );
}

pw.Widget _buildGeneralComments(
    {required AttitudeEvaluationFormController controller}) {
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
