import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final _logger = Logger('GenerateEnterpriseEvaluationPdf');

Future<Uint8List> generateEnterpriseEvaluationPdf(
    BuildContext context, PdfPageFormat format,
    {required String internshipId, required String evaluationId}) async {
  _logger.info(
      'Generating enterprise evaluation PDF for internship: $internshipId');

  final document = pw.Document();

  document.addPage(
    pw.Page(
      build: (pw.Context context) =>
          pw.Center(child: pw.Text('Enterprise Evaluation')),
    ),
  );

  return document.save();
}
