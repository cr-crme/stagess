import 'package:flutter/material.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation_visa.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

class VisaEvaluationFormController {
  static const _formVersion = '1.0.0';

  VisaEvaluationFormController({required this.internshipId});
  final String internshipId;
  Internship internship(BuildContext context, {bool listen = true}) =>
      InternshipsProvider.of(context, listen: listen)[internshipId];

  factory VisaEvaluationFormController.fromInternshipId(
    BuildContext context, {
    required String internshipId,
    required int evaluationIndex,
  }) {
    Internship internship =
        InternshipsProvider.of(context, listen: false)[internshipId];
    InternshipEvaluationVisa visaForm =
        internship.visaEvaluations[evaluationIndex];

    final controller = VisaEvaluationFormController(internshipId: internshipId);

    controller.evaluationDate = visaForm.date;

    controller.responses[Inattendance] = visaForm.form.inattendance;
    controller.responses[Ponctuality] = visaForm.form.ponctuality;
    controller.responses[Sociability] = visaForm.form.sociability;
    controller.responses[Politeness] = visaForm.form.politeness;
    controller.responses[Motivation] = visaForm.form.motivation;
    controller.responses[DressCode] = visaForm.form.dressCode;
    controller.responses[QualityOfWork] = visaForm.form.qualityOfWork;
    controller.responses[Productivity] = visaForm.form.productivity;
    controller.responses[Autonomy] = visaForm.form.autonomy;
    controller.responses[Cautiousness] = visaForm.form.cautiousness;
    controller.responses[GeneralAppreciation] =
        visaForm.form.generalAppreciation;

    return controller;
  }

  InternshipEvaluationVisa toInternshipEvaluation() {
    return InternshipEvaluationVisa(
      date: evaluationDate,
      form: VisaEvaluation(
        inattendance: responses[Inattendance]! as Inattendance,
        ponctuality: responses[Ponctuality]! as Ponctuality,
        sociability: responses[Sociability]! as Sociability,
        politeness: responses[Politeness]! as Politeness,
        motivation: responses[Motivation]! as Motivation,
        dressCode: responses[DressCode]! as DressCode,
        qualityOfWork: responses[QualityOfWork]! as QualityOfWork,
        productivity: responses[Productivity]! as Productivity,
        autonomy: responses[Autonomy]! as Autonomy,
        cautiousness: responses[Cautiousness]! as Cautiousness,
        generalAppreciation:
            responses[GeneralAppreciation]! as GeneralAppreciation,
      ),
      formVersion: _formVersion,
    );
  }

  DateTime evaluationDate = DateTime.now();
  Map<Type, VisaCategoryEnum?> responses = {};

  bool get isAttitudeCompleted =>
      responses[Inattendance] != null &&
      responses[Ponctuality] != null &&
      responses[Sociability] != null &&
      responses[Politeness] != null &&
      responses[Motivation] != null &&
      responses[DressCode] != null;

  bool get isSkillCompleted =>
      responses[QualityOfWork] != null &&
      responses[Productivity] != null &&
      responses[Autonomy] != null &&
      responses[Cautiousness] != null;

  bool get isGeneralAppreciationCompleted =>
      responses[GeneralAppreciation] != null;

  bool get isCompleted =>
      isAttitudeCompleted && isSkillCompleted && isGeneralAppreciationCompleted;
}
