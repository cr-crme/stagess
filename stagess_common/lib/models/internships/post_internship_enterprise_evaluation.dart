import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/internships/internship.dart';

double _doubleFromSerialized(num? number, {double defaultValue = 0}) {
  if (number is int) return number.toDouble();
  return double.parse(((number ?? defaultValue) as double).toStringAsFixed(5));
}

class PostInternshipEnterpriseEvaluation extends ItemSerializable {
  PostInternshipEnterpriseEvaluation({
    super.id,
    required this.date,
    required this.internshipId,
    required this.skillsRequired,
    required this.taskVariety,
    required this.trainingPlanRespect,
    required this.autonomyExpected,
    required this.efficiencyExpected,
    required this.supervisionStyle,
    required this.easeOfCommunication,
    required this.absenceAcceptance,
    required this.supervisionComments,
    required this.acceptanceTsa,
    required this.acceptanceLanguageDisorder,
    required this.acceptanceIntellectualDisability,
    required this.acceptancePhysicalDisability,
    required this.acceptanceMentalHealthDisorder,
    required this.acceptanceBehaviorDifficulties,
  });

  PostInternshipEnterpriseEvaluation.fromSerialized(super.map)
      : internshipId = map?['internship_id'] ?? '',
        date = DateTimeExt.from(map?['date']) ?? DateTime(0),
        skillsRequired = ListExt.from(map?['skills_required'],
                deserializer: (e) => StringExt.from(e)!) ??
            [],
        taskVariety = _doubleFromSerialized(map?['task_variety']),
        trainingPlanRespect =
            _doubleFromSerialized(map?['training_plan_respect']),
        autonomyExpected = _doubleFromSerialized(map?['autonomy_expected']),
        efficiencyExpected = _doubleFromSerialized(map?['efficiency_expected']),
        supervisionStyle = _doubleFromSerialized(map?['supervision_style']),
        easeOfCommunication =
            _doubleFromSerialized(map?['ease_of_communication']),
        absenceAcceptance = _doubleFromSerialized(map?['absence_acceptance']),
        supervisionComments = map?['supervision_comments'] ?? '',
        acceptanceTsa = _doubleFromSerialized(map?['acceptance_tsa']),
        acceptanceLanguageDisorder =
            _doubleFromSerialized(map?['acceptance_language_disorder']),
        acceptanceIntellectualDisability =
            _doubleFromSerialized(map?['acceptance_intellectual_disability']),
        acceptancePhysicalDisability =
            _doubleFromSerialized(map?['acceptance_physical_disability']),
        acceptanceMentalHealthDisorder =
            _doubleFromSerialized(map?['acceptance_mental_health_disorder']),
        acceptanceBehaviorDifficulties =
            _doubleFromSerialized(map?['acceptance_behavior_difficulties']),
        super.fromSerialized();

  PostInternshipEnterpriseEvaluation copyWith({
    String? id,
    DateTime? date,
    String? internshipId,
    List<String>? skillsRequired,
    double? taskVariety,
    double? trainingPlanRespect,
    double? autonomyExpected,
    double? efficiencyExpected,
    double? supervisionStyle,
    double? easeOfCommunication,
    double? absenceAcceptance,
    String? supervisionComments,
    double? acceptanceTsa,
    double? acceptanceLanguageDisorder,
    double? acceptanceIntellectualDisability,
    double? acceptancePhysicalDisability,
    double? acceptanceMentalHealthDisorder,
    double? acceptanceBehaviorDifficulties,
  }) {
    return PostInternshipEnterpriseEvaluation(
        id: id ?? this.id,
        date: date ?? this.date,
        internshipId: internshipId ?? this.internshipId,
        skillsRequired: skillsRequired ?? this.skillsRequired,
        taskVariety: taskVariety ?? this.taskVariety,
        trainingPlanRespect: trainingPlanRespect ?? this.trainingPlanRespect,
        autonomyExpected: autonomyExpected ?? this.autonomyExpected,
        efficiencyExpected: efficiencyExpected ?? this.efficiencyExpected,
        supervisionStyle: supervisionStyle ?? this.supervisionStyle,
        easeOfCommunication: easeOfCommunication ?? this.easeOfCommunication,
        absenceAcceptance: absenceAcceptance ?? this.absenceAcceptance,
        supervisionComments: supervisionComments ?? this.supervisionComments,
        acceptanceTsa: acceptanceTsa ?? this.acceptanceTsa,
        acceptanceLanguageDisorder:
            acceptanceLanguageDisorder ?? this.acceptanceLanguageDisorder,
        acceptanceIntellectualDisability: acceptanceIntellectualDisability ??
            this.acceptanceIntellectualDisability,
        acceptancePhysicalDisability:
            acceptancePhysicalDisability ?? this.acceptancePhysicalDisability,
        acceptanceMentalHealthDisorder: acceptanceMentalHealthDisorder ??
            this.acceptanceMentalHealthDisorder,
        acceptanceBehaviorDifficulties: acceptanceBehaviorDifficulties ??
            this.acceptanceBehaviorDifficulties);
  }

