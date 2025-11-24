import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/student.dart' as student_model;
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common/services/image_helpers.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

final _logger = Logger('GenerateInternshipContractPdf');

final _textStyle = pw.TextStyle(font: pw.Font.times());
final _textStyleBold = pw.TextStyle(font: pw.Font.timesBold());

String _title(student_model.Program program) {
  switch (program) {
    case student_model.Program.fpt:
      return 'Formation préparatoire au travail';
    case student_model.Program.fms:
      return 'Formation menant à l\'exercice d\'un métier semi-spécialisé';
    case student_model.Program.undefined:
      throw ArgumentError('Program must be defined');
  }
}

Future<Uint8List> generateInternshipContractPdf(
    BuildContext mainContext, PdfPageFormat format,
    {required String internshipId}) async {
  _logger
      .info('Generating internship contract PDF for internship: $internshipId');

  final document = pw.Document(pageMode: PdfPageMode.outlines);
  final headerHeight = 300;

  document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      header: (context) => pw.Container(
          child: _logo(mainContext,
              internshipId: internshipId,
              sizeFactor: context.pageNumber == 1 ? 1.0 : 0.7),
          padding: const pw.EdgeInsets.only(bottom: 12.0)),
      footer: (pw.Context context) {
        return pw.Stack(children: [
          if (context.pageNumber > 1)
            pw.Text(
                'N.B. Ce document est à conserver dans le dossier «	stage » de '
                'l\'élève pendant 3 ans.',
                style: _textStyleBold.copyWith(fontSize: 10)),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            padding: const pw.EdgeInsets.only(top: 12.0, right: 12.0),
            child: context.pageNumber == 1
                ? null
                : pw.Text(
                    context.pageNumber.toString(),
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
          )
        ]);
      },
      build: (context) => [
            pw.SizedBox(
                height: PdfPageFormat.letter.height - headerHeight,
                child: _coverPage(mainContext, internshipId: internshipId)),
            pw.NewPage(),
            _studentObligations(mainContext, internshipId: internshipId),
            pw.NewPage(),
            _contract(mainContext, internshipId: internshipId),
            pw.NewPage(),
            _studentInformations(mainContext, internshipId: internshipId),
          ]));

  return document.save();
}

pw.Widget _logo(BuildContext context,
    {required String internshipId, double sizeFactor = 1.0}) {
  final internship = _internship(context, internshipId: internshipId);
  final schoolBoard =
      _schoolBoard(context, schoolBoardId: internship.schoolBoardId);

  return schoolBoard.logo.isEmpty
      ? pw.Container()
      : pw.Image(
          pw.MemoryImage(schoolBoard.logo),
          fit: pw.BoxFit.scaleDown,
          height: ImageHelpers.logoHeight * sizeFactor,
        );
}

pw.Widget _coverPage(BuildContext context, {required String internshipId}) {
  final internship = _internship(context, internshipId: internshipId);
  final schoolBoard =
      _schoolBoard(context, schoolBoardId: internship.schoolBoardId);
  final program = _student(context, studentId: internship.studentId).program;
  final dash = '-';

  return pw.Center(
      child: pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(_title(program).toUpperCase(),
          style: _textStyle.copyWith(fontSize: 18)),
      pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
              color: PdfColors.grey300),
          child: pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: pw.Column(
              children: [
                pw.Text('CONTRAT DE STAGE',
                    style: _textStyleBold.copyWith(fontSize: 20)),
                pw.SizedBox(height: 20),
                pw.Text(
                  'ENTENTE ENTRE LES PARTIES',
                  style: _textStyle.copyWith(fontSize: 16),
                ),
                pw.Text(
                    '${schoolBoard.name.toUpperCase()} $dash ELEVE $dash ENTREPRISE $dash SUPERVISEUR DE STAGE $dash ECOLE',
                    style: _textStyle.copyWith(fontSize: 16),
                    textAlign: pw.TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ],
  ));
}

