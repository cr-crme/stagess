import 'package:crcrme_material_theme/crcrme_material_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/student_visa.dart';
import 'package:stagess_common/services/job_data_file_service.dart'
    as job_service;
import 'package:stagess_common_flutter/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/pdf/visa_pdf_template.dart';

// coverage:ignore-start
void main() async {
  runApp(StagessApp());
}
// coverage:ignore-end

class StagessApp extends StatelessWidget {
  const StagessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => 'Stagess',
      theme: crcrmeMaterialTheme,
      home: MainPage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'CA')],
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final visa = StudentVisa(
        date: DateTime.now(),
        form: VisaForm(
            experiencesAndAptitudes: [
              ExperiencesAndAptitudes(
                  index: 0, isSelected: true, text: 'Experience 1'),
              ExperiencesAndAptitudes(
                  index: 1, isSelected: true, text: 'Experience 2'),
            ],
            attestationsAndMentions: [
              AttestationsAndMentions(
                  index: 0, isSelected: true, text: 'Attestation 1'),
              AttestationsAndMentions(
                  index: 1, isSelected: true, text: 'Attestation 2'),
            ],
            sstTrainings: [
              SstTraining(
                  index: 0,
                  isSelected: true,
                  trainingId: SstTraining.availableTrainings.keys.first,
                  isHidden: false),
              SstTraining(
                  index: 1,
                  isSelected: true,
                  trainingId: SstTraining.availableTrainings.keys.elementAt(1),
                  isHidden: false),
            ],
            isGatewayToFmsAvailable: false,
            certificates: [
              Certificate(
                  index: 0,
                  isSelected: true,
                  certificateType: CertificateType.fpt)
            ],
            skills: [
              Skill(
                  index: 0,
                  isSelected: true,
                  skillId:
                      job_service.ActivitySectorsService.allSkills.first.id)
            ],
            references: [
              Reference(
                  index: 0,
                  isSelected: true,
                  referee: 'Referee 1',
                  enterprise: 'Enterprise 1',
                  phoneNumber: PhoneNumber.fromString('123-456-7890'),
                  email: 'referee1@example.com',
                  supplementaryInfo: 'Reference 1 supplementary info'),
            ],
            forces: [
              Attitude(
                  index: 0,
                  isSelected: true,
                  attitudeId: Attitude.availableItems.keys.first)
            ],
            challenges: [
              Attitude(
                  index: 0,
                  isSelected: true,
                  attitudeId: Attitude.availableItems.keys.elementAt(1))
            ],
            successConditions: [
              SuccessConditions(
                  index: 0, isSelected: true, text: 'Success Condition 1')
            ]),
        formVersion: StudentVisa.currentVersion);

    return Scaffold(
      appBar: AppBar(title: const Text('Stagess - Main Page')),
      body: Center(
        child: TextButton(
          onPressed: () {
            showPdfDialog(context,
                pdfGeneratorCallback: (context, format) => generateVisaPdf(
                    context, format,
                    studentId: 'Coucou', studentVisa: visa));
          },
          child: const Text('Click me'),
        ),
      ),
    );
  }
}
