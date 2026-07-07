import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/screens/visiting_students/widgets/routing_map.dart';
import 'package:stagess_common/models/itineraries/waypoint.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/pdf_widgets/pdf_theme.dart';

final _logger = Logger('ItineraryPdfTemplate');

Future<Uint8List> generateItineraryPdf(
    BuildContext context, PdfPageFormat format,
    {required RoutingController controller}) async {
  _logger.info(
      'Generating itinerary PDF for itinerary: ${controller.itinerary.name}');

  final teacher = TeachersProvider.of(context).currentTeacher;
  if (teacher == null) {
    _logger.warning('No teacher found');
    return Uint8List(0);
  }

  final document = pw.Document(pageMode: PdfPageMode.outlines);

  document.addPage(
    pw.MultiPage(
      build: (pw.Context ctx) => [
        _buildHeader(teacher: teacher, controller: controller),
        _buildItineraryDetails(controller: controller),
      ],
    ),
  );

  return document.save();
}

pw.Widget _buildHeader(
    {required Teacher teacher, required RoutingController controller}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        decoration: pw.BoxDecoration(
          border:
              pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey)),
        ),
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4.0),
          child: pw.Row(children: [
            PdfTheme.titleSmall('Nom de l\'enseignant·e\u00a0: '),
            PdfTheme.bodyMedium(teacher.fullName),
          ]),
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Container(
        decoration: pw.BoxDecoration(
          border:
              pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey)),
        ),
        child: pw.Row(children: [
          pw.Expanded(
              child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 16, bottom: 4.0),
                  child: PdfTheme.titleSmall('Itinéraire du\u00a0: '))),
          pw.Expanded(
              child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 16, bottom: 4.0),
                  child: PdfTheme.titleSmall(
                      'Kilométrage total\u00a0: ${(controller.totalDistance / 1000).toStringAsFixed(1)}km'))),
        ]),
      ),
    ],
  );
}

pw.Widget _buildItineraryDetails({required RoutingController controller}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 24),
      PdfTheme.titleMedium('Itinéraire détaillé'),
      pw.SizedBox(height: 12),
      pw.Container(
        decoration: pw.BoxDecoration(
          border:
              pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey)),
        ),
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4.0),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: PdfTheme.titleSmall('Point de départ'),
              ),
              pw.Expanded(
                child: PdfTheme.titleSmall('Point d\'arrivée'),
              ),
              pw.Expanded(
                child: PdfTheme.titleSmall('Distance'),
              ),
            ],
          ),
        ),
      ),
      ...controller.distances.asMap().keys.map((index) {
        if (index >= controller.itinerary.length - 1) return pw.Container();
        final distance = controller.distances[index];
        final startingPoint = controller.itinerary[index];
        final endingPoint = controller.itinerary[index + 1];

        return pw.Container(
          decoration: pw.BoxDecoration(
              border: pw.Border(
                  bottom:
                      pw.BorderSide(width: 0.25, color: PdfColors.grey300))),
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _placeTile(startingPoint),
              _placeTile(endingPoint),
              pw.Expanded(
                child: PdfTheme.bodyMedium(
                    '${(distance / 1000).toStringAsFixed(1)} km'),
              ),
            ],
          ),
        );
      }),
    ],
  );
}

pw.Widget _placeTile(Waypoint place) {
  final studentName = place.title;
  final enterpriseName = place.subtitle ?? '';

  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.titleSmall(studentName,
            padding: const pw.EdgeInsets.only(bottom: 2.0)),
        PdfTheme.bodyMedium(
          enterpriseName,
          style: PdfTheme.textStyleItalic,
          padding: const pw.EdgeInsets.only(bottom: 2.0),
        ),
        PdfTheme.bodyMedium(place.address.toParagraph()),
      ],
    ),
  );
}
