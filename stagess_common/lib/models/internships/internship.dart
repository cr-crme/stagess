import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/extended_item_serializable.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/internships/internship_evaluation_visa.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/time_utils.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/person.dart';

export 'package:stagess_common/models/generic/serializable_elements.dart';

double _doubleFromSerialized(num? number, {double defaultValue = 0}) {
  if (number is int) return number.toDouble();
  return double.parse(((number ?? defaultValue) as double).toStringAsFixed(5));
}

class PostInternshipEnterpriseEvaluation extends ItemSerializable {
  PostInternshipEnterpriseEvaluation({
    super.id,
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

  String internshipId;

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

class InternshipMutableElements extends ItemSerializable {
  InternshipMutableElements({
    super.id,
    required this.creationDate,
    required this.supervisor,
    required this.dates,
    required this.weeklySchedules,
    required this.transportations,
    required this.visitFrequencies,
  });
  final DateTime creationDate;
  final Person supervisor;
  final DateTimeRange dates;
  final List<WeeklySchedule> weeklySchedules;
  final List<Transportation> transportations;
  final String visitFrequencies;

  InternshipMutableElements.fromSerialized(super.map)
      : creationDate =
            DateTimeExt.from(map?['creation_date']) ?? DateTime.now(),
        supervisor = Person.fromSerialized(map?['supervisor']),
        dates = DateTimeRange(
            start: DateTimeExt.from(map?['starting_date']) ?? DateTime(0),
            end: DateTimeExt.from(map?['ending_date']) ?? DateTime(0)),
        weeklySchedules = (map?['schedules'] as List?)
                ?.map((e) => WeeklySchedule.fromSerialized(e))
                .toList() ??
            [],
        transportations = ListExt.from(map?['transportations'],
                deserializer: (e) => Transportation.deserialize(e)) ??
            [],
        visitFrequencies = StringExt.from(map?['visit_frequencies']) ?? 'N/A',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'creation_date': creationDate.serialize(),
        'supervisor': supervisor.serialize(),
        'starting_date': dates.start.serialize(),
        'ending_date': dates.end.serialize(),
        'schedules': weeklySchedules.map((e) => e.serialize()).toList(),
        'transportations': transportations.map((e) => e.serialize()).toList(),
        'visit_frequencies': visitFrequencies.serialize(),
      };

  InternshipMutableElements copyWith({
    DateTime? creationDate,
    Person? supervisor,
    DateTimeRange? dates,
    List<WeeklySchedule>? weeklySchedules,
    List<Transportation>? transportations,
    String? visitFrequencies,
  }) {
    return InternshipMutableElements(
      id: id,
      creationDate: creationDate ?? this.creationDate,
      supervisor: supervisor ?? this.supervisor,
      dates: dates ?? this.dates,
      weeklySchedules: weeklySchedules ?? this.weeklySchedules,
      transportations: transportations ?? this.transportations,
      visitFrequencies: visitFrequencies ?? this.visitFrequencies,
    );
  }

  InternshipMutableElements copyWithData(Map? serialized) {
    if (serialized == null || serialized.isEmpty) return copyWith();

    return InternshipMutableElements(
      id: id,
      creationDate:
          DateTimeExt.from(serialized['creation_date']) ?? creationDate,
      supervisor: supervisor.copyWithData(serialized['supervisor']),
      dates: DateTimeRange(
        start: DateTimeExt.from(serialized['starting_date']) ?? dates.start,
        end: DateTimeExt.from(serialized['ending_date']) ?? dates.end,
      ),
      weeklySchedules: (serialized['schedules'] as List?)
              ?.map((e) => WeeklySchedule.fromSerialized(e))
              .toList() ??
          weeklySchedules,
      transportations: ListExt.from(serialized['transportations'],
              deserializer: (e) => Transportation.deserialize(e)) ??
          transportations,
      visitFrequencies:
          StringExt.from(serialized['visit_frequencies']) ?? visitFrequencies,
    );
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'creation_date': FetchableFields.mandatory,
        'supervisor': Person.fetchableFields,
        'starting_date': FetchableFields.mandatory,
        'ending_date': FetchableFields.mandatory,
        'schedules': WeeklySchedule.fetchableFields,
        'transportations': FetchableFields.optional,
        'visit_frequencies': FetchableFields.optional,
      });

  @override
  String toString() {
    return 'MutableElements{creationDate: $creationDate, '
        'supervisor_id: $supervisor, '
        'dates: $dates, '
        'weeklySchedules: $weeklySchedules}';
  }
}

class Internship extends ExtendedItemSerializable {
  static final String _currentVersion = '1.0.0';
  static String get currentVersion => _currentVersion;

