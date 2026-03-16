import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess_common/models/persons/student_visa.dart';

final _logger = Logger('GenerateVisaPdf');

Future<Uint8List> generateVisaPdf(BuildContext context, PdfPageFormat format,
    {required String studentId, required StudentVisa studentVisa}) async {
  _logger.info('Generating visa PDF for student: $studentId');

  final document = pw.Document();
  print(studentVisa);

  document.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Center(child: pw.Text('Visa')),
    ),
  );

  return document.save();
}
