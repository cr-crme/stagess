import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation.dart';

double _doubleFromSerialized(num? number, {double defaultValue = 0}) {
  if (number is int) return number.toDouble();
  return double.parse(((number ?? defaultValue) as double).toStringAsFixed(5));
}

class PostInternshipEnterpriseEvaluation extends InternshipEvaluation {
  PostInternshipEnterpriseEvaluation({
    super.id,
    required this.date,
    required this.internshipId,
    required this.skillsRequired,
    required this.taskVariety,
    required this.trainingPlanRespect,
    required this.autonomyExpected,
    required this.efficiencyExpected,
    required this.specialNeedsAccommodation,
    required this.supervisionStyle,
    required this.easeOfCommunication,
    required this.absenceAcceptance,
    required this.sstManagement,
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
        specialNeedsAccommodation =
            _doubleFromSerialized(map?['special_needs_accommodation']),
        supervisionStyle = _doubleFromSerialized(map?['supervision_style']),
        easeOfCommunication =
            _doubleFromSerialized(map?['ease_of_communication']),
        absenceAcceptance = _doubleFromSerialized(map?['absence_acceptance']),
        sstManagement = _doubleFromSerialized(map?['sst_management']),
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
    double? specialNeedsAccommodation,
    double? supervisionStyle,
    double? easeOfCommunication,
    double? absenceAcceptance,
    double? sstManagement,
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
      specialNeedsAccommodation:
          specialNeedsAccommodation ?? this.specialNeedsAccommodation,
      supervisionStyle: supervisionStyle ?? this.supervisionStyle,
      easeOfCommunication: easeOfCommunication ?? this.easeOfCommunication,
      absenceAcceptance: absenceAcceptance ?? this.absenceAcceptance,
      sstManagement: sstManagement ?? this.sstManagement,
    );
  }

  PostInternshipEnterpriseEvaluation copyWithData(
      Map<String, dynamic>? serialized) {
    if (serialized == null || serialized.isEmpty) return copyWith();

    return PostInternshipEnterpriseEvaluation(
      id: serialized['id'] ?? id,
      date: DateTimeExt.from(serialized['date']) ?? date,
      internshipId: serialized['internship_id'] ?? internshipId,
      skillsRequired: ListExt.from(serialized['skills_required'],
              deserializer: (e) => StringExt.from(e)!) ??
          skillsRequired,
      taskVariety: _doubleFromSerialized(serialized['task_variety'],
          defaultValue: taskVariety),
      trainingPlanRespect: _doubleFromSerialized(
          serialized['training_plan_respect'],
          defaultValue: trainingPlanRespect),
      autonomyExpected: _doubleFromSerialized(serialized['autonomy_expected'],
          defaultValue: autonomyExpected),
      efficiencyExpected: _doubleFromSerialized(
          serialized['efficiency_expected'],
          defaultValue: efficiencyExpected),
      specialNeedsAccommodation: _doubleFromSerialized(
          serialized['special_needs_accommodation'],
          defaultValue: specialNeedsAccommodation),
      supervisionStyle: _doubleFromSerialized(serialized['supervision_style'],
          defaultValue: supervisionStyle),
      easeOfCommunication: _doubleFromSerialized(
          serialized['ease_of_communication'],
          defaultValue: easeOfCommunication),
      absenceAcceptance: _doubleFromSerialized(serialized['absence_acceptance'],
          defaultValue: absenceAcceptance),
      sstManagement: _doubleFromSerialized(serialized['sst_management'],
          defaultValue: sstManagement),
    );
  }

  String internshipId;
  @override
  DateTime date;

  // Prerequisites
  final List<String> skillsRequired;

  // Tasks
  final double taskVariety;
  final double trainingPlanRespect;
  final double autonomyExpected;
  final double efficiencyExpected;
  final double specialNeedsAccommodation;

  // Management
  final double supervisionStyle;
  final double easeOfCommunication;
  final double absenceAcceptance;
  final double sstManagement;

  // Supervision

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
        'special_needs_accommodation': specialNeedsAccommodation,
        'supervision_style': supervisionStyle,
        'ease_of_communication': easeOfCommunication,
        'absence_acceptance': absenceAcceptance,
        'sst_management': sstManagement,
      };

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'date': FetchableFields.optional,
        'internship_id': FetchableFields.mandatory,
        'skills_required': FetchableFields.optional,
        'task_variety': FetchableFields.optional,
        'training_plan_respect': FetchableFields.optional,
        'autonomy_expected': FetchableFields.optional,
        'efficiency_expected': FetchableFields.optional,
        'special_needs_accommodation': FetchableFields.optional,
        'supervision_style': FetchableFields.optional,
        'ease_of_communication': FetchableFields.optional,
        'absence_acceptance': FetchableFields.optional,
        'sst_management': FetchableFields.optional,
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
        'specialNeedsAccommodation: $specialNeedsAccommodation, '
        'supervisionStyle: $supervisionStyle, '
        'easeOfCommunication: $easeOfCommunication, '
        'absenceAcceptance: $absenceAcceptance, '
        'sstManagement: $sstManagement, '
        '}';
  }
}
