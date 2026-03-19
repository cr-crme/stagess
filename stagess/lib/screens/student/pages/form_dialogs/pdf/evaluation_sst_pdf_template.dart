import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/common/pdf_widgets/pdf_check_boxes.dart';
import 'package:stagess/common/pdf_widgets/pdf_evaluation_date.dart';
import 'package:stagess/common/pdf_widgets/pdf_radio_buttons.dart';
import 'package:stagess/common/pdf_widgets/pdf_theme.dart';
import 'package:stagess/common/pdf_widgets/pdf_were_present.dart';
import 'package:stagess/misc/question_file_service.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';

final _logger = Logger('GenerateSstEvaluationPdf');

Future<Uint8List> generateSstEvaluationPdf(
    BuildContext context, PdfPageFormat format,
    {required String internshipId, required String evaluationId}) async {
  _logger.info(
      'Generating SST PDF for evaluation: $evaluationId of internship: $internshipId');
  final internship =
      InternshipsProvider.of(context, listen: false).fromId(internshipId);

  final evaluation =
      internship.sstEvaluations.firstWhereOrNull((e) => e.id == evaluationId);
  if (evaluation == null) {
    _logger.warning(
        'No SST evaluation found for internship ${internship.id} with evaluation id $evaluationId');
    return Uint8List(0);
  }
  final student =
      StudentsProvider.of(context, listen: false).fromId(internship.studentId);

  final document = pw.Document(pageMode: PdfPageMode.outlines);

  // Sort the question by "id"
  final specialization = ActivitySectorsService.specializationOrNull(
      internship.currentContract!.specializationId);

  final questionIds = [...?specialization?.questions]
    ..sort((a, b) => int.parse(a) - int.parse(b));
  final questions =
      questionIds.map((e) => QuestionFileService.fromId(e)).toList();

  document.addPage(
    pw.MultiPage(
      build: (pw.Context cxt) => [
        pw.Center(child: PdfTheme.titleLarge('Repérer les risques SST')),
        pw.SizedBox(height: 12),
        PdfTheme.titleMedium('Informations générales'),
        PdfEvaluationDate(evaluationDate: evaluation.date),
        pw.SizedBox(height: 12),
        PdfWerePresentAtMeeting(
            werePresent: evaluation.presentAtEvaluation,
            studentName: student.fullName),
        pw.SizedBox(height: 24),
        ...questions.asMap().keys.expand((index) {
          final question = questions[index];
          final answer = evaluation.questions['Q${question.id}'];
          final followUpAnswer = evaluation.questions['Q${question.id}+t'];

          return [
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 24),
              child: _buildQuestion(
                context,
                index: index,
                question: question,
                answer: answer,
                followUpAnswer: followUpAnswer,
              ),
            ),
          ];
        }),
      ],
    ),
  );

  return document.save();
}

String _sanitize(String input) {
  final out = input.replaceAll('\u2019', '\'').replaceAll('\u2026', '...');
  if (out.startsWith('*')) {
    return out.substring(1).trim();
  }
  return out;
}

pw.Widget _buildQuestion(
  BuildContext context, {
  required int index,
  required Question question,
  required List<String>? answer,
  required List<String>? followUpAnswer,
}) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    PdfTheme.titleSmall('${index + 1}. ${_sanitize(question.question)}'),
    switch (question.type) {
      QuestionType.radio => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 8.0, left: 12.0),
              child: PdfRadioButtons(
                options: question.choices?.toList().asMap().map(
                          (i, choice) => MapEntry(
                              _sanitize(question.choices!.elementAt(i)),
                              answer?.contains(choice) ?? false),
                        ) ??
                    {},
              ),
            ),
            if (question.followUpQuestion != null &&
                (answer?.contains(question.choices!.first) ?? false))
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 8),
                    pw.Text(_sanitize(question.followUpQuestion!),
                        style: PdfTheme.textStyleItalic),
                    PdfTheme.bodyMedium(
                        followUpAnswer?.join(', ') ?? 'Aucune réponse'),
                  ]),
          ],
        ),
      QuestionType.checkbox => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 8.0, left: 12.0),
              child: PdfCheckBoxes(
                options: question.choices?.toList().asMap().map(
                          (i, choice) => MapEntry(
                              _sanitize(question.choices!.elementAt(i)),
                              answer?.contains(choice) ?? false),
                        ) ??
                    {},
                otherValue: answer
                        ?.where(
                            (a) => !(question.choices?.contains(a) ?? false))
                        .join(', ') ??
                    '',
                includeOthers: true,
              ),
            ),
            if (question.followUpQuestion != null && answer?.isNotEmpty == true)
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 8),
                    pw.Text(_sanitize(question.followUpQuestion!),
                        style: PdfTheme.textStyleItalic),
                    PdfTheme.bodyMedium(
                        followUpAnswer?.join(', ') ?? 'Aucune réponse'),
                  ]),
          ],
        ),
      QuestionType.text =>
        PdfTheme.bodyMedium(followUpAnswer?.join(', ') ?? 'Aucune réponse'),
    },
    pw.SizedBox(height: 12),
  ]);
}