pw.Widget _studentObligations(BuildContext context,
    {required String internshipId}) {
  final internship = _internship(context, internshipId: internshipId);
  final schoolBoard =
      _schoolBoard(context, schoolBoardId: internship.schoolBoardId);
  final student = _student(context, studentId: internship.studentId);
  final school = _school(context,
      schoolBoardId: student.schoolBoardId, schoolId: student.schoolId);
  final mid = '\u00b7';

  return pw.Column(
    mainAxisSize: pw.MainAxisSize.max,
    children: [
      pw.SizedBox(width: double.infinity),
      pw.SizedBox(height: 24),
      pw.Center(
          child: pw.Column(children: [
        pw.Text('ENGAGEMENT DE L\'ÉLÈVE',
            style: _textStyleBold.copyWith(fontSize: 18)),
        pw.SizedBox(height: 16),
        pw.Text('Formation en entreprise',
            style: _textStyleBold.copyWith(fontSize: 16)),
        pw.SizedBox(height: 16),
        pw.RichText(
            text: pw.TextSpan(children: [
          pw.TextSpan(text: 'Je, soussigné${mid}e, ', style: _textStyle),
          pw.TextSpan(
              text: student.fullName.toUpperCase(),
              style:
                  _textStyle.copyWith(decoration: pw.TextDecoration.underline)),
          pw.TextSpan(text: ', m\'engage :', style: _textStyle),
        ])),
        pw.SizedBox(height: 16),
      ])),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                  text:
                      'À observer l\'horaire établi après entente entre les dirigeants${mid}e${mid}s '
                      'de l\'entreprise et l\'école secondaire ',
                  style: _textStyle),
              pw.TextSpan(
                  text: school.name.toUpperCase(),
                  style: _textStyle.copyWith(
                      decoration: pw.TextDecoration.underline)),
              pw.TextSpan(text: ';', style: _textStyle),
            ],
          ),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                  text:
                      'À prévenir, le plus tôt possible, l\'enseignant${mid}e responsable des stages '
                      'de l\'école secondaire ',
                  style: _textStyle),
              pw.TextSpan(
                  text: school.name.toUpperCase(),
                  style: _textStyle.copyWith(
                      decoration: pw.TextDecoration.underline)),
              pw.TextSpan(
                  text: ' et mon employeur de toute absence, de tout '
                      'accident au travail ou de tout autre problème qui pourrait survenir lors de ma '
                      'formation;',
                  style: _textStyle),
            ],
          ),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'À fournir à la personne désignée un billet médical ou légal pour justifier toute absence;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'À ne pas demander ni directement ni indirectement, de salaire ou de compensation '
                  'pour le travail effectué durant les heures de formation;',
              style: _textStyle.copyWith(color: PdfColors.red)),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                  text:
                      'À faire toute la période de formation exigée par l\'école secondaire ',
                  style: _textStyle),
              pw.TextSpan(
                  text: school.name.toUpperCase(),
                  style: _textStyle.copyWith(
                      decoration: pw.TextDecoration.underline)),
              pw.TextSpan(
                  text: ' et l\'entreprise de formation;', style: _textStyle)
            ],
          ),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'À demander des explications supplémentaires lorsqu\'il y a doute pour éviter '
                  'des erreurs coûteuses;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'À me conformer aux règlements, politiques et mesures de sécurité relatives '
                  'aux tâches qui me seront assignées;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'À suivre les règlements de l\'ENTREPRISE et du ${schoolBoard.name.toUpperCase()} '
                  'en me conformant aux politiques, directives et pratiques courantes dont on m\'aura '
                  'préalablement informé${mid}e, notamment les règles d\'utilisation du matériel '
                  'informatique et technologique (cellulaire, internet, réseaux sociaux, etc.);',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'À respecter la propriété des autres et à ne jamais m\'approprier ce qui n\'est '
                  'pas à moi;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'À informer l\'enseignant${mid}e responsable des stages à l\'école si je n\'ai '
                  'pas accès à l\'équipement de protection individuelle (EPI) en lien avec les mesures '
                  'sanitaires et les tâches exécutées en milieu de stage;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'À respecter les règles de santé, de sécurité, d\'hygiène et de salubrité '
                  'selon les techniques de travail et les normes prescrites.',
              style: _textStyle),
        ),
      ),
      pw.SizedBox(height: 24),
      _signature('Signature de l\'élève'),
    ],
  );
}