  PostInternshipEnterpriseEvaluation copyWithData(
      Map<String, dynamic>? serialized) {
    if (serialized == null || serialized.isEmpty) return copyWith();

    return PostInternshipEnterpriseEvaluation(
        id: serialized['id'] ?? id,
        date: DateTimeExt.from(serialized['date']) ?? date,
        internshipId: serialized['internship_id'] ?? internshipId,
        skillsRequired: ListExt.from(serialized['skills_required'], deserializer: (e) => StringExt.from(e)!) ??
            skillsRequired,
        taskVariety: _doubleFromSerialized(serialized['task_variety'],
            defaultValue: taskVariety),
        trainingPlanRespect: _doubleFromSerialized(serialized['training_plan_respect'],
            defaultValue: trainingPlanRespect),
        autonomyExpected: _doubleFromSerialized(serialized['autonomy_expected'],
            defaultValue: autonomyExpected),
        efficiencyExpected: _doubleFromSerialized(serialized['efficiency_expected'],
            defaultValue: efficiencyExpected),
        supervisionStyle: _doubleFromSerialized(serialized['supervision_style'],
            defaultValue: supervisionStyle),
        easeOfCommunication: _doubleFromSerialized(serialized['ease_of_communication'],
            defaultValue: easeOfCommunication),
        absenceAcceptance: _doubleFromSerialized(serialized['absence_acceptance'],
            defaultValue: absenceAcceptance),
        supervisionComments:
            serialized['supervision_comments'] ?? supervisionComments,
        acceptanceTsa: _doubleFromSerialized(serialized['acceptance_tsa'],
            defaultValue: acceptanceTsa),
        acceptanceLanguageDisorder: _doubleFromSerialized(
            serialized['acceptance_language_disorder'],
            defaultValue: acceptanceLanguageDisorder),
        acceptanceIntellectualDisability: _doubleFromSerialized(
            serialized['acceptance_intellectual_disability'],
            defaultValue: acceptanceIntellectualDisability),
        acceptancePhysicalDisability: _doubleFromSerialized(serialized['acceptance_physical_disability'], defaultValue: acceptancePhysicalDisability),
        acceptanceMentalHealthDisorder: _doubleFromSerialized(serialized['acceptance_mental_health_disorder'], defaultValue: acceptanceMentalHealthDisorder),
        acceptanceBehaviorDifficulties: _doubleFromSerialized(serialized['acceptance_behavior_difficulties'], defaultValue: acceptanceBehaviorDifficulties));
  }

  String internshipId;
  DateTime date;

  // Prerequisites
  final List<String> skillsRequired;

  // Tasks
  final double taskVariety;
  final double trainingPlanRespect;
  final double autonomyExpected;
  final double efficiencyExpected;

  // Management
  final double supervisionStyle;
  final double easeOfCommunication;
  final double absenceAcceptance;
  final String supervisionComments;

  // Supervision
  final double acceptanceTsa;
  final double acceptanceLanguageDisorder;
  final double acceptanceIntellectualDisability;
  final double acceptancePhysicalDisability;
  final double acceptanceMentalHealthDisorder;
  final double acceptanceBehaviorDifficulties;
  bool get hasDisorder =>
      acceptanceTsa >= 0 ||
      acceptanceLanguageDisorder >= 0 ||
      acceptanceIntellectualDisability >= 0 ||
      acceptancePhysicalDisability >= 0 ||
      acceptanceMentalHealthDisorder >= 0 ||
      acceptanceBehaviorDifficulties >= 0;

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'date': date.serialize(),
        'internship_id': internshipId,
        'skills_required': skillsRequired,
        'task_variety': taskVariety,
        'training_plan_respect': trainingPlanRespect,
        'autonomy_expected': autonomyExpected,
        'efficiency_expected': efficiencyExpected,
        'supervision_style': supervisionStyle,
        'ease_of_communication': easeOfCommunication,
        'absence_acceptance': absenceAcceptance,
        'supervision_comments': supervisionComments,
        'acceptance_tsa': acceptanceTsa,
        'acceptance_language_disorder': acceptanceLanguageDisorder,
        'acceptance_intellectual_disability': acceptanceIntellectualDisability,
        'acceptance_physical_disability': acceptancePhysicalDisability,
        'acceptance_mental_health_disorder': acceptanceMentalHealthDisorder,
        'acceptance_behavior_difficulties': acceptanceBehaviorDifficulties,
      };

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'date': FetchableFields.mandatory,
        'internship_id': FetchableFields.mandatory,
        'skills_required': FetchableFields.optional,
        'task_variety': FetchableFields.optional,
        'training_plan_respect': FetchableFields.optional,
        'autonomy_expected': FetchableFields.optional,
        'efficiency_expected': FetchableFields.optional,
        'supervision_style': FetchableFields.optional,
        'ease_of_communication': FetchableFields.optional,
        'absence_acceptance': FetchableFields.optional,
        'supervision_comments': FetchableFields.optional,
        'acceptance_tsa': FetchableFields.optional,
        'acceptance_language_disorder': FetchableFields.optional,
        'acceptance_intellectual_disability': FetchableFields.optional,
        'acceptance_physical_disability': FetchableFields.optional,
        'acceptance_mental_health_disorder': FetchableFields.optional,
        'acceptance_behavior_difficulties': FetchableFields.optional,
      });

  @override
  String toString() {
    return 'PostInternshipEnterpriseEvaluation{'
        'internshipId: $internshipId, '
        'skillsRequired: $skillsRequired, '
        'taskVariety: $taskVariety, '
        'trainingPlanRespect: $trainingPlanRespect, '
        'autonomyExpected: $autonomyExpected, '
        'efficiencyExpected: $efficiencyExpected, '
        'supervisionStyle: $supervisionStyle, '
        'easeOfCommunication: $easeOfCommunication, '
        'absenceAcceptance: $absenceAcceptance, '
        'supervisionComments: $supervisionComments, '
        'acceptanceTsa: $acceptanceTsa, '
        'acceptanceLanguageDisorder: $acceptanceLanguageDisorder, '
        'acceptanceIntellectualDisability: $acceptanceIntellectualDisability, '
        'acceptancePhysicalDisability: $acceptancePhysicalDisability, '
        'acceptanceMentalHealthDisorder: $acceptanceMentalHealthDisorder, '
        'acceptanceBehaviorDifficulties: $acceptanceBehaviorDifficulties}';
  }
}
