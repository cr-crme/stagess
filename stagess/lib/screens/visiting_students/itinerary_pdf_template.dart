import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

final _logger = Logger('ItineraryPdfTemplate');

final _textStyle = pw.TextStyle(font: pw.Font.times());
final _textStyleBold = pw.TextStyle(font: pw.Font.timesBold());
final _textStyleBoldItalic = pw.TextStyle(font: pw.Font.timesBoldItalic());

Future<Uint8List> generateItineraryPdf(
    BuildContext context, PdfPageFormat format,
    {required String itineraryName}) async {
  _logger.info('Generating itinerary PDF for itinerary: $itineraryName');

  final teacher = TeachersProvider.of(context).currentTeacher;
  if (teacher == null) {
    _logger.warning('No teacher found');
    return Uint8List(0);
  }
  final itinerary =
      teacher.itineraries.firstWhereOrNull((i) => i.name == itineraryName);
  if (itinerary == null) {
    _logger.warning('No itinerary found with name $itineraryName');
    return Uint8List(0);
  }

  final document = pw.Document(pageMode: PdfPageMode.outlines);

  document.addPage(
    pw.Page(
      build: (pw.Context context) =>
          pw.Center(child: pw.Text('Itinéraire de visite : ${itinerary.name}')),
    ),
  );

  document.addPage(
    pw.MultiPage(
      build: (pw.Context ctx) => [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [],
        )
      ],
    ),
  );

  return document.save();
}