pw.Widget _contract(BuildContext context, {required String internshipId}) {
  final internship = _internship(context, internshipId: internshipId);
  final schoolBoard =
      _schoolBoard(context, schoolBoardId: internship.schoolBoardId);
  final student = _student(context, studentId: internship.studentId);
  final school = _school(context,
      schoolBoardId: student.schoolBoardId, schoolId: student.schoolId);
  final enterprise =
      _enterprise(context, enterpriseId: internship.enterpriseId);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisSize: pw.MainAxisSize.max,
    children: [
      pw.SizedBox(width: double.infinity),
      pw.Center(
        child: pw.Text('ENTENTE', style: _textStyleBold.copyWith(fontSize: 18)),
      ),
      pw.SizedBox(height: 16),
      pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          child: pw.Text('Entre le ${schoolBoard.name.toUpperCase()}',
              style: _textStyleBold.copyWith(fontSize: 16))),
      pw.SizedBox(height: 16),
      pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          child: pw.Text('L\'école ${school.name.toUpperCase()}',
              style: _textStyleBold.copyWith(fontSize: 16))),
      pw.SizedBox(height: 16),
      pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          child: pw.Text('Et l\'entreprise ${enterprise.name}',
              style: _textStyleBold.copyWith(fontSize: 16))),
      pw.SizedBox(height: 24),
      pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12.0),
          child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
              ),
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              child: pw.Text('Objet : ${_title(student.program)}',
                  style: _textStyleBold.copyWith(fontSize: 14)))),
      pw.SizedBox(height: 24),
      pw.RichText(
          text: pw.TextSpan(text: 'Il est entendu :', style: _textStyle)),
      pw.SizedBox(height: 16),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'Que les modalités de la formation concernant la durée, l\'horaire, et les '
                  'tâches à effectuer doivent faire l\'objet d\'un accord entre les parties et '
                  'doivent être respectés;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'Que l\'employeur assigne un travailleur parrain qui se charge '
                  'd\'accompagner le ou la stagiaire et ce, pour toute la durée de la formation en '
                  'entreprise;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                  text: 'Que le stagiaire travaille sous la supervision ',
                  style: _textStyle),
              pw.TextSpan(
                  text: 'd\'une personne déléguée',
                  style: _textStyle.copyWith(
                      decoration: pw.TextDecoration.underline)),
              pw.TextSpan(text: ' par l\'employeur;', style: _textStyle),
            ],
          ),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'Que le stagiaire ne se substitue d\'aucune manière à l\'employé en fonction '
                  'mais travaille avec ce dernier en vue de parfaire sa formation;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'Que l\'enseignant responsable des stages a la liberté de se rendre '
                  'régulièrement dans l\'entreprise où a lieu la formation afin d\'échanger avec '
                  'le stagiaire et avec le travailleur parrain;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                  text:
                      'Que l\'employeur et le travailleur parrain s\'engagent à participer à '
                      'l\'évaluation du stagiaire selon les modalités convenues avec l\'enseignant '
                      'ou l\'enseignante responsable des stages de l\'école secondaire ',
                  style: _textStyle),
              pw.TextSpan(
                  text: school.name.toUpperCase(),
                  style: _textStyle.copyWith(
                      decoration: pw.TextDecoration.underline)),
              pw.TextSpan(text: ';', style: _textStyle)
            ],
          ),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'Que l\'employeur informe l\'élève sur les normes de la santé et sécurité '
                  'obligatoires dans son entreprise;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'Que la Loi sur les accidents de travail et les maladies professionnelles '
                  'protège automatiquement le stagiaire qui effectue une formation non '
                  'rémunérée sous la responsabilité d\'un établissement d\'enseignement;',
              style: _textStyle),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: 'Que le ', style: _textStyle),
              pw.TextSpan(
                  text: schoolBoard.name.toUpperCase(),
                  style: _textStyle.copyWith(
                      decoration: pw.TextDecoration.underline)),
              pw.TextSpan(
                  text: ' acquitte la cotisation pour '
                      'la protection assurée par la Loi. Le numéro de dossier du ',
                  style: _textStyle),
              pw.TextSpan(
                  text: schoolBoard.name.toUpperCase(),
                  style: _textStyle.copyWith(
                      decoration: pw.TextDecoration.underline)),
              pw.TextSpan(
                  text: ' pour la Commission des normes, de l\'équité, de la '
                      'santé et de la sécurité du travail (CNESST) est: ',
                  style: _textStyle),
              pw.TextSpan(
                  text: schoolBoard.cnesstNumber,
                  style: _textStyle.copyWith(
                      decoration: pw.TextDecoration.underline)),
              pw.TextSpan(text: ';', style: _textStyle),
            ],
          ),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: 'Que le ', style: _textStyle),
              pw.TextSpan(
                  text: schoolBoard.name.toUpperCase(),
                  style: _textStyle.copyWith(
                      decoration: pw.TextDecoration.underline)),
              pw.TextSpan(
                  text: ' s\'engage à ajouter le '
                      'stagiaire comme assuré supplémentaire dans son contrat d\'assurance '
                      'responsabilité civile pendant la période de stage;',
                  style: _textStyle),
            ],
          ),
        ),
      ),
      _BulletPoint(
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
              text:
                  'Que les parties contractantes peuvent, après entente, mettre fin au stage '
                  'de l\'élève.',
              style: _textStyle),
        ),
      ),
      pw.SizedBox(height: 24),
      pw.Text('En foi de quoi, les parties ont signé la présente :',
          style: _textStyleBold),
      pw.SizedBox(height: 24),
      _signature('Signature de l\'employeur'),
      pw.SizedBox(height: 24),
      _signature('Signature de l\'enseignant\nresponsable des stages'),
      pw.SizedBox(height: 24),
      _signature('Signature du stagiaire'),
    ],
  );
}

