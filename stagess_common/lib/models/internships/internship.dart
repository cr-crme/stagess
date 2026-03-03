import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/extended_item_serializable.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/internships/internship_contract.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/internships/internship_evaluation_visa.dart';
import 'package:stagess_common/models/internships/post_internship_enterprise_evaluation.dart';
import 'package:stagess_common/models/internships/sst_evaluation.dart';

export 'package:stagess_common/models/generic/serializable_elements.dart';

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

  // Elements that are parts of the inner working of the internship (can be
  // modify, but won't generate a new version)
  final int achievedDuration;
  final String teacherNotes;
  final DateTime endDate;

  bool get hasContract => contracts.isNotEmpty;
  InternshipContract? get currentContract =>
      hasContract ? contracts.last : null;
  final List<InternshipContract> contracts;
  final List<InternshipEvaluationSkill> skillEvaluations;
  final List<InternshipEvaluationAttitude> attitudeEvaluations;
  final List<InternshipEvaluationVisa> visaEvaluations;
  final List<SstEvaluation> sstEvaluations;
  final List<PostInternshipEnterpriseEvaluation> enterpriseEvaluations;

  bool get isClosed => isNotActive && !isEnterpriseEvaluationPending;
  bool get isEnterpriseEvaluationPending =>
      isNotActive && enterpriseEvaluations.isEmpty;
  bool get isActive => hasContract && endDate == DateTime(0);
  bool get isNotActive => !isActive;
  bool get shouldTerminate =>
      isActive &&
      currentContract!.dates.end.difference(DateTime.now()).inDays <= -1;

  void _finalizeInitialization() {
    extraSupervisingTeacherIds.remove(signatoryTeacherId);

    contracts.sort((a, b) => a.date.compareTo(b.date));
    skillEvaluations.sort((a, b) => a.date.compareTo(b.date));
    attitudeEvaluations.sort((a, b) => a.date.compareTo(b.date));
    visaEvaluations.sort((a, b) => a.date.compareTo(b.date));
    sstEvaluations.sort((a, b) => a.date.compareTo(b.date));
    enterpriseEvaluations.sort((a, b) => a.date.compareTo(b.date));
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
    required this.expectedDuration,
    required this.achievedDuration,
    required this.teacherNotes,
    required this.endDate,
    required this.contracts,
    required this.skillEvaluations,
    required this.attitudeEvaluations,
    required this.visaEvaluations,
    required this.sstEvaluations,
    required this.enterpriseEvaluations,
  }) {
    _finalizeInitialization();
  }

  static Internship get empty => Internship(
        schoolBoardId: '-1',
        studentId: '',
        signatoryTeacherId: '',
        extraSupervisingTeacherIds: [],
        enterpriseId: '',
        jobId: '',
        extraSpecializationIds: [],
        expectedDuration: -1,
        achievedDuration: -1,
        teacherNotes: '',
        endDate: DateTime(0),
        contracts: [],
        skillEvaluations: [],
        attitudeEvaluations: [],
        visaEvaluations: [],
        sstEvaluations: [],
        enterpriseEvaluations: [],
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
        expectedDuration = IntExt.from(map?['expected_duration']) ?? -1,
        achievedDuration = IntExt.from(map?['achieved_duration']) ?? -1,
        teacherNotes = StringExt.from(map?['teacher_notes']) ?? '',
        endDate = DateTimeExt.from(map?['end_date']) ?? DateTime(0),
        contracts = ListExt.from(map?['contracts'] as List?,
                deserializer: (e) => InternshipContract.fromSerialized(e)) ??
            [],
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
        sstEvaluations = ListExt.from(map?['sst_evaluations'],
                deserializer: (map) => SstEvaluation.fromSerialized(map)) ??
            [],
        enterpriseEvaluations = ListExt.from(map?['enterprise_evaluations'],
                deserializer: (map) =>
                    PostInternshipEnterpriseEvaluation.fromSerialized(map)) ??
            [],
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
        'expected_duration': expectedDuration.serialize(),
        'achieved_duration': achievedDuration.serialize(),
        'teacher_notes': teacherNotes.serialize(),
        'end_date': endDate.serialize(),
        'contracts': contracts.serialize(),
        'skill_evaluations': skillEvaluations.serialize(),
        'attitude_evaluations': attitudeEvaluations.serialize(),
        'visa_evaluations': visaEvaluations.serialize(),
        'sst_evaluations': sstEvaluations.serialize(),
        'enterprise_evaluations': enterpriseEvaluations.serialize(),
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
        'contracts': InternshipContract.fetchableFields,
        'expected_duration': FetchableFields.optional,
        'achieved_duration': FetchableFields.optional,
        'teacher_notes': FetchableFields.optional,
        'end_date': FetchableFields.mandatory,
        'skill_evaluations': InternshipEvaluationSkill.fetchableFields,
        'attitude_evaluations': InternshipEvaluationAttitude.fetchableFields,
        'visa_evaluations': InternshipEvaluationVisa.fetchableFields,
        'sst_evaluations': SstEvaluation.fetchableFields,
        'enterprise_evaluations':
            PostInternshipEnterpriseEvaluation.fetchableFields,
      });

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
    List<InternshipContract>? contracts,
    List<InternshipEvaluationSkill>? skillEvaluations,
    List<InternshipEvaluationAttitude>? attitudeEvaluations,
    List<InternshipEvaluationVisa>? visaEvaluations,
    List<SstEvaluation>? sstEvaluations,
    List<PostInternshipEnterpriseEvaluation>? enterpriseEvaluations,
  }) {
    return Internship(
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
      expectedDuration: expectedDuration ?? this.expectedDuration,
      achievedDuration: achievedDuration ?? this.achievedDuration,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      endDate: endDate ?? this.endDate,
      contracts: contracts?.toList() ?? this.contracts,
      skillEvaluations: skillEvaluations?.toList() ?? this.skillEvaluations,
      attitudeEvaluations:
          attitudeEvaluations?.toList() ?? this.attitudeEvaluations,
      visaEvaluations: visaEvaluations?.toList() ?? this.visaEvaluations,
      sstEvaluations: sstEvaluations ?? this.sstEvaluations,
      enterpriseEvaluations:
          enterpriseEvaluations ?? this.enterpriseEvaluations,
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
      'expected_duration',
      'achieved_duration',
      'teacher_notes',
      'end_date',
      'contracts',
      'skill_evaluations',
      'attitude_evaluations',
      'visa_evaluations',
      'sst_evaluations',
      'enterprise_evaluations',
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

    return Internship(
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
      expectedDuration:
          IntExt.from(data['expected_duration']) ?? expectedDuration,
      achievedDuration:
          IntExt.from(data['achieved_duration']) ?? achievedDuration,
      teacherNotes: StringExt.from(data['teacher_notes']) ?? teacherNotes,
      endDate: DateTimeExt.from(data['end_date']) ?? endDate,
      contracts: ListExt.from(data['contracts'],
              deserializer: (map) => InternshipContract.fromSerialized(map)) ??
          contracts,
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
      sstEvaluations: ListExt.from(data['sst_evaluations'],
              deserializer: (map) => SstEvaluation.fromSerialized(map)) ??
          sstEvaluations,
      enterpriseEvaluations: ListExt.from(data['enterprise_evaluations'],
              deserializer: (map) =>
                  PostInternshipEnterpriseEvaluation.fromSerialized(map)) ??
          enterpriseEvaluations,
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
        'expectedDuration: $expectedDuration days, '
        'achievedDuration: $achievedDuration, '
        'teacherNotes: $teacherNotes, '
        'endDate: $endDate, '
        'contracts: $contracts, '
        'skillEvaluations: $skillEvaluations, '
        'attitudeEvaluations: $attitudeEvaluations, '
        'visaEvaluations: $visaEvaluations, '
        'sstEvaluations: $sstEvaluations, '
        'enterpriseEvaluations: $enterpriseEvaluations'
        '}';
  }
}
