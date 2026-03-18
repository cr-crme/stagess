import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/common/pdf_widgets/pdf_check_boxes.dart';
import 'package:stagess/common/pdf_widgets/pdf_evaluation_date.dart';
import 'package:stagess/common/pdf_widgets/pdf_radio_buttons.dart';
import 'package:stagess/common/pdf_widgets/pdf_slider.dart';
import 'package:stagess/common/pdf_widgets/pdf_theme.dart';
import 'package:stagess/screens/student/pages/form_dialogs/forms/enterprise_evaluation_form_dialog.dart';
import 'package:stagess/screens/student/pages/form_dialogs/forms/enterprise_evaluation_form_enums.dart';

final _logger = Logger('GenerateEnterpriseEvaluationPdf');

Future<Uint8List> generateEnterpriseEvaluationPdf(
    BuildContext context, PdfPageFormat format,
    {required String internshipId, required String evaluationId}) async {
  _logger.info(
      'Generating enterprise evaluation PDF for internship: $internshipId');

  final controller = EnterpriseEvaluationFormController(
    context,
    internshipId: internshipId,
    evaluationId: evaluationId,
    canModify: false,
  );

  final document = pw.Document();

  document.addPage(
    pw.MultiPage(
      build: (pw.Context context) => [
        pw.Center(
            child: PdfTheme.titleLarge(
                'Évaluation de l\'encadrement de l\'entreprise')),
        pw.SizedBox(height: 12),
        PdfTheme.titleMedium('Informations générales'),
        PdfEvaluationDate(evaluationDate: controller.evaluationDate),
        pw.SizedBox(height: 12),
        _buildTask(controller),
        pw.SizedBox(height: 12),
        _buildSkillsRequired(controller),
        pw.NewPage(),
        _buildStudentExpectations(controller),
        pw.SizedBox(height: 12),
        _buildStudentSupervision(controller),
      ],
    ),
  );

  return document.save();
}

pw.Widget _buildTask(EnterpriseEvaluationFormController controller) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      PdfTheme.titleMedium('Tâches'),
      PdfTheme.titleSmall('Tâches données à l\'élève'),
      pw.SizedBox(height: 4),
      PdfRadioButtons(
          options: TaskVariety.values
              .where((e) => e != TaskVariety.none)
              .toList()
              .asMap()
              .map((index, e) =>
                  MapEntry(e.toString(), controller.taskVariety == e))),
      pw.SizedBox(height: 12),
      PdfTheme.titleSmall('Respect du plan de formation'),
      PdfTheme.bodyMedium(
          'Possibilité d\'exercer toutes les tâches de toutes les compétences spécifiques '
          'obligatoires d\'un métier semi-spécialisé'),
      pw.SizedBox(height: 4),
      PdfRadioButtons(
          options: TrainingPlan.values
              .where((e) => e != TrainingPlan.none)
              .toList()
              .asMap()
              .map((index, e) =>
                  MapEntry(e.toString(), controller.trainingPlan == e)))
    ],
  );
}

pw.Widget _buildSkillsRequired(EnterpriseEvaluationFormController controller) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      PdfTheme.titleMedium('Habiletés'),
      PdfTheme.titleSmall('Habiletés requises pour le stage'),
      pw.SizedBox(height: 4),
      PdfCheckBoxes(
        options: RequiredSkills.values.toList().asMap().map((index, e) =>
            MapEntry(
                e.toString(), controller.selectedRequiredSkills.contains(e))),
        includeOthers: true,
        otherValue: controller.otherRequiredSkills,
      ),
    ],
  );
}

pw.Widget _buildStudentExpectations(
    EnterpriseEvaluationFormController controller) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      PdfTheme.titleMedium('Attentes envers le ou la stagiaire'),
      PdfTheme.titleSmall('Niveau d\'autonomie de l\'élève souhaité'),
      pw.SizedBox(height: 4),
      PdfSlider(
          value: controller.autonomyExpected,
          lowestLabel: AutonomyExpected.low.label,
          highestLabel: AutonomyExpected.high.label),
      pw.SizedBox(height: 12),
      PdfTheme.titleSmall('Rendement de l\'élève'),
      PdfSlider(
          value: controller.efficiencyExpected,
          lowestLabel: EfficiencyExpected.low.label,
          highestLabel: EfficiencyExpected.high.label),
      pw.SizedBox(height: 12),
      PdfTheme.titleSmall(
          'Ouverture de l\'entreprise à accueillir des élèves avec des besoins particuliers'),
      PdfSlider(
          value: controller.specialNeedsAccommodation,
          lowestLabel: SpecialNeedsAccommodation.low.label,
          highestLabel: SpecialNeedsAccommodation.high.label),
    ],
  );
}

pw.Widget _buildStudentSupervision(
    EnterpriseEvaluationFormController controller) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      PdfTheme.titleMedium('Encadrement'),
      PdfTheme.titleSmall('Type d\'encadrement'),
      pw.SizedBox(height: 4),
      PdfSlider(
          value: controller.supervisionStyle,
          lowestLabel: SupervisionStyle.low.label,
          highestLabel: SupervisionStyle.high.label),
      pw.SizedBox(height: 12),
      PdfTheme.titleSmall('Communication avec l\'entreprise'),
      PdfSlider(
          value: controller.easeOfCommunication,
          lowestLabel: EaseOfCommunication.low.label,
          highestLabel: EaseOfCommunication.high.label),
      pw.SizedBox(height: 12),
      PdfTheme.titleSmall(
          'Tolérance du milieu à l\'égard des retards et absences de l\'élève'),
      PdfSlider(
          value: controller.absenceAcceptance,
          lowestLabel: AbsenceAcceptance.low.label,
          highestLabel: AbsenceAcceptance.high.label),
      pw.SizedBox(height: 12),
      PdfTheme.titleSmall('Encadrement par rapport à la SST'),
      PdfSlider(
          value: controller.sstSupervision,
          lowestLabel: SstSupervision.low.label,
          highestLabel: SstSupervision.high.label),
    ],
  );
}
