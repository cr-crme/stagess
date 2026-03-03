import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/screens/student/pages/internship_form_dialogs/forms/attitude_evaluation_form_dialog.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart';

final _logger = Logger('GenerateAttitudePdf');

final _textStyle = pw.TextStyle(font: pw.Font.times());
final _textStyleBold = pw.TextStyle(font: pw.Font.timesBold());

Future<Uint8List> generateAttitudeEvaluationPdf(
    BuildContext context, PdfPageFormat format,
    {required String internshipId, required String evaluationId}) async {
  _logger.info(
      'Generating attitude evaluation PDF for internship: $internshipId, evaluationId: $evaluationId');

  final controller = AttitudeEvaluationFormController.fromInternshipId(context,
      internshipId: internshipId, evaluationId: evaluationId);

  final workingSituations = [
    controller.ponctuality,
    controller.inattendance,
    controller.qualityOfWork,
    controller.productivity,
  ];
  final relationshipWithOthers = [
    controller.teamCommunication,
    controller.respectOfAuthority,
    controller.communicationAboutSst,
  ];
  final autonomyAndAdaptability = [
    controller.selfControl,
    controller.takeInitiative,
    controller.adaptability,
  ];

  final document = pw.Document(pageMode: PdfPageMode.outlines);

  document.addPage(
    pw.Page(
      build: (pw.Context context) =>
          pw.Center(child: pw.Text('Évaluation de l\'attitude au travail')),
    ),
  );

  document.addPage(
    pw.MultiPage(
      build: (pw.Context context) => [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _buildPersonsPresent(controller: controller),
          pw.SizedBox(height: 24),
          _subTitle('Situation de travail'),
          ...workingSituations.asMap().keys.map(
            (index) {
              final element = workingSituations[index];
              return pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 24.0),
                  child: _buildAttitudeTile(
                    title: '${index + 1}. ${element.title}',
                    definition: element.definition,
                    groupValue: element,
                    elements: element.validElements,
                  ));
            },
          ),
          _subTitle('Relation avec les autres'),
          ...relationshipWithOthers.asMap().keys.map(
            (index) {
              final element = relationshipWithOthers[index];
              return pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 24.0),
                  child: _buildAttitudeTile(
                    title:
                        '${index + workingSituations.length + 1}. ${element.title}',
                    definition: element.definition,
                    groupValue: element,
                    elements: element.validElements,
                  ));
            },
          ),
          _subTitle('Autonomie et adaptabilité'),
          ...autonomyAndAdaptability.asMap().keys.map(
            (index) {
              final element = autonomyAndAdaptability[index];
              return pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 24.0),
                  child: _buildAttitudeTile(
                    title:
                        '${index + workingSituations.length + relationshipWithOthers.length + 1}. ${element.title}',
                    definition: element.definition,
                    groupValue: element,
                    elements: element.validElements,
                  ));
            },
          ),
        ])
      ],
    ),
  );

  return document.save();
}

pw.Widget _subTitle(String text) {
  return pw.Padding(
    padding: pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(text, style: _textStyleBold.copyWith(fontSize: 14)),
  );
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
  required String definition,
  required AttitudeCategoryEnum groupValue,
  required List<AttitudeCategoryEnum> elements,
}) {
  return pw.Column(
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
                child: groupValue == element
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