  // Elements fixed across versions of the same stage
  final String schoolBoardId;
  final String studentId;
  final String signatoryTeacherId;
  final List<String> extraSupervisingTeacherIds;

  List<String> get supervisingTeacherIds =>
      [signatoryTeacherId, ...extraSupervisingTeacherIds];

  final String enterpriseId;
  final String jobId; // Main job attached to the enterprise
  final List<String>
      extraSpecializationIds; // Any extra jobs added to the internship
  final int expectedDuration;

  // Elements that can be modified (which increase the version number, but
  // do not require a completely new internship contract)
  final List<InternshipMutableElements> _mutables;
  bool get hasVersions => _mutables.isNotEmpty;
  int get nbVersions => _mutables.length;
  DateTime get creationDate => _mutables.last.creationDate;
  DateTime creationDateFrom(int version) => _mutables[version].creationDate;
  Person get supervisor => _mutables.last.supervisor;
  Person supervisorFrom(int version) => _mutables[version].supervisor;
  DateTimeRange get dates => _mutables.last.dates;
  DateTimeRange dateFrom(int version) => _mutables[version].dates;
  List<WeeklySchedule> get weeklySchedules => _mutables.last.weeklySchedules;
  List<WeeklySchedule> weeklySchedulesFrom(int version) =>
      _mutables[version].weeklySchedules;
  List<Transportation> get transportations => _mutables.last.transportations;
  List<Transportation> transportationsFrom(int version) =>
      _mutables[version].transportations;
  String get visitFrequencies => _mutables.last.visitFrequencies;
  String visitFrequenciesFrom(int version) =>
      _mutables[version].visitFrequencies;
  List<Map<String, dynamic>> get serializedMutables =>
      _mutables.map((e) => e.serialize()).toList();

  // Elements that are parts of the inner working of the internship (can be
  // modify, but won't generate a new version)
  final int achievedDuration;
  final String teacherNotes;
  final DateTime endDate;

  final List<InternshipEvaluationSkill> skillEvaluations;
  final List<InternshipEvaluationAttitude> attitudeEvaluations;
  final List<InternshipEvaluationVisa> visaEvaluations;

  PostInternshipEnterpriseEvaluation? enterpriseEvaluation;

  bool get isClosed => isNotActive && !isEnterpriseEvaluationPending;
  bool get isEnterpriseEvaluationPending =>
      isNotActive && enterpriseEvaluation == null;
  bool get isActive => endDate == DateTime(0);
  bool get isNotActive => !isActive;
  bool get shouldTerminate =>
      isActive && dates.end.difference(DateTime.now()).inDays <= -1;

  void _finalizeInitialization() {
    extraSupervisingTeacherIds.remove(signatoryTeacherId);

    _mutables.sort((a, b) => a.creationDate.compareTo(b.creationDate));
    for (final mutable in _mutables) {
      mutable.weeklySchedules.sort((a, b) {
        if (a.period.start.isBefore(b.period.start)) return -1;
        if (a.period.start.isAfter(b.period.start)) return 1;
        return 0;
      });

      for (final schedule in mutable.weeklySchedules) {
        schedule.schedule.entries.toList().sort((pairA, pairB) {
          final dayA = pairA.key;
          final dayB = pairB.key;
          final a = pairA.value;
          final b = pairB.value;

          if (a == null && b == null) return 0;
          if (a == null) return 1;
          if (b == null) return -1;

          if (dayA.index < dayB.index) return -1;
          if (dayA.index > dayB.index) return 1;

          return 0;
        });
      }
    }

    skillEvaluations.sort((a, b) {
      if (a.date.isBefore(b.date)) return -1;
      if (a.date.isAfter(b.date)) return 1;
      return 0;
    });
    attitudeEvaluations.sort((a, b) {
      if (a.date.isBefore(b.date)) return -1;
      if (a.date.isAfter(b.date)) return 1;
      return 0;
    });
    visaEvaluations.sort((a, b) {
      if (a.date.isBefore(b.date)) return -1;
      if (a.date.isAfter(b.date)) return 1;
      return 0;
    });
  }

