import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/internships/internship_evaluation.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/time_utils.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/student.dart';

class InternshipContract extends InternshipEvaluation {
  static const String currentVersion = '1.0.0';

  @override
  DateTime date;
  String formVersion;

  final DateTimeRange dates;
  final String jobId;
  final String specializationId;
  final List<String> extraSpecializationIds;
  final Program program;
  final Person supervisor;
  final List<WeeklySchedule> weeklySchedules;
  final List<String> transportations;
  final String visitFrequencies;
  final int expectedDuration;

  InternshipContract({
    super.id,
    required this.date,
    required this.jobId,
    required this.specializationId,
    required this.extraSpecializationIds,
    required this.program,
    required this.supervisor,
    required this.dates,
    required this.weeklySchedules,
    required this.transportations,
    required this.visitFrequencies,
    required this.expectedDuration,
    required this.formVersion,
  }) {
    _finalizeInitialization();
  }
  InternshipContract.fromSerialized(super.map)
      : date = DateTimeExt.from(map?['date']) ?? DateTime.now(),
        jobId = StringExt.from(map?['job_id']) ?? '',
        specializationId = StringExt.from(map?['specialization_id']) ?? '',
        extraSpecializationIds = ListExt.from(map?['extra_specialization_ids'],
                deserializer: (e) => StringExt.from(e)!) ??
            [],
        program = Program.fromSerialized(map?['program'] ?? {}, currentVersion),
        supervisor = Person.fromSerialized({
          'first_name': map?['supervisor_first_name'],
          'last_name': map?['supervisor_last_name'],
          'phone': {'phone_number': map?['supervisor_phone_number']},
          'email': map?['supervisor_email'],
        }),
        dates = DateTimeRange(
            start: DateTimeExt.from(map?['starting_date']) ?? DateTime(0),
            end: DateTimeExt.from(map?['ending_date']) ?? DateTime(0)),
        weeklySchedules = (map?['schedules'] as List?)
                ?.map((e) => WeeklySchedule.fromSerialized(e))
                .toList() ??
            [],
        transportations = ListExt.from(map?['transportations'],
                deserializer: (e) => StringExt.from(e)!) ??
            [],
        visitFrequencies = StringExt.from(map?['visit_frequencies']) ?? 'N/A',
        expectedDuration = map?['expected_duration'] ?? -1,
        formVersion = map?['form_version'] ?? currentVersion,
        super.fromSerialized() {
    _finalizeInitialization();
  }
  static InternshipContract get empty => InternshipContract(
        date: DateTime.now(),
        jobId: '',
        specializationId: '',
        extraSpecializationIds: [],
        program: Program.undefined,
        supervisor: Person.empty,
        dates: DateTimeRange(start: DateTime.now(), end: DateTime.now()),
        weeklySchedules: [],
        transportations: [],
        visitFrequencies: '',
        expectedDuration: -1,
        formVersion: currentVersion,
      );