class _BulletPoint extends pw.StatelessWidget {
  _BulletPoint({required this.child});

  final pw.Widget child;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('\u0097', style: _textStyle),
          pw.SizedBox(width: 6.0),
          pw.Expanded(child: child),
        ],
      ),
      padding: const pw.EdgeInsets.only(bottom: 12.0),
    );
  }
}

pw.Widget _signature(String person) {
  return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(children: [
          pw.Text('______________________________________________',
              style: _textStyleBold),
          pw.Text(person, style: _textStyle, textAlign: pw.TextAlign.center),
        ]),
        pw.Column(children: [
          pw.Text('____________________________', style: _textStyleBold),
          pw.Text('Date (année/mois/jour)', style: _textStyle),
        ]),
      ]);
}

pw.Widget _studentInformations(BuildContext context,
    {required String internshipId}) {
  final internship = _internship(context, internshipId: internshipId);
  final student = _student(context, studentId: internship.studentId);
  final school = _school(context,
      schoolBoardId: student.schoolBoardId, schoolId: student.schoolId);
  final teacher = _teacher(context, teacherId: internship.signatoryTeacherId);
  final enterprise =
      _enterprise(context, enterpriseId: internship.enterpriseId);
  final specialization =
      _job(context, enterpriseId: enterprise.id, jobId: internship.jobId)
          .specialization;

  return pw.Column(
    mainAxisSize: pw.MainAxisSize.max,
    children: [
      pw.SizedBox(width: double.infinity),
      pw.Text('RENSEIGNEMENTS SUR LE STAGIAIRE',
          style: _textStyleBold.copyWith(fontSize: 18)),
      pw.SizedBox(height: 16),
      _textCell(
          title: 'Nom du stagiaire', content: student.fullName.toUpperCase()),
      pw.Row(children: [
        pw.Expanded(
            child: _textCell(
          title: 'Téléphone',
          content: student.phone?.toString() ?? 'N/A',
        )),
        pw.Expanded(
            child: _textCell(
          title: 'Téléphone urgence',
          content: student.contact.phone?.toString() ?? 'N/A',
        )),
      ]),
      _textCell(
          title: 'Âge',
          content: student.dateBirth?.year == null
              ? 'N/A'
              : '${DateTime.now().difference(student.dateBirth!).inDays ~/ 365} ans'),
      _textCell(
        title: 'Nom de l\'enseignant responsable',
        content: teacher.fullName.toUpperCase(),
        sameLine: false,
      ),
      _textCell(
        title: 'Nom, adresse et téléphone de l\'école',
        content: '${school.name.toUpperCase()}\n'
            '${school.address.toString()}\n'
            '${school.phone.toString()}',
        sameLine: false,
      ),
      pw.SizedBox(height: 12),
      _textCell(
        title: 'Date de début du stage',
        content: DateFormat('yyyy-MM-dd').format(internship.dates.start),
      ),
      _textCell(
        title: 'Code et nom du métier semi-spécialisé',
        content: specialization.idWithName,
        sameLine: false,
      ),
      _checkBoxCell(
          title: 'Transport',
          content: Transportation.values.asMap().map((key, value) {
            final transportation = Transportation.deserialize(key);
            return MapEntry(transportation.toString(),
                internship.transportations.contains(transportation));
          })),
      _textCell(
        title: 'Fréquence de visites du superviseur',
        content: internship.visitFrequencies,
        sameLine: false,
      ),
      _textCell(
        title: 'Nom du parrain dans l\'entreprise',
        content: internship.supervisor.fullName.toUpperCase(),
        sameLine: false,
      ),
      _textCell(
        title: 'Nom, adresse et téléphone de l\'entreprise',
        content: '${enterprise.name.toUpperCase()}\n'
            '${enterprise.address.toString()}\n'
            '${enterprise.phone.toString()}',
        sameLine: false,
      ),
      _schedulesCell(
        title: 'Horaire de travail (et heure de la pause)',
        content: internship.weeklySchedules,
      ),
    ],
  );
}

