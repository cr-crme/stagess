import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess_common/models/persons/student_visa.dart';
import 'package:stagess_common/services/job_data_file_service.dart'
    as job_service;
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/widgets/pdf_widgets/pdf_bullet_points.dart';

final _logger = Logger('GenerateVisaPdf');

const _bulletPointSpacing = pw.EdgeInsets.only(bottom: 8);

Future<Uint8List> generateVisaPdf(BuildContext context, PdfPageFormat format,
    {required String studentId, required StudentVisa studentVisa}) async {
  _logger.info('Generating visa PDF for student: $studentId');

  final document = pw.Document();

  document.addPage(_buildFirstPage(studentVisa));
  document.addPage(_buildSecondPage(studentVisa));
  document.addPage(_buildThirdPage(studentVisa));
  document.addPage(_buildFourthPage(studentVisa));

  return document.save();
}

pw.Page _buildFirstPage(StudentVisa studentVisa) {
  return pw.Page(
    build: (pw.Context context) => pw.Center(
      child: pw.Text(
        'VISA Destination emploi',
      ),
    ),
  );
}

pw.Page _buildSecondPage(StudentVisa studentVisa) {
  final experiences = (studentVisa.form.experiencesAndAptitudes.toList()
        ..removeWhere((e) => e.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) => e.text);

  final attestations = (studentVisa.form.attestationsAndMentions.toList()
        ..removeWhere((a) => a.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) => e.text);

  final sstTrainings = (studentVisa.form.sstTrainings.toList()
        ..removeWhere((s) => s.isHidden || s.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) => SstTraining.availableTrainings[e.trainingId]!)
      .toList();

  return pw.Page(
    build: (pw.Context context) {
      final pageHeight = context.page.pageFormat.height;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _Title('Expériences et aptitudes complémentaires'),
          pw.SizedBox(height: 10),
          _BorderBox(
              title:
                  'Expériences et aptitudes personnelles et scolaires complémentaires au profil d\'employabilité',
              height: pageHeight * 0.30,
              child: PdfBulletPoints(
                elements: experiences,
                spacing: _bulletPointSpacing,
              )),
          pw.SizedBox(height: 12),
          _BorderBox(
              title: 'Attestations et mentions',
              height: pageHeight * 0.20,
              child: PdfBulletPoints(
                elements: attestations,
                spacing: _bulletPointSpacing,
              )),
          pw.SizedBox(height: 12),
          _BorderBox(
              title: 'Formations relatives à la SST',
              height: pageHeight * 0.20,
              child: PdfBulletPoints(
                elements: sstTrainings,
                spacing: _bulletPointSpacing,
              )),
        ],
      );
    },
  );
}

pw.Page _buildThirdPage(StudentVisa studentVisa) {
  final forces = (studentVisa.form.forces.toList()
        ..removeWhere((f) => f.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) => Attitude.availableItems[e.attitudeId]!);

  final challenges = (studentVisa.form.challenges.toList()
        ..removeWhere((d) => d.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) => Attitude.availableItems[e.attitudeId]!);

  final successConditions = (studentVisa.form.successConditions.toList()
        ..removeWhere((a) => a.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) => e.text);

  return pw.Page(
    build: (pw.Context context) {
      final pageHeight = context.page.pageFormat.height;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _Title('Évaluation du rendement en milieu de stage'),
          _Subtitle(
              'Évaluation effectuée en partenariat entre l\'enseignant, le superviseur en milieu de stage et l\'élève'),
          pw.SizedBox(height: 36),
          _BorderBox(
              title: 'Forces',
              height: pageHeight * 0.15,
              child: PdfBulletPoints(
                elements: forces,
                spacing: _bulletPointSpacing,
              )),
          pw.SizedBox(height: 24),
          _BorderBox(
              title: 'Défis à relever',
              height: pageHeight * 0.08,
              child: PdfBulletPoints(
                elements: challenges,
                spacing: _bulletPointSpacing,
              )),
          pw.SizedBox(height: 24),
          _BorderBox(
              title: 'Conditions de succès',
              height: pageHeight * 0.08,
              child: PdfBulletPoints(
                elements: successConditions,
                spacing: _bulletPointSpacing,
              )),
        ],
      );
    },
  );
}

pw.Page _buildFourthPage(StudentVisa studentVisa) {
  final skills = (studentVisa.form.skills.toList()
        ..removeWhere((e) => e.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) =>
          job_service.ActivitySectorsService.skillOrNull(e.skillId)?.name ??
          'Compétence non trouvée');

  final certificates = (studentVisa.form.certificates.toList()
        ..removeWhere((c) => c.isNotSelected)
        ..sort((a, b) => (a.year ?? -1).compareTo(b.year ?? -1)))
      .reversed
      .map((e) {
    final certificate = switch (e.certificateType) {
      CertificateType.none => 'Aucun certificat',
      CertificateType.fpt =>
        'Certificat de formation préparatoire au travail (CFPT)',
      CertificateType.fms =>
        'Certificat de formation à un métier semi-spécialisé (CFMS) pour le métier\u00a0:\n'
            '${job_service.ActivitySectorsService.allSpecializations.firstWhereOrNull((job) => job.id == e.specializationId)?.name ?? 'Métier non trouvé'}',
    };
    return '${e.year} - $certificate';
  });

  final references = (studentVisa.form.reference.toList()
        ..removeWhere((r) => r.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) => e.text);

  return pw.Page(
    build: (pw.Context context) {
      final pageHeight = context.page.pageFormat.height;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _Title('Profil d\'employabilité'),
          pw.SizedBox(height: 10),
          _BorderBox(
            title:
                'Compétences spécifiques intégrées liées à des métiers semi-spécialisés',
            height: pageHeight * 0.20,
            child: PdfBulletPoints(
              elements: skills,
              spacing: _bulletPointSpacing,
            ),
          ),
          pw.SizedBox(height: 12),
          _BorderBox(
            title: 'Certificats',
            height: pageHeight * 0.20,
            child: PdfBulletPoints(
              elements: certificates,
              spacing: _bulletPointSpacing,
            ),
          ),
        ],
      );
    },
  );
}

class _Title extends pw.StatelessWidget {
  _Title(this.text);

  final String text;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }
}

class _Subtitle extends pw.StatelessWidget {
  _Subtitle(this.text);

  final String text;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }
}

class _BorderBox extends pw.StatelessWidget {
  _BorderBox({this.title, this.height, required this.child});

  final String? title;
  final double? height;
  final pw.Widget child;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title != null)
          pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: _Subtitle(title!)),
        pw.Container(
          height: height,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: child,
        )
      ],
    );
  }
}