  Internship._({
    super.id,
    required this.schoolBoardId,
    required this.studentId,
    required this.signatoryTeacherId,
    required this.extraSupervisingTeacherIds,
    required this.enterpriseId,
    required this.jobId,
    required this.extraSpecializationIds,
    required List<InternshipMutableElements> mutables,
    required this.expectedDuration,
    required this.achievedDuration,
    required this.teacherNotes,
    required this.endDate,
    required this.skillEvaluations,
    required this.attitudeEvaluations,
    required this.visaEvaluations,
    required this.enterpriseEvaluation,
  }) : _mutables = mutables {
    _finalizeInitialization();
  }

  Internship({
    super.id,
    required this.schoolBoardId,
    required this.studentId,
    required this.signatoryTeacherId,
    required this.extraSupervisingTeacherIds,
    required this.enterpriseId,
    required this.jobId,
    required this.extraSpecializationIds,
    required DateTime creationDate,
    required Person supervisor,
    required DateTimeRange dates,
    required List<WeeklySchedule> weeklySchedules,
    required List<Transportation> transportations,
    required String visitFrequencies,
    required this.expectedDuration,
    required this.achievedDuration,
    this.teacherNotes = '',
    required this.endDate,
    List<InternshipEvaluationSkill>? skillEvaluations,
    List<InternshipEvaluationAttitude>? attitudeEvaluations,
    List<InternshipEvaluationVisa>? visaEvaluations,
    this.enterpriseEvaluation,
  })  : _mutables = [
          InternshipMutableElements(
            creationDate: creationDate,
            supervisor: supervisor,
            dates: dates,
            weeklySchedules: weeklySchedules,
            transportations: transportations,
            visitFrequencies: visitFrequencies,
          )
        ],
        skillEvaluations = skillEvaluations ?? [],
        attitudeEvaluations = attitudeEvaluations ?? [],
        visaEvaluations = visaEvaluations ?? [] {
    _finalizeInitialization();
  }

  static Internship get empty => Internship._(
        schoolBoardId: '-1',
        studentId: '',
        signatoryTeacherId: '',
        extraSupervisingTeacherIds: [],
        enterpriseId: '',
        jobId: '',
        extraSpecializationIds: [],
        mutables: [],
        expectedDuration: -1,
        achievedDuration: -1,
        teacherNotes: '',
        endDate: DateTime(0),
        skillEvaluations: [],
        attitudeEvaluations: [],
        visaEvaluations: [],
        enterpriseEvaluation: null,
      );

  Internship.fromSerialized(super.map)
      : schoolBoardId = StringExt.from(map?['school_board_id']) ?? '-1',
        studentId = StringExt.from(map?['student_id']) ?? '',
        signatoryTeacherId = StringExt.from(map?['signatory_teacher_id']) ?? '',
        extraSupervisingTeacherIds = ListExt.from(
                map?['extra_supervising_teacher_ids'],
                deserializer: (e) => StringExt.from(e)!) ??
            [],
        enterpriseId = StringExt.from(map?['enterprise_id']) ?? '',
        jobId = StringExt.from(map?['job_id']) ?? '',
        extraSpecializationIds = ListExt.from(map?['extra_specialization_ids'],
                deserializer: (e) => StringExt.from(e)!) ??
            [],
        _mutables = (map?['mutables'] as List?)
                ?.map(((e) => InternshipMutableElements.fromSerialized(e)))
                .toList() ??
            [],
        expectedDuration = IntExt.from(map?['expected_duration']) ?? -1,
        achievedDuration = IntExt.from(map?['achieved_duration']) ?? -1,
        teacherNotes = StringExt.from(map?['teacher_notes']) ?? '',
        endDate = DateTimeExt.from(map?['end_date']) ?? DateTime(0),
        skillEvaluations = ListExt.from(map?['skill_evaluations'],
                deserializer: (map) =>
                    InternshipEvaluationSkill.fromSerialized(map)) ??
            [],
        attitudeEvaluations = ListExt.from(map?['attitude_evaluations'],
                deserializer: (map) =>
                    InternshipEvaluationAttitude.fromSerialized(map)) ??
            [],
        visaEvaluations = ListExt.from(map?['visa_evaluations'],
                deserializer: (map) =>
                    InternshipEvaluationVisa.fromSerialized(map)) ??
            [],
        enterpriseEvaluation = map?['enterprise_evaluation'] == null
            ? null
            : PostInternshipEnterpriseEvaluation.fromSerialized(
                map?['enterprise_evaluation']),
        super.fromSerialized() {
    _finalizeInitialization();
  }

