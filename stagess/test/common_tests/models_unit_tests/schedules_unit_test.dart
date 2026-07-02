import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/time_utils.dart';

import '../utils.dart';

void main() {
  group('DailySchedule', () {
    test('DayCycle count', () {
      expect(DayCycle.values.length, 3);
    });

    test('"WeekdaysCycle" is the right label', () {
      final dayCycle = DayCycle.weekdaysCycle;

      expect(dayCycle.dayCount, 7);
      expect(dayCycle.dayAsString(0), 'Lundi');
      expect(dayCycle.dayAsString(1), 'Mardi');
      expect(dayCycle.dayAsString(2), 'Mercredi');
      expect(dayCycle.dayAsString(3), 'Jeudi');
      expect(dayCycle.dayAsString(4), 'Vendredi');
      expect(dayCycle.dayAsString(5), 'Samedi');
      expect(dayCycle.dayAsString(6), 'Dimanche');
    });

    test('"NineDaysCycle" is the right label', () {
      final dayCycle = DayCycle.nineDaysCycle;

      expect(dayCycle.dayCount, 9);
      expect(dayCycle.dayAsString(0), 'Jour 0');
      expect(dayCycle.dayAsString(1), 'Jour 1');
      expect(dayCycle.dayAsString(2), 'Jour 2');
      expect(dayCycle.dayAsString(3), 'Jour 3');
      expect(dayCycle.dayAsString(4), 'Jour 4');
      expect(dayCycle.dayAsString(5), 'Jour 5');
      expect(dayCycle.dayAsString(6), 'Jour 6');
      expect(dayCycle.dayAsString(7), 'Jour 7');
      expect(dayCycle.dayAsString(8), 'Jour 8');
    });

    test('"TenDaysCycle" is the right label', () {
      final dayCycle = DayCycle.tenDaysCycle;

      expect(dayCycle.dayCount, 10);
      expect(dayCycle.dayAsString(0), 'Jour 0');
      expect(dayCycle.dayAsString(1), 'Jour 1');
      expect(dayCycle.dayAsString(2), 'Jour 2');
      expect(dayCycle.dayAsString(3), 'Jour 3');
      expect(dayCycle.dayAsString(4), 'Jour 4');
      expect(dayCycle.dayAsString(5), 'Jour 5');
      expect(dayCycle.dayAsString(6), 'Jour 6');
      expect(dayCycle.dayAsString(7), 'Jour 7');
      expect(dayCycle.dayAsString(8), 'Jour 8');
      expect(dayCycle.dayAsString(9), 'Jour 9');
    });

    test('"copyWith" behaves properly', () {
      final dailySchedule = dummyDailySchedule();

      final dailyScheduleSame = dailySchedule.copyWith();
      expect(dailyScheduleSame.id, dailySchedule.id);
      expect(dailyScheduleSame.blocks.length, dailySchedule.blocks.length);
      expect(
        dailyScheduleSame.blocks.first.start.toString(),
        dailySchedule.blocks.first.start.toString(),
      );
      expect(
        dailyScheduleSame.blocks.first.end.toString(),
        dailySchedule.blocks.first.end.toString(),
      );

      final dailyScheduleDifferent = dailySchedule.copyWith(
        id: 'newId',
        blocks: [
          TimeBlock(
            start: const TimeOfDay(hour: 1, minute: 2),
            end: const TimeOfDay(hour: 3, minute: 4),
          ),
        ],
      );

      expect(dailyScheduleDifferent.id, 'newId');
      expect(
        dailyScheduleDifferent.blocks.first.start,
        const TimeOfDay(hour: 1, minute: 2),
      );
      expect(
        dailyScheduleDifferent.blocks.first.end,
        const TimeOfDay(hour: 3, minute: 4),
      );
    });

    test('serialization and deserialization works', () {
      final dailySchedule = dummyDailySchedule();
      final serialized = dailySchedule.serialize();
      final deserialized = DailySchedule.fromSerialized(serialized);

      expect(serialized, {
        'id': dailySchedule.id,
        'blocks': dailySchedule.blocks
            .map(
              (e) => {
                'id': e.id,
                'start': [e.start.hour, e.start.minute],
                'end': [e.end.hour, e.end.minute],
              },
            )
            .toList(),
      });

      expect(deserialized.id, dailySchedule.id);
      expect(deserialized.blocks.first.start, dailySchedule.blocks.first.start);
      expect(deserialized.blocks.first.end, dailySchedule.blocks.first.end);

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = DailySchedule.fromSerialized({'id': 'emptyId'});
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.blocks.length, 0);
    });
  });

  group('WeeklySchedule', () {
    test('"copyWith" behaves properly', () {
      final schedule = dummyWeeklySchedule();

      final scheduleSame = schedule.copyWith();
      expect(scheduleSame.id, schedule.id);
      for (final day in scheduleSame.schedule.keys) {
        expect(scheduleSame.schedule[day]!.id, schedule.schedule[day]!.id);
      }
      expect(scheduleSame.period.toString(), schedule.period.toString());

      final scheduleDifferent = schedule.copyWith(
        id: 'newId',
        schedule: {
          0: dummyDailySchedule(id: 'newDailyScheduleId'),
          1: dummyDailySchedule(id: 'newDailyScheduleId2'),
        },
        period: DateTimeRange(
          start: DateTime(2020, 2, 3),
          end: DateTime(2020, 2, 4),
        ),
      );

      expect(scheduleDifferent.id, 'newId');
      expect(scheduleDifferent.schedule.length, 2);
      expect(scheduleDifferent.schedule[0]!.id, 'newDailyScheduleId');
      expect(
        scheduleDifferent.schedule[1]!.id,
        'newDailyScheduleId2',
      );
      expect(scheduleDifferent.period.start, DateTime(2020, 2, 3));
      expect(scheduleDifferent.period.end, DateTime(2020, 2, 4));
    });

    test('serialization and deserialization works', () {
      final weeklySchedule = dummyWeeklySchedule();
      final serialized = weeklySchedule.serialize();
      final deserialized = WeeklySchedule.fromSerialized(serialized);

      expect(serialized, {
        'id': weeklySchedule.id,
        'days': weeklySchedule.schedule.map(
          (day, e) => MapEntry(day, e?.serialize()),
        ),
        'start': weeklySchedule.period.start.millisecondsSinceEpoch,
        'end': weeklySchedule.period.end.millisecondsSinceEpoch,
      });

      expect(deserialized.id, weeklySchedule.id);
      expect(deserialized.schedule.length, weeklySchedule.schedule.length);
      expect(deserialized.period, weeklySchedule.period);

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = WeeklySchedule.fromSerialized({
        'id': 'emptyId',
      });
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.schedule.length, 0);
      expect(
        emptyDeserialized.period,
        DateTimeRange(start: DateTime(0), end: DateTime(0)),
      );
    });
  });
}
