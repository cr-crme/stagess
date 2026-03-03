import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/internships/internship_evaluation.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/time_utils.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/person.dart';

class InternshipContract extends InternshipEvaluation {
  static const String currentVersion = '1.0.0';

  @override
  DateTime date;
  String formVersion;

  final Person supervisor;
  final DateTimeRange dates;
  final List<WeeklySchedule> weeklySchedules;
  final List<Transportation> transportations;
  final String visitFrequencies;

  InternshipContract({
    super.id,
    required this.date,
    required this.supervisor,
    required this.dates,
    required this.weeklySchedules,
    required this.transportations,
    required this.visitFrequencies,
    required this.formVersion,
  });
  InternshipContract.fromSerialized(super.map)
      : date = DateTimeExt.from(map?['creation_date']) ?? DateTime.now(),
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
        formVersion = map?['form_version'] ?? currentVersion,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'supervisor': supervisor.serialize(),
      'starting_date': dates.start.serialize(),
      'ending_date': dates.end.serialize(),
      'schedules': weeklySchedules.map((e) => e.serialize()).toList(),
      'transportations': transportations.map((e) => e.serialize()).toList(),
      'visit_frequencies': visitFrequencies.serialize(),
      'form_version': formVersion,
    };
  }

  InternshipContract copyWith({
    DateTime? date,
    Person? supervisor,
    DateTimeRange? dates,
    List<WeeklySchedule>? weeklySchedules,
    List<Transportation>? transportations,
    String? visitFrequencies,
    String? formVersion,
  }) {
    return InternshipContract(
      id: id,
      date: date ?? this.date,
      supervisor: supervisor ?? this.supervisor,
      dates: dates ?? this.dates,
      weeklySchedules: weeklySchedules ?? this.weeklySchedules,
      transportations: transportations ?? this.transportations,
      visitFrequencies: visitFrequencies ?? this.visitFrequencies,
      formVersion: formVersion ?? this.formVersion,
    );
  }

  InternshipContract copyWithData(Map? serialized) {
    if (serialized == null || serialized.isEmpty) return copyWith();

    return InternshipContract(
      id: id,
      date: DateTimeExt.from(serialized['creation_date']) ?? date,
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
      formVersion: serialized['form_version'] ?? formVersion,
    );
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'date': FetchableFields.optional,
        'supervisor': Person.fetchableFields,
        'starting_date': FetchableFields.mandatory,
        'ending_date': FetchableFields.mandatory,
        'schedules': WeeklySchedule.fetchableFields,
        'transportations': FetchableFields.optional,
        'visit_frequencies': FetchableFields.optional,
        'form_version': FetchableFields.optional,
      });

  @override
  String toString() {
    return 'InternshipManagingContract(date: $date, '
        'supervisor: ${supervisor.fullName}, '
        'dates: ${dates.start} - ${dates.end}, '
        'weeklySchedules: $weeklySchedules, '
        'transportations: $transportations, '
        'visitFrequencies: $visitFrequencies, '
        'form_version: $formVersion)';
  }
}
