import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stagess_common/models/persons/student_visa.dart';
import 'package:stagess_common/services/job_data_file_service.dart'
    as job_service;
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/widgets/pdf_widgets/pdf_bullet_points.dart';

final _logger = Logger('GenerateVisaPdf');

const _bulletPointSpacing = pw.EdgeInsets.only(bottom: 8);
final _bullets = pw.Container(
  margin: const pw.EdgeInsets.only(top: 5, right: 6),
  width: 4,
  height: 4,
  decoration: pw.BoxDecoration(
      color: _VisaPdfContext.bulletColor, shape: pw.BoxShape.circle),
);

class _VisaPdfContext {
  static Future<_VisaPdfContext> create(PdfPageFormat format,
      {required StudentVisa studentVisa}) async {
    final frontPageTheme = await _buildPageTheme(format,
        'packages/stagess_common_flutter/assets/visa_background_front.svg');
    final leftPageTheme = await _buildPageTheme(format,
        'packages/stagess_common_flutter/assets/visa_background_left.svg');
    final rightPageTheme = await _buildPageTheme(format,
        'packages/stagess_common_flutter/assets/visa_background_right.svg');

    final titleFont = await PdfGoogleFonts.alegreyaSCBold();
    final subTitleFont = await PdfGoogleFonts.alegreyaSCRegular();

    return _VisaPdfContext(
      studentVisa: studentVisa,
      frontPageTheme: frontPageTheme,
      leftPageTheme: leftPageTheme.copyWith(margin: pageMargin),
      rightPageTheme: rightPageTheme.copyWith(margin: pageMargin),
      titleFont: titleFont,
      subTitleFont: subTitleFont,
    );
  }

  _VisaPdfContext({
    required this.studentVisa,
    required this.frontPageTheme,
    required this.leftPageTheme,
    required this.rightPageTheme,
    required this.titleFont,
    required this.subTitleFont,
  });

  final StudentVisa studentVisa;
  final pw.PageTheme frontPageTheme;
  final pw.PageTheme leftPageTheme;
  final pw.PageTheme rightPageTheme;

  final pw.Font titleFont;
  final PdfColor titleColor = PdfColors.white;
  static const pw.EdgeInsets pageMargin = pw.EdgeInsets.only(
      left: PdfPageFormat.mm * 15.5,
      right: PdfPageFormat.mm * 16.5,
      top: PdfPageFormat.mm * 20,
      bottom: PdfPageFormat.mm * 20);
  final (double, double) titleBoxSize =
      (PdfPageFormat.mm * 114.5, PdfPageFormat.mm * 33.5);
  final (double, double) mainBoxSize =
      (PdfPageFormat.mm * 184, PdfPageFormat.mm * 205);

  final pw.Font subTitleFont;
  static const PdfColor subTitleColor = PdfColor.fromInt(0xff0085a4);

  static const PdfColor bulletColor = PdfColor.fromInt(0xffb9ddb2);
}

Future<Uint8List> generateVisaPdf(BuildContext context, PdfPageFormat format,
    {required String studentId, required StudentVisa studentVisa}) async {
  _logger.info('Generating visa PDF for student: $studentId');

  final document = pw.Document();
  final pdfContext =
      await _VisaPdfContext.create(format, studentVisa: studentVisa);

  document.addPage(_buildFirstPage(pdfContext));
  document.addPage(_buildSecondPage(pdfContext));
  document.addPage(_buildThirdPage(pdfContext));
  document.addPage(_buildFourthPage(pdfContext));

  return document.save();
}

Future<pw.PageTheme> _buildPageTheme(
  PdfPageFormat format,
  String backgroundAssetPath,
) async {
  final backgroundSvg = await rootBundle.loadString(backgroundAssetPath);
  return pw.PageTheme(
    pageFormat: format,
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: pw.SvgImage(svg: backgroundSvg),
    ),
  );
}

pw.Page _buildFirstPage(_VisaPdfContext pdfContext) {
  return pw.Page(
    pageTheme: pdfContext.frontPageTheme,
    build: (pw.Context context) => pw.Center(
      child: pw.Text(
        'VISA Destination emploi',
      ),
    ),
  );
}

