import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/internships/time_utils.dart';
import 'package:stagess_common/utils.dart';

enum DayCycle {
  undefined,
  weekdaysCycle,
  nineDaysCycle,
  tenDaysCycle;

  int get dayCount {
    return switch (this) {
      DayCycle.undefined => 0,
      DayCycle.weekdaysCycle => 7,
      DayCycle.nineDaysCycle => 9,
      DayCycle.tenDaysCycle => 10,
    };
  }

  String get name {
    return switch (this) {
      DayCycle.undefined => 'Erreur interne',
      DayCycle.weekdaysCycle => 'Semaine de 7 jours',
      DayCycle.nineDaysCycle => 'Cycle de 9 jours',
      DayCycle.tenDaysCycle => 'Cycle de 10 jours',
    };
  }

  String dayAsString(int day) {
    switch (this) {
      case DayCycle.undefined:
        return 'Erreur interne';
      case DayCycle.weekdaysCycle:
        return switch (day) {
          0 => 'Lundi',
          1 => 'Mardi',
          2 => 'Mercredi',
          3 => 'Jeudi',
          4 => 'Vendredi',
          5 => 'Samedi',
          6 => 'Dimanche',
          _ => 'Jour $day',
        };
      case DayCycle.nineDaysCycle:
      case DayCycle.tenDaysCycle:
        return 'Jour ${day + 1}';
    }
  }

  int serialize() => index;

  static DayCycle fromSerialized(int index) => DayCycle.values[index];

  static DayCycle fromName(String name) =>
      DayCycle.values.firstWhere((cycle) => cycle.name == name);
}

class TimeBlock extends ItemSerializable {
  TimeBlock({
    super.id,
    required this.start,
    required this.end,
  });

  final TimeOfDay start;
  final TimeOfDay end;

  TimeBlock.fromSerialized(super.map)
      : start = TimeOfDay(hour: map?['start'][0], minute: map?['start'][1]),
        end = TimeOfDay(hour: map?['end'][0], minute: map?['end'][1]),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'start': [start.hour, start.minute],
        'end': [end.hour, end.minute],
      };

  TimeBlock copyWith({
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return TimeBlock(
      start: (start ?? this.start).copy(),
      end: (end ?? this.end).copy(),
    );
  }
}

class DailySchedule extends ItemSerializable {
  DailySchedule({super.id, required this.blocks});

  final List<TimeBlock> blocks;

  DailySchedule.fromSerialized(super.map)
      : blocks = ListExt.from(map?['blocks'] as List?,
                deserializer: (element) => TimeBlock.fromSerialized(element)) ??
            [],
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'blocks': blocks.map((block) => block.serialize()).toList(),
      };

  ///
  /// Similar to [copyWith], but enforce the change of id
  DailySchedule duplicate() => DailySchedule(
        blocks: blocks.map((block) => block.copyWith()).toList(),
      );

  DailySchedule copyWith({
    String? id,
    List<TimeBlock>? blocks,
  }) =>
      DailySchedule(
        id: id ?? this.id,
        blocks:
            (blocks ?? this.blocks).map((block) => block.copyWith()).toList(),
      );

  @override
  String toString() {
    return 'DailySchedule(id: $id, blocks: $blocks)';
  }
}

class WeeklySchedule extends ItemSerializable {
  WeeklySchedule({
    super.id,
    required this.period,
    required this.dayCycle,
    required this.schedule,
  }) {
    _finalizeInitialization();
  }

  final DateTimeRange period;
  final DayCycle dayCycle;
  final Map<int, DailySchedule?> schedule;

  void _finalizeInitialization() {
    // Remove schedules that are outside the day cycle range
    final daysToRemove =
        schedule.keys.where((day) => day >= dayCycle.dayCount).toList();
    for (final day in daysToRemove) {
      schedule.remove(day);
    }

    // Sort them so they appear in numerical order
    schedule.entries.toList().sort((pairA, pairB) {
      final dayA = pairA.key;
      final dayB = pairB.key;
      final a = pairA.value;
      final b = pairB.value;

      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;

      if (dayA < dayB) return -1;
      if (dayA > dayB) return 1;

      return 0;
    });
  }

