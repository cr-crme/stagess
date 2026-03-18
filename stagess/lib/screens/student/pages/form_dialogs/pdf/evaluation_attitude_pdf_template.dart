import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/common/pdf_widgets/pdf_evaluation_date.dart';
import 'package:stagess/common/pdf_widgets/pdf_radio_buttons.dart';
import 'package:stagess/common/pdf_widgets/pdf_theme.dart';
import 'package:stagess/common/pdf_widgets/pdf_were_present.dart';
import 'package:stagess/screens/student/pages/form_dialogs/forms/attitude_evaluation_form_dialog.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';

final _logger = Logger('GenerateAttitudePdf');

Future<Uint8List> generateAttitudeEvaluationPdf(
    BuildContext context, PdfPageFormat format,
    {required String internshipId, required String evaluationId}) async {
  _logger.info(
      'Generating attitude evaluation PDF for internship: $internshipId, evaluationId: $evaluationId');

  final controller = AttitudeEvaluationFormController.fromInternshipId(context,
      internshipId: internshipId, evaluationId: evaluationId);
  final internship = controller.internship(context, listen: false);
  final student =
      StudentsProvider.of(context, listen: false).fromId(internship.studentId);

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
        PdfTheme.titleMedium('Situation de travail'),
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
        pw.NewPage(),
        PdfTheme.titleMedium('Relation avec les autres'),
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
        pw.NewPage(),
        PdfTheme.titleMedium('Autonomie et adaptabilité'),
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
      ],
    ),
  );

  return document.save();
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
      PdfTheme.titleSmall(title),
      pw.Padding(
          padding: pw.EdgeInsets.only(top: 4),
          child: PdfRadioButtons(
            options: {
              for (var element in elements) element.name: element == groupValue,
            },
          ))
    ],
  );
}
