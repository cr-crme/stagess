import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final _logger = Logger('GenerateVisaPdf');

Future<Uint8List> generateVisaPdf(BuildContext context, PdfPageFormat format,
    {required String internshipId}) async {
  _logger.info('Generating visa PDF for internship: $internshipId');

  final document = pw.Document();

  document.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Center(child: pw.Text('VISA')),
    ),
  );

  return document.save();
}