  WeeklySchedule.fromSerialized(super.map)
      : period = DateTimeRange(
          start: DateTimeExt.from(map?['start']) ?? DateTime(0),
          end: DateTimeExt.from(map?['end']) ?? DateTime(0),
        ),
        dayCycle = map?['cycle'] == null
            ? DayCycle.undefined
            : DayCycle.fromSerialized(map!['cycle']),
        schedule = (map?['days'] as Map?)?.map((day, e) =>
                MapEntry(int.parse(day), DailySchedule.fromSerialized(e))) ??
            {},
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'start': period.start.serialize(),
        'end': period.end.serialize(),
        'cycle': dayCycle.serialize(),
        'days':
            schedule.map((day, e) => MapEntry(day.toString(), e?.serialize())),
      };

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'start': FetchableFields.optional,
        'end': FetchableFields.optional,
        'cycle': FetchableFields.optional,
        'days': FetchableFields.optional,
      });

  ///
  /// Similar to [copyWith], but enforce the change of id
  WeeklySchedule duplicate() => WeeklySchedule(
        period: period,
        dayCycle: dayCycle,
        schedule: schedule.map((day, e) => MapEntry(day, e?.duplicate())),
      );

  WeeklySchedule copyWith({
    String? id,
    DateTimeRange? period,
    DayCycle? dayCycle,
    Map<int, DailySchedule>? schedule,
  }) =>
      WeeklySchedule(
        id: id ?? this.id,
        period: period ?? this.period,
        dayCycle: dayCycle ?? this.dayCycle,
        schedule: schedule ?? this.schedule,
      );

  @override
  String toString() {
    return 'WeeklySchedule(id: $id, schedule: $schedule, period: $period)';
  }
}

class InternshipHelpers {
  static List<WeeklySchedule> copySchedules(
    List<WeeklySchedule>? schedules, {
    DayCycle? dayCycle,
    bool keepId = true,
  }) =>
      schedules
          ?.map(
            (schedule) => WeeklySchedule(
              id: keepId ? schedule.id : null,
              period: DateTimeRange(
                start: schedule.period.start,
                end: schedule.period.end,
              ),
              dayCycle: dayCycle ?? schedule.dayCycle,
              schedule: schedule.schedule.map(
                (day, entry) => MapEntry(
                  day,
                  entry == null
                      ? null
                      : DailySchedule(
                          id: keepId ? entry.id : null,
                          blocks: entry.blocks
                              .map((block) => block.copyWith())
                              .toList()),
                ),
              ),
            ),
          )
          .toList() ??
      [];

  static bool areSchedulesEqual(
    List<WeeklySchedule> listA,
    List<WeeklySchedule> listB,
  ) {
    if (listA.length != listB.length) return false;

    for (int i = 0; i < listA.length; i++) {
      if (!areWeeklySchedulesEqual(listA[i], listB[i])) return false;
    }
    return true;
  }

  static bool areWeeklySchedulesEqual(
      WeeklySchedule weeklyA, WeeklySchedule weeklyB) {
    if (weeklyA.period.start != weeklyB.period.start ||
        weeklyA.period.end != weeklyB.period.end) {
      return false;
    }

    if (weeklyA.schedule.length != weeklyB.schedule.length) return false;

    if (weeklyA.schedule.keys.length != weeklyB.schedule.keys.length) {
      return false;
    }
    if (weeklyA.schedule.keys
        .toSet()
        .difference(weeklyB.schedule.keys.toSet())
        .isNotEmpty) {
      return false;
    }

    final days = weeklyA.schedule.keys.toList();
    for (final day in days) {
      final dayA = weeklyA.schedule[day]!;
      final dayB = weeklyB.schedule[day]!;

      if (dayA.blocks.length != dayB.blocks.length) return false;
      if (areListsNotEqual(dayA.blocks, dayB.blocks, ignoreKeys: ['id'])) {
        return false;
      }
    }

    return true;
  }
}
