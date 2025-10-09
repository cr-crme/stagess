import 'package:flutter/widgets.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';

class AttitudeEvaluationFormController {
  static const _formVersion = '1.0.0';

  AttitudeEvaluationFormController({required this.internshipId});
  final String internshipId;
  Internship internship(context, {listen = true}) =>
      InternshipsProvider.of(context, listen: listen)[internshipId];

  factory AttitudeEvaluationFormController.fromInternshipId(
    context, {
    required String internshipId,
    required int evaluationIndex,
  }) {
    Internship internship =
        InternshipsProvider.of(context, listen: false)[internshipId];
    InternshipEvaluationAttitude evaluation =
        internship.attitudeEvaluations[evaluationIndex];

    final controller = AttitudeEvaluationFormController(
      internshipId: internshipId,
    );

    controller.evaluationDate = evaluation.date;

    controller.wereAtMeeting.clear();
    controller.wereAtMeeting.addAll(evaluation.presentAtEvaluation);

    controller.responses[Inattendance] = evaluation.attitude.inattendance;
    controller.responses[Ponctuality] = evaluation.attitude.ponctuality;
    controller.responses[Sociability] = evaluation.attitude.sociability;
    controller.responses[Politeness] = evaluation.attitude.politeness;
    controller.responses[Motivation] = evaluation.attitude.motivation;
    controller.responses[DressCode] = evaluation.attitude.dressCode;
    controller.responses[QualityOfWork] = evaluation.attitude.qualityOfWork;
    controller.responses[Productivity] = evaluation.attitude.productivity;
    controller.responses[Autonomy] = evaluation.attitude.autonomy;
    controller.responses[Cautiousness] = evaluation.attitude.cautiousness;
    controller.responses[GeneralAppreciation] =
        evaluation.attitude.generalAppreciation;

    controller.commentsController.text = evaluation.comments;

    return controller;
  }

  InternshipEvaluationAttitude toInternshipEvaluation() {
    return InternshipEvaluationAttitude(
      date: evaluationDate,
      presentAtEvaluation: wereAtMeeting,
      attitude: AttitudeEvaluation(
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
      comments: commentsController.text,
      formVersion: _formVersion,
    );
  }

  DateTime evaluationDate = DateTime.now();

  late final wereAtMeetingController = CheckboxWithOtherController(
    elements: wereAtMeetingOptions,
    initialValues: wereAtMeeting,
  );
  final List<String> wereAtMeetingOptions = [
    'Stagiaire',
    'Responsable en milieu de stage',
  ];
  final List<String> wereAtMeeting = [];
  void setWereAtMeeting() {
    wereAtMeeting.clear();
    wereAtMeeting.addAll(wereAtMeetingController.values);
  }

  Map<Type, AttitudeCategoryEnum?> responses = {};

  final commentsController = TextEditingController();

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