pw.Widget _textCell({String? title, String? content, bool sameLine = true}) {
  return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      decoration:
          pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
      child: pw.Flex(
        direction: sameLine ? pw.Axis.horizontal : pw.Axis.vertical,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (title != null)
            pw.Text('$title : ', style: _textStyleBold.copyWith(fontSize: 14)),
          if (content != null)
            pw.Padding(
              padding: pw.EdgeInsets.only(left: sameLine ? 0.0 : 12.0),
              child: pw.Text(content, style: _textStyle.copyWith(fontSize: 14)),
            ),
        ],
      ));
}

pw.Widget _checkBoxCell({String? title, required Map<String, bool> content}) {
  return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      decoration:
          pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
      child: pw.Row(children: [
        pw.Text('$title : ', style: _textStyleBold.copyWith(fontSize: 14)),
        pw.Expanded(
            child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: content.entries.map((entry) {
            return pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
              pw.Text(entry.key, style: _textStyle.copyWith(fontSize: 14)),
              pw.SizedBox(width: 6.0),
              pw.Container(
                  decoration: entry.value
                      ? pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black))
                      : null,
                  child: pw.Checkbox(
                    value: entry.value,
                    name: entry.key,
                    checkColor: PdfColors.black,
                    activeColor: PdfColors.white,
                  )),
            ]);
          }).toList(),
        ))
      ]));
}