pw.Page _buildSecondPage(_VisaPdfContext pdfContext) {
  final experiences =
      (pdfContext.studentVisa.form.experiencesAndAptitudes.toList()
            ..removeWhere((e) => e.isNotSelected)
            ..sort((a, b) => a.index.compareTo(b.index)))
          .map((e) => e.text);

  final attestations =
      (pdfContext.studentVisa.form.attestationsAndMentions.toList()
            ..removeWhere((a) => a.isNotSelected)
            ..sort((a, b) => a.index.compareTo(b.index)))
          .map((e) => e.text);

  final sstTrainings = (pdfContext.studentVisa.form.sstTrainings.toList()
        ..removeWhere((s) => s.isHidden || s.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) => SstTraining.availableTrainings[e.trainingId]!)
      .toList();

  return pw.Page(
    pageTheme: pdfContext.leftPageTheme,
    build: (pw.Context context) {
      final pageHeight = pdfContext.mainBoxSize.$2;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _TitleBox(
            pdfContext,
            text: 'Expériences et aptitudes complémentaires',
          ),
          _MainBox(
            pdfContext,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _SubtitledBox(pdfContext,
                    title:
                        'Expériences et aptitudes personnelles et scolaires complémentaires au profil d\'employabilité',
                    height: pageHeight * 0.29,
                    child: PdfTextBulletPoints(
                      elements: experiences,
                      spacing: _bulletPointSpacing,
                      bullet: _bullets,
                    )),
                pw.SizedBox(height: 12),
                _SubtitledBox(pdfContext,
                    title: 'Attestations et mentions',
                    height: pageHeight * 0.19,
                    child: PdfTextBulletPoints(
                      elements: attestations,
                      spacing: _bulletPointSpacing,
                      bullet: _bullets,
                    )),
                pw.SizedBox(height: 12),
                _SubtitledBox(pdfContext,
                    title: 'Formations relatives à la SST',
                    height: pageHeight * 0.19,
                    child: PdfTextBulletPoints(
                      elements: sstTrainings,
                      spacing: _bulletPointSpacing,
                      bullet: _bullets,
                    )),
              ],
            ),
          ),
        ],
      );
    },
  );
}

pw.Page _buildThirdPage(_VisaPdfContext pdfContext) {
  final forces = (pdfContext.studentVisa.form.forces.toList()
        ..removeWhere((f) => f.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) => Attitude.availableItems[e.attitudeId]!);

  final challenges = (pdfContext.studentVisa.form.challenges.toList()
        ..removeWhere((d) => d.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) => Attitude.availableItems[e.attitudeId]!);

  final successConditions =
      (pdfContext.studentVisa.form.successConditions.toList()
            ..removeWhere((a) => a.isNotSelected)
            ..sort((a, b) => a.index.compareTo(b.index)))
          .map((e) => e.text);

  return pw.Page(
    pageTheme: pdfContext.rightPageTheme,
    build: (pw.Context context) {
      final pageHeight = pdfContext.mainBoxSize.$2;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: _TitleBox(pdfContext,
                text: 'Évaluation du rendement en milieu de stage'),
          ),
          _MainBox(
            pdfContext,
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _SubtitledBox(pdfContext,
                      title: 'Forces',
                      height: pageHeight * 0.15,
                      child: PdfTextBulletPoints(
                        elements: forces,
                        spacing: _bulletPointSpacing,
                        bullet: _bullets,
                      )),
                  pw.SizedBox(height: 24),
                  _SubtitledBox(pdfContext,
                      title: 'Défis à relever',
                      height: pageHeight * 0.08,
                      child: PdfTextBulletPoints(
                        elements: challenges,
                        spacing: _bulletPointSpacing,
                        bullet: _bullets,
                      )),
                  pw.SizedBox(height: 24),
                  _SubtitledBox(pdfContext,
                      title: 'Conditions de succès',
                      height: pageHeight * 0.08,
                      child: PdfTextBulletPoints(
                        elements: successConditions,
                        spacing: _bulletPointSpacing,
                        bullet: _bullets,
                      )),
                ]),
          )
        ],
      );
    },
  );
}

