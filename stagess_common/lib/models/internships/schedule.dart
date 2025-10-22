import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/internships/time_utils.dart';
import 'package:stagess_common/utils.dart';

enum Day {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get name {
    switch (this) {
      case (Day.monday):
        return 'Lundi';
      case (Day.tuesday):
        return 'Mardi';
      case (Day.wednesday):
        return 'Mercredi';
      case (Day.thursday):
        return 'Jeudi';
      case (Day.friday):
        return 'Vendredi';
      case (Day.saturday):
        return 'Samedi';
      case (Day.sunday):
        return 'Dimanche';
    }
  }

  static fromName(String name) {
    return Day.values.firstWhere(
      (element) => element.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Day.monday,
    );
  }

  @override
  String toString() => name;
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
    required this.schedule,
    required this.period,
  });

  final Map<Day, DailySchedule?> schedule;
  final DateTimeRange period;

  WeeklySchedule.fromSerialized(super.map)
      : schedule = (map?['days'] as Map?)?.map((day, e) => MapEntry(
                Day.values[int.parse(day)], DailySchedule.fromSerialized(e))) ??
            {},
        period = DateTimeRange(
            start: DateTime.fromMillisecondsSinceEpoch(map?['start'] ?? 0),
            end: DateTime.fromMillisecondsSinceEpoch(map?['end'] ?? 0)),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'days': schedule
            .map((day, e) => MapEntry(day.index.toString(), e?.serialize())),
        'start': period.start.millisecondsSinceEpoch,
        'end': period.end.millisecondsSinceEpoch,
      };

  ///
  /// Similar to [copyWith], but enforce the change of id
  WeeklySchedule duplicate() => WeeklySchedule(
        schedule: schedule.map((day, e) => MapEntry(day, e?.duplicate())),
        period: period,
      );

  WeeklySchedule copyWith({
    String? id,
    Map<Day, DailySchedule>? schedule,
    DateTimeRange? period,
  }) =>
      WeeklySchedule(
        id: id ?? this.id,
        schedule: schedule ?? this.schedule,
        period: period ?? this.period,
      );

  @override
  String toString() {
    return 'WeeklySchedule(id: $id, schedule: $schedule, period: $period)';
  }
}

class InternshipHelpers {
  static List<WeeklySchedule> copySchedules(
    List<WeeklySchedule>? schedules, {
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
      if (areListsNotEqual(dayA.blocks, dayB.blocks)) return false;
    }

    return true;
  }
}
