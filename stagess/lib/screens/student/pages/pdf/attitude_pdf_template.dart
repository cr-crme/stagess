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
      build: (pw.Context context) => pw.Align(
          alignment: pw.Alignment.topLeft,
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // TODO Rendu ici
                _buildSectionTitle(
                    title: '1. ${Inattendance.title}',
                    controller: controller,
                    elements: Inattendance.values),
                pw.SizedBox(height: 16),
                _buildSectionTitle(
                    title: '2. ${Politeness.title}',
                    controller: controller,
                    elements: Politeness.values),

                // _AttitudeRadioChoices(
                //         title: '1. *${Inattendance.title}',
                //         formController: widget.formController,
                //         elements: Inattendance.values,
                //         editMode: widget.editMode,
                //       ),
                //       _AttitudeRadioChoices(
                //         title: '2. *${Ponctuality.title}',
                //         formController: widget.formController,
                //         elements: Ponctuality.values,
                //         editMode: widget.editMode,
                //       ),
                //       _AttitudeRadioChoices(
                //         title: '3. *${Sociability.title}',
                //         formController: widget.formController,
                //         elements: Sociability.values,
                //         editMode: widget.editMode,
                //       ),
                //       _AttitudeRadioChoices(
                //         title: '4. *${Politeness.title}',
                //         formController: widget.formController,
                //         elements: Politeness.values,
                //         editMode: widget.editMode,
                //       ),
                //       _AttitudeRadioChoices(
                //         title: '5. *${Motivation.title}',
                //         formController: widget.formController,
                //         elements: Motivation.values,
                //         editMode: widget.editMode,
                //       ),
                //       _AttitudeRadioChoices(
                //         title: '6. *${DressCode.title}',
                //         formController: widget.formController,
                //         elements: DressCode.values,
                //         editMode: widget.editMode,
                //       ),
                // _AttitudeRadioChoices(
                //         title: '7. *${QualityOfWork.title}',
                //         formController: widget.formController,
                //         elements: QualityOfWork.values,
                //         editMode: widget.editMode,
                //       ),
                //       _AttitudeRadioChoices(
                //         title: '8. *${Productivity.title}',
                //         formController: widget.formController,
                //         elements: Productivity.values,
                //         editMode: widget.editMode,
                //       ),
                //       _AttitudeRadioChoices(
                //         title: '9. *${Autonomy.title}',
                //         formController: widget.formController,
                //         elements: Autonomy.values,
                //         editMode: widget.editMode,
                //       ),
                //       _AttitudeRadioChoices(
                //         title: '10. *${Cautiousness.title}',
                //         formController: widget.formController,
                //         elements: Cautiousness.values,
                //         editMode: widget.editMode,
                //       ),
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