pw.Page _buildFourthPage(_VisaPdfContext pdfContext) {
  final skills = (pdfContext.studentVisa.form.skills.toList()
        ..removeWhere((e) => e.isNotSelected)
        ..sort((a, b) => a.index.compareTo(b.index)))
      .map((e) =>
          job_service.ActivitySectorsService.skillOrNull(e.skillId)?.name ??
          'Compétence non trouvée');

  final certificates = (pdfContext.studentVisa.form.certificates.toList()
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

  final references = (pdfContext.studentVisa.form.references.toList()
    ..removeWhere((r) => r.isNotSelected)
    ..sort((a, b) => a.index.compareTo(b.index)));

  return pw.Page(
    pageTheme: pdfContext.leftPageTheme,
    build: (pw.Context context) {
      final pageHeight = pdfContext.mainBoxSize.$2;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _TitleBox(pdfContext, text: 'Profil d\'employabilité'),
          _MainBox(
            pdfContext,
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _SubtitledBox(
                    pdfContext,
                    title:
                        'Compétences spécifiques intégrées liées à des métiers semi-spécialisés',
                    height: pageHeight * 0.20,
                    child: PdfTextBulletPoints(
                      elements: skills,
                      spacing: _bulletPointSpacing,
                      bullet: _bullets,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _SubtitledBox(
                    pdfContext,
                    title: 'Certificats',
                    height: pageHeight * 0.20,
                    child: PdfTextBulletPoints(
                      elements: certificates,
                      spacing: _bulletPointSpacing,
                      bullet: _bullets,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _SubtitledBox(
                    pdfContext,
                    title: 'Références',
                    height: pageHeight * 0.20,
                    child: PdfBulletPoints(
                      spacing: _bulletPointSpacing,
                      children: references.map((e) {
                        final reference = e;
                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.RichText(
                              text: pw.TextSpan(children: [
                                if (reference.referee.isEmpty &&
                                    reference.enterprise.isEmpty &&
                                    reference.phoneNumber.toString().isEmpty &&
                                    reference.email.isEmpty)
                                  pw.TextSpan(
                                      text: 'Aucune information renseignée',
                                      style: pw.TextStyle(
                                          fontStyle: pw.FontStyle.italic)),
                                if (reference.referee.isNotEmpty) ...[
                                  pw.TextSpan(
                                    text: reference.referee,
                                    style: pw.TextStyle(
                                        fontStyle: pw.FontStyle.italic),
                                  ),
                                ],
                                if (reference.enterprise.isNotEmpty) ...[
                                  if (reference.referee.isNotEmpty)
                                    pw.TextSpan(text: ', '),
                                  pw.TextSpan(
                                    text: reference.enterprise,
                                    style: pw.TextStyle(
                                        fontStyle: reference.referee.isNotEmpty
                                            ? pw.FontStyle.normal
                                            : pw.FontStyle.italic),
                                  ),
                                ],
                                if (reference.phoneNumber
                                    .toString()
                                    .isNotEmpty) ...[
                                  if (reference.referee.isNotEmpty ||
                                      reference.enterprise.isNotEmpty)
                                    pw.TextSpan(text: ', '),
                                  pw.TextSpan(
                                      text: reference.phoneNumber.toString()),
                                ],
                                if (reference.email.isNotEmpty) ...[
                                  if (reference.referee.isNotEmpty ||
                                      reference.enterprise.isNotEmpty ||
                                      reference.phoneNumber
                                          .toString()
                                          .isNotEmpty)
                                    pw.TextSpan(text: ', '),
                                  pw.TextSpan(text: reference.email),
                                ],
                              ]),
                            ),
                            if (reference.supplementaryInfo.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 4.0),
                                child: pw.Text(reference.supplementaryInfo,
                                    style: pw.TextStyle(
                                        fontStyle: pw.FontStyle.italic)),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ]),
          )
        ],
      );
    },
  );
}

class _TitleBox extends pw.StatelessWidget {
  _TitleBox(this.pdfContext, {required this.text});

  final String text;
  final _VisaPdfContext pdfContext;

  @override
  pw.Widget build(pw.Context context) {
    return pw.SizedBox(
      width: pdfContext.titleBoxSize.$1,
      height: pdfContext.titleBoxSize.$2,
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(24.0),
        child: pw.Center(
          child: pw.Text(
            text,
            style: pw.TextStyle(
                font: pdfContext.titleFont,
                fontSize: 16,
                color: pdfContext.titleColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _MainBox extends pw.StatelessWidget {
  _MainBox(this.pdfContext, {required this.child});

  final _VisaPdfContext pdfContext;
  final pw.Widget child;

  @override
  pw.Widget build(pw.Context context) {
    return pw.SizedBox(
      child: pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        child: pw.Center(child: child),
      ),
    );
  }
}

class _SubtitledBox extends pw.StatelessWidget {
  _SubtitledBox(this.pdfContext,
      {this.title, this.height, required this.child});

  final _VisaPdfContext pdfContext;
  final String? title;
  final double? height;
  final pw.Widget child;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title != null)
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title!,
                style: pw.TextStyle(
                  font: pdfContext.subTitleFont,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _VisaPdfContext.subTitleColor,
                ),
              ),
              pw.Divider(color: _VisaPdfContext.bulletColor),
              pw.SizedBox(height: 4),
            ],
          ),
        pw.SizedBox(width: double.infinity, height: height, child: child)
      ],
    );
  }
}