  @override
  Map<String, dynamic> serializedMap() => {
        'school_board_id': schoolBoardId.serialize(),
        'version': _currentVersion.serialize(),
        'student_id': studentId.serialize(),
        'signatory_teacher_id': signatoryTeacherId.serialize(),
        'extra_supervising_teacher_ids': extraSupervisingTeacherIds.serialize(),
        'enterprise_id': enterpriseId.serialize(),
        'job_id': jobId.serialize(),
        'extra_specialization_ids': extraSpecializationIds.serialize(),
        'mutables': serializedMutables,
        'expected_duration': expectedDuration.serialize(),
        'achieved_duration': achievedDuration.serialize(),
        'teacher_notes': teacherNotes.serialize(),
        'end_date': endDate.serialize(),
        'skill_evaluations': skillEvaluations.serialize(),
        'attitude_evaluations': attitudeEvaluations.serialize(),
        'visa_evaluations': visaEvaluations.serialize(),
        'enterprise_evaluation': enterpriseEvaluation?.serialize(),
      };

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'school_board_id': FetchableFields.mandatory,
        'student_id': FetchableFields.mandatory,
        'signatory_teacher_id': FetchableFields.mandatory,
        'extra_specialization_ids': FetchableFields.mandatory,
        'enterprise_id': FetchableFields.mandatory,
        'job_id': FetchableFields.mandatory,
        'extra_supervising_teacher_ids': FetchableFields.mandatory,
        'mutables': InternshipMutableElements.fetchableFields,
        'expected_duration': FetchableFields.optional,
        'achieved_duration': FetchableFields.optional,
        'teacher_notes': FetchableFields.optional,
        'end_date': FetchableFields.mandatory,
        'skill_evaluations': InternshipEvaluationSkill.fetchableFields,
        'attitude_evaluations': InternshipEvaluationAttitude.fetchableFields,
        'visa_evaluations': InternshipEvaluationVisa.fetchableFields,
        'enterprise_evaluation':
            PostInternshipEnterpriseEvaluation.fetchableFields,
      });

  void addVersion({
    required DateTime creationDate,
    required Person supervisor,
    required DateTimeRange dates,
    required List<WeeklySchedule> weeklySchedules,
    required List<Transportation> transportations,
    required String visitFrequencies,
  }) {
    _mutables.add(InternshipMutableElements(
      creationDate: creationDate,
      supervisor: supervisor,
      dates: dates,
      weeklySchedules: weeklySchedules,
      transportations: transportations,
      visitFrequencies: visitFrequencies,
    ));
  }

  Internship copyWith({
    String? id,
    String? schoolBoardId,
    String? studentId,
    String? signatoryTeacherId,
    List<String>? extraSupervisingTeacherIds,
    String? enterpriseId,
    String? jobId,
    List<String>? extraSpecializationIds,
    int? expectedDuration,
    int? achievedDuration,
    String? teacherNotes,
    DateTime? endDate,
    List<InternshipEvaluationSkill>? skillEvaluations,
    List<InternshipEvaluationAttitude>? attitudeEvaluations,
    List<InternshipEvaluationVisa>? visaEvaluations,
    PostInternshipEnterpriseEvaluation? enterpriseEvaluation,
  }) {
    return Internship._(
      id: id ?? this.id,
      schoolBoardId: schoolBoardId ?? this.schoolBoardId,
      studentId: studentId ?? this.studentId,
      signatoryTeacherId: signatoryTeacherId ?? this.signatoryTeacherId,
      extraSupervisingTeacherIds:
          extraSupervisingTeacherIds ?? this.extraSupervisingTeacherIds,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      jobId: jobId ?? this.jobId,
      extraSpecializationIds:
          extraSpecializationIds ?? this.extraSpecializationIds,
      mutables: _mutables,
      expectedDuration: expectedDuration ?? this.expectedDuration,
      achievedDuration: achievedDuration ?? this.achievedDuration,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      endDate: endDate ?? this.endDate,
      skillEvaluations: skillEvaluations?.toList() ?? this.skillEvaluations,
      attitudeEvaluations:
          attitudeEvaluations?.toList() ?? this.attitudeEvaluations,
      visaEvaluations: visaEvaluations?.toList() ?? this.visaEvaluations,
      enterpriseEvaluation: enterpriseEvaluation ?? this.enterpriseEvaluation,
    );
  }

  @override
  Internship copyWithData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return copyWith();

    final availableFields = [
      'version',
      'id',
      'school_board_id',
      'student_id',
      'signatory_teacher_id',
      'extra_supervising_teacher_ids',
      'enterprise_id',
      'job_id',
      'extra_specialization_ids',
      'mutables',
      'expected_duration',
      'achieved_duration',
      'teacher_notes',
      'end_date',
      'skill_evaluations',
      'attitude_evaluations',
      'visa_evaluations',
      'enterprise_evaluation',
    ];
    // Make sure data does not contain unrecognized fields
    if (data.keys.any((key) => !availableFields.contains(key))) {
      throw InvalidFieldException('Invalid field data detected');
    }

    final version = data['version'];
    if (version == null) {
      throw InvalidFieldException('Version field is required');
    } else if (version != '1.0.0') {
      throw WrongVersionException(version, _currentVersion);
    }

    return Internship._(
      id: StringExt.from(data['id']) ?? id,
      schoolBoardId: StringExt.from(data['school_board_id']) ?? schoolBoardId,
      studentId: StringExt.from(data['student_id']) ?? studentId,
      signatoryTeacherId:
          StringExt.from(data['signatory_teacher_id']) ?? signatoryTeacherId,
      extraSupervisingTeacherIds: ListExt.from(
              data['extra_supervising_teacher_ids'],
              deserializer: (e) => StringExt.from(e)!) ??
          extraSupervisingTeacherIds,
      enterpriseId: StringExt.from(data['enterprise_id']) ?? enterpriseId,
      jobId: StringExt.from(data['job_id']) ?? jobId,
      extraSpecializationIds: ListExt.from(data['extra_specialization_ids'],
              deserializer: (e) => StringExt.from(e)!) ??
          extraSpecializationIds,
      mutables: ListExt.mergeWithData(_mutables, data['mutables'] as List?,
          copyWithData: (original, serialized) =>
              original.copyWithData(serialized),
          deserializer: (e) => InternshipMutableElements.fromSerialized(e)),
      expectedDuration:
          IntExt.from(data['expected_duration']) ?? expectedDuration,
      achievedDuration:
          IntExt.from(data['achieved_duration']) ?? achievedDuration,
      teacherNotes: StringExt.from(data['teacher_notes']) ?? teacherNotes,
      endDate: DateTimeExt.from(data['end_date']) ?? endDate,
      skillEvaluations: ListExt.from(data['skill_evaluations'],
              deserializer: (map) =>
                  InternshipEvaluationSkill.fromSerialized(map)) ??
          skillEvaluations,
      attitudeEvaluations: ListExt.from(data['attitude_evaluations'],
              deserializer: (map) =>
                  InternshipEvaluationAttitude.fromSerialized(map)) ??
          attitudeEvaluations,
      visaEvaluations: ListExt.from(data['visa_evaluations'],
              deserializer: (map) =>
                  InternshipEvaluationVisa.fromSerialized(map)) ??
          visaEvaluations,
      enterpriseEvaluation: data['enterprise_evaluation'] == null
          ? enterpriseEvaluation
          : PostInternshipEnterpriseEvaluation.fromSerialized(
              data['enterprise_evaluation']),
    );
  }

  @override
  String toString() {
    return 'Internship{studentId: $studentId, '
        'signatoryTeacherId: $signatoryTeacherId, '
        'extraSupervisingTeacherIds: $extraSupervisingTeacherIds, '
        'enterpriseId: $enterpriseId, '
        'jobId: $jobId, '
        'extraSpecializationIds: $extraSpecializationIds, '
        'mutables: $_mutables, '
        'expectedDuration: $expectedDuration days, '
        'achievedDuration: $achievedDuration, '
        'teacherNotes: $teacherNotes, '
        'endDate: $endDate, '
        'skillEvaluations: $skillEvaluations, '
        'attitudeEvaluations: $attitudeEvaluations, '
        'visaEvaluations: $visaEvaluations, '
        'enterpriseEvaluation: $enterpriseEvaluation'
        '}';
  }
}
