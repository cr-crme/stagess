import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/misc/question_file_service.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/sst_evaluation.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

final _logger = Logger('GenerateSstEvaluationPdf');

final _textStyle = pw.TextStyle(font: pw.Font.times());
final _textStyleBold = pw.TextStyle(font: pw.Font.timesBold());
final _textStyleBoldItalic = pw.TextStyle(font: pw.Font.timesBoldItalic());

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

  final document = pw.Document(pageMode: PdfPageMode.outlines);

  document.addPage(
    pw.Page(
      build: (pw.Context context) =>
          pw.Center(child: pw.Text('Repérer les risques SST')),
    ),
  );

  document.addPage(
    pw.MultiPage(
      build: (pw.Context ctx) => [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _buildPersonsPresent(internship: internship, evaluation: evaluation),
          pw.Text('Questions', style: _textStyleBold),
          _buildQuestions(context,
              internship: internship, evaluation: evaluation),
          pw.SizedBox(height: 24),
        ])
      ],
    ),
  );

  return document.save();
}

pw.Widget _buildPersonsPresent({
  required Internship internship,
  required SstEvaluation evaluation,
}) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Text(
        'Personnes présentes à l\'évaluation du ${DateFormat(
          'dd MMMM yyyy',
          'fr_CA',
        ).format(evaluation.date)} :',
        style: _textStyleBold),
    ...evaluation.presentAtEvaluation.map(
      (e) => pw.Padding(
          padding: pw.EdgeInsets.only(top: 8),
          child: pw.Text('- $e', style: _textStyle)),
    ),
  ]);
}

pw.Widget _buildQuestions(BuildContext context,
    {required Internship internship, required SstEvaluation evaluation}) {
  final enterprise = EnterprisesProvider.of(context, listen: false)
      .fromId(internship.enterpriseId);
  final job = enterprise.jobs.fromId(internship.jobId);
  // Sort the question by "id"
  final questionIds = [...job.specialization.questions]
    ..sort((a, b) => int.parse(a) - int.parse(b));
  final questions =
      questionIds.map((e) => QuestionFileService.fromId(e)).toList();

  return pw.ListView.builder(
      itemCount: questions.length,
      itemBuilder: (ctx, index) {
        final question = questions[index];

        // Fill the initial answer
        final baseAnswer = evaluation.questions['Q${question.id}'];
        final followUpAnswer = evaluation.questions['Q${question.id}+t'];

        switch (question.type) {
          case QuestionType.radio:
          case QuestionType.checkbox:
          case QuestionType.text:
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 36.0),
              child: pw.Text('${index + 1}. ${question.question}'),
            );
        }
      });
}