  void _finalizeInitialization() {
    weeklySchedules.sort((a, b) {
      if (a.period.start.isBefore(b.period.start)) return -1;
      if (a.period.start.isAfter(b.period.start)) return 1;
      return 0;
    });
  }

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'date': date.serialize(),
      'job_id': jobId.serialize(),
      'specialization_id': specializationId.serialize(),
      'extra_specialization_ids': extraSpecializationIds.serialize(),
      'program': program.serialize(currentVersion),
      'supervisor_first_name': supervisor.firstName.serialize(),
      'supervisor_last_name': supervisor.lastName.serialize(),
      'supervisor_phone_number': supervisor.phone?.serialize()['phone_number'],
      'supervisor_email': supervisor.email?.serialize(),
      'starting_date': dates.start.serialize(),
      'ending_date': dates.end.serialize(),
      'schedules': weeklySchedules.map((e) => e.serialize()).toList(),
      'transportations': transportations.serialize(),
      'visit_frequencies': visitFrequencies.serialize(),
      'expected_duration': expectedDuration,
      'form_version': formVersion,
    };
  }

  InternshipContract copyWith({
    DateTime? date,
    String? jobId,
    String? specializationId,
    List<String>? extraSpecializationIds,
    Program? program,
    Person? supervisor,
    DateTimeRange? dates,
    List<WeeklySchedule>? weeklySchedules,
    List<String>? transportations,
    String? visitFrequencies,
    int? expectedDuration,
    String? formVersion,
  }) {
    return InternshipContract(
      id: id,
      date: date ?? this.date,
      jobId: jobId ?? this.jobId,
      specializationId: specializationId ?? this.specializationId,
      extraSpecializationIds:
          extraSpecializationIds ?? this.extraSpecializationIds,
      program: program ?? this.program,
      supervisor: supervisor ?? this.supervisor,
      dates: dates ?? this.dates,
      weeklySchedules: weeklySchedules ?? this.weeklySchedules,
      transportations: transportations ?? this.transportations,
      visitFrequencies: visitFrequencies ?? this.visitFrequencies,
      expectedDuration: expectedDuration ?? this.expectedDuration,
      formVersion: formVersion ?? this.formVersion,
    );
  }

  InternshipContract copyWithData(Map? serialized) {
    if (serialized == null || serialized.isEmpty) return copyWith();

    return InternshipContract(
      id: id,
      date: DateTimeExt.from(serialized['date']) ?? date,
      jobId: StringExt.from(serialized['job_id']) ?? jobId,
      specializationId:
          StringExt.from(serialized['specialization_id']) ?? specializationId,
      extraSpecializationIds: ListExt.from(
              serialized['extra_specialization_ids'],
              deserializer: (e) => StringExt.from(e)!) ??
          extraSpecializationIds,
      program: serialized['program'] == null
          ? Program.fromSerialized(serialized['program'] ?? {}, currentVersion)
          : program,
      supervisor: supervisor.copyWithData({
        'first_name': serialized['supervisor_first_name'],
        'last_name': serialized['supervisor_last_name'],
        'phone': serialized['supervisor_phone_number'],
        'email': serialized['supervisor_email'],
      }),
      dates: DateTimeRange(
        start: DateTimeExt.from(serialized['starting_date']) ?? dates.start,
        end: DateTimeExt.from(serialized['ending_date']) ?? dates.end,
      ),
      weeklySchedules: (serialized['schedules'] as List?)
              ?.map((e) => WeeklySchedule.fromSerialized(e))
              .toList() ??
          weeklySchedules,
      transportations: ListExt.from(serialized['transportations'],
              deserializer: (e) => StringExt.from(e)!) ??
          transportations,
      visitFrequencies:
          StringExt.from(serialized['visit_frequencies']) ?? visitFrequencies,
      expectedDuration:
          IntExt.from(serialized['expected_duration']) ?? expectedDuration,
      formVersion: serialized['form_version'] ?? formVersion,
    );
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'date': FetchableFields.optional,
        'specialization_id': FetchableFields.mandatory,
        'extra_specialization_ids': FetchableFields.mandatory,
        'program': FetchableFields.optional,
        'supervisor_first_name': FetchableFields.optional,
        'supervisor_last_name': FetchableFields.optional,
        'supervisor_phone_number': FetchableFields.optional,
        'supervisor_email': FetchableFields.optional,
        'starting_date': FetchableFields.optional,
        'ending_date': FetchableFields.optional,
        'schedules': WeeklySchedule.fetchableFields,
        'transportations': FetchableFields.optional,
        'visit_frequencies': FetchableFields.optional,
        'expected_duration': FetchableFields.optional,
        'form_version': FetchableFields.mandatory,
      });

  @override
  String toString() {
    return 'InternshipManagingContract(date: $date, '
        'jobId: $jobId, '
        'specializationId: $specializationId, '
        'extraSpecializationIds: $extraSpecializationIds, '
        'program: ${program.name}, '
        'supervisor: ${supervisor.fullName}, '
        'dates: ${dates.start} - ${dates.end}, '
        'weeklySchedules: $weeklySchedules, '
        'transportations: $transportations, '
        'visitFrequencies: $visitFrequencies, '
        'expectedDuration: $expectedDuration, '
        'form_version: $formVersion)';
  }
}