pw.Widget _schedulesCell(
    {required String title, required List<WeeklySchedule> content}) {
  final mid = ' - ';
  final style = _textStyle.copyWith(fontSize: 14);
  return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      decoration:
          pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$title : ', style: _textStyleBold.copyWith(fontSize: 14)),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12.0),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: content.isEmpty
                  ? [pw.Text('Aucun horaire défini', style: style)]
                  : content
                      .map(
                        (weeklySchedule) => pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (content.length > 1)
                              pw.Padding(
                                  padding: const pw.EdgeInsets.only(
                                      top: 4.0, bottom: 2.0),
                                  child: pw.Text(
                                      'Du ${DateFormat('yyyy-MM-dd').format(weeklySchedule.period.start)} '
                                      'au ${DateFormat('yyyy-MM-dd').format(weeklySchedule.period.end)}',
                                      style: _textStyleBold.copyWith(
                                          fontSize: 14))),
                            pw.Padding(
                              padding: pw.EdgeInsets.only(
                                  left: content.length > 1 ? 4.0 : 0.0,
                                  bottom: weeklySchedule != content.last
                                      ? 8.0
                                      : 0.0),
                              child: pw.Table(
                                children: weeklySchedule.schedule.entries
                                    .map<pw.TableRow>(
                                  (pair) {
                                    final day = pair.key;
                                    final entry = pair.value;
                                    return pw.TableRow(children: [
                                      pw.Text(day.name, style: style),
                                      pw.SizedBox(width: 20.0),
                                      pw.Text(
                                          '${entry?.blocks.first.start.hour}:${entry?.blocks.first.start.minute.toString().padLeft(2, '0')}',
                                          style: style),
                                      pw.Text(mid, style: style),
                                      pw.Text(
                                          (entry?.blocks.length ?? 0) > 1
                                              ? '${entry?.blocks[1].end.hour}:${entry?.blocks[1].end.minute.toString().padLeft(2, '0')}'
                                              : '${entry?.blocks.first.end.hour}:${entry?.blocks.first.end.minute.toString().padLeft(2, '0')}',
                                          style: style),
                                      if ((entry?.blocks.length ?? 0) > 1)
                                        pw.Padding(
                                            padding: const pw.EdgeInsets.only(
                                                left: 8.0),
                                            child: pw.Text(
                                                '(${entry?.blocks[0].end.hour}:${entry?.blocks[0].end.minute.toString().padLeft(2, '0')} - '
                                                '${entry?.blocks[1].start.hour}:${entry?.blocks[1].start.minute.toString().padLeft(2, '0')})',
                                                style: style)),
                                      pw.SizedBox(width: double.infinity),
                                    ]);
                                  },
                                ).toList(),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ));
}

Internship _internship(BuildContext context, {required String internshipId}) =>
    InternshipsProvider.of(context, listen: false).fromId(internshipId);

Job _job(BuildContext context,
        {required String enterpriseId, required String jobId}) =>
    _enterprise(context, enterpriseId: enterpriseId).jobs[jobId];

SchoolBoard _schoolBoard(BuildContext context,
        {required String schoolBoardId}) =>
    SchoolBoardsProvider.of(context, listen: false).fromId(schoolBoardId);

School _school(BuildContext context,
        {required String schoolBoardId, required String schoolId}) =>
    _schoolBoard(context, schoolBoardId: schoolBoardId)
        .schools
        .firstWhere((school) => school.id == schoolId);

Enterprise _enterprise(BuildContext context, {required String enterpriseId}) =>
    EnterprisesProvider.of(context, listen: false).fromId(enterpriseId);

Teacher _teacher(BuildContext context, {required String teacherId}) =>
    TeachersProvider.of(context, listen: false).fromId(teacherId);

student_model.Student _student(BuildContext context,
        {required String studentId}) =>
    StudentsProvider.of(context, listen: false).fromId(studentId);
