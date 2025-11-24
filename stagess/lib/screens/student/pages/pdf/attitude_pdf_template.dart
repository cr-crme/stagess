import 'dart:typed_data';

import 'package:flutter/widgets.dart';
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
    pw.Page(
      build: (pw.Context context) => pw.Center(
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
            // TODO Rendu ici
            _buildSectionTitle(
                title: Politeness.title,
                controller: controller,
                elements: Politeness.values),
          ])),
    ),
  );

  return document.save();
}

pw.Widget _buildSectionTitle({
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
            pw.Text(controller.responses[elements[0].runtimeType]!.toString(),
                style: _textStyle)
          ],
        );
}
