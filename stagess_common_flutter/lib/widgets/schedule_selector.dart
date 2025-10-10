import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/time_utils.dart'
    as time_utils;
import 'package:stagess_common_flutter/helpers/time_of_day_extension.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';
import 'package:stagess_common_flutter/widgets/custom_time_picker.dart';

final _logger = Logger('ScheduleSelector');

final _defaultDaily = DailySchedule(
  blocks: [
    TimeBlock(
      start: time_utils.TimeOfDay(hour: 9, minute: 0),
      end: time_utils.TimeOfDay(hour: 12, minute: 0),
    ),
    TimeBlock(
      start: time_utils.TimeOfDay(hour: 13, minute: 0),
      end: time_utils.TimeOfDay(hour: 15, minute: 0),
    ),
  ],
);

class WeeklySchedulesController {
  var _currentDefaultDaily = _defaultDaily.duplicate();

  final List<bool> _useSameScheduleForAllDays = [];
  final List<WeeklySchedule> _weeklySchedules;
  List<WeeklySchedule> get weeklySchedules => _weeklySchedules;
  set weeklySchedules(List<WeeklySchedule> newSchedules) {
    _weeklySchedules
      ..clear()
      ..addAll(newSchedules);
    _resetUseSameScheduleForAllDays();
    _hasChanged = true;
  }

  time_utils.DateTimeRange? _dateRange;
  time_utils.DateTimeRange? get dateRange => _dateRange;
  bool _hasChanged = false;

  WeeklySchedulesController({
    List<WeeklySchedule>? weeklySchedules,
    time_utils.DateTimeRange? dateRange,
  }) : _dateRange = dateRange?.copy(),
       _weeklySchedules = InternshipHelpers.copySchedules(
         weeklySchedules,
         keepId: true,
       ) {
    for (var _ in weeklySchedules ?? []) {
      _useSameScheduleForAllDays.add(false);
    }
  }

  bool get hasChanged => _hasChanged;
  set dateRange(time_utils.DateTimeRange? newRange) {
    _dateRange = newRange;
    if (_weeklySchedules.length == 1) {
      _weeklySchedules[0] = _weeklySchedules[0].copyWith(period: newRange);
    }
    _hasChanged = true;
  }

  void addWeeklySchedule(WeeklySchedule newSchedule) {
    _logger.finer('Adding new weekly schedule: ${newSchedule.id}');

    _weeklySchedules.add(newSchedule);
    _useSameScheduleForAllDays.add(
      _useSameScheduleForAllDays.isEmpty
          ? true
          : _useSameScheduleForAllDays.last,
    );
    _hasChanged = true;
  }

  void removedWeeklySchedule(int weeklyIndex) {
    _logger.finer('Removing weekly schedule at index: $weeklyIndex');

    _weeklySchedules.removeAt(weeklyIndex);
    _useSameScheduleForAllDays.removeAt(weeklyIndex);
    _hasChanged = true;
  }

  void updateDailyScheduleTime(
    int weeklyIndex,
    Day day, {
    required DailySchedule schedule,
  }) {
    _logger.finer(
      'Updating daily schedule (weekly index: $weeklyIndex, day: $day)',
    );
    _weeklySchedules[weeklyIndex].schedule[day] =
        _weeklySchedules[weeklyIndex].schedule[day]?.copyWith(
          blocks: schedule.blocks,
        ) ??
        schedule;

    if (_useSameScheduleForAllDays[weeklyIndex]) {
      applySameScheduleForAllDays(weeklyIndex);
    }
    _hasChanged = true;
  }

  void removeDailyScheduleTime(int weeklyIndex, Day day) {
    _logger.finer(
      'Updating daily schedule (weekly index: $weeklyIndex, day: $day)',
    );
    _weeklySchedules[weeklyIndex].schedule.remove(day);

    if (_useSameScheduleForAllDays[weeklyIndex]) {
      applySameScheduleForAllDays(weeklyIndex);
    }
    _hasChanged = true;
  }

  void updateDailyScheduleRange(
    int weeklyIndex,
    time_utils.DateTimeRange newRange,
  ) {
    _logger.finer(
      'Updating date range for weekly schedule at index: $weeklyIndex',
    );
    _weeklySchedules[weeklyIndex] = _weeklySchedules[weeklyIndex].copyWith(
      period: newRange,
    );

    if (_useSameScheduleForAllDays[weeklyIndex]) {
      applySameScheduleForAllDays(weeklyIndex);
    }

    _hasChanged = true;
  }

  void _resetUseSameScheduleForAllDays() {
    _useSameScheduleForAllDays.clear();
    for (var _ in _weeklySchedules) {
      _useSameScheduleForAllDays.add(false);
    }
  }

  void switchApplyToAllDays({required bool value, required int weeklyIndex}) {
    _useSameScheduleForAllDays[weeklyIndex] = value;
    if (_useSameScheduleForAllDays[weeklyIndex]) {
      applySameScheduleForAllDays(weeklyIndex);
    }
    _hasChanged = true;
  }

  void applySameScheduleForAllDays(int weeklyIndex) {
    final schedules = _weeklySchedules[weeklyIndex].schedule;
    if (schedules.isEmpty) return;

    // Reference day is the first day with a schedule
    final referenceDay = Day.values.firstWhereOrNull(
      (day) => schedules[day] != null,
    );
    if (referenceDay == null) return;

    schedules.forEach((day, schedule) {
      if (day != referenceDay) {
        schedules[day] = schedules[referenceDay]?.duplicate();
      }
    });
    _hasChanged = true;
  }

  static WeeklySchedule fillNewScheduleList({
    required Map<Day, DailySchedule?> schedule,
    required time_utils.DateTimeRange periode,
  }) {
    return WeeklySchedule(
      schedule: {
        for (var key in schedule.keys) key: schedule[key]?.duplicate(),
      },
      period: periode,
    );
  }

  void dispose() {
    _logger.finer('Disposing WeeklySchedulesController');
    _weeklySchedules.clear();
    _useSameScheduleForAllDays.clear();
    _dateRange = null;
    _hasChanged = false;
  }
}

class ScheduleSelector extends StatefulWidget {
  const ScheduleSelector({
    super.key,
    this.title,
    required this.scheduleController,
    required this.editMode,
    this.leftPadding,
    this.periodTextSize,
  });

  final WeeklySchedulesController scheduleController;
  final bool editMode;
  final Widget? title;
  final double? leftPadding;
  final double? periodTextSize;

  @override
  State<ScheduleSelector> createState() => _ScheduleSelectorState();
}

class _ScheduleSelectorState extends State<ScheduleSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) widget.title!,
        ...widget.scheduleController._weeklySchedules.asMap().keys.map<Widget>(
          (weekIndex) => _ScheduleSelector(
            key: ValueKey(
              widget.scheduleController._weeklySchedules[weekIndex].hashCode,
            ),
            controller: widget.scheduleController,
            weekIndex: weekIndex,
            periodName:
                widget.scheduleController._weeklySchedules.length > 1
                    ? 'Période ${weekIndex + 1}'
                    : null,
            periodTextSize: widget.periodTextSize,
            onShouldRefresh: () => setState(() {}),
            editMode: widget.editMode,
            leftPadding: widget.leftPadding,
          ),
        ),
        if (widget.editMode)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: TextButton(
              onPressed:
                  () => setState(() {
                    widget.scheduleController.addWeeklySchedule(
                      WeeklySchedulesController.fillNewScheduleList(
                        schedule:
                            widget.scheduleController._weeklySchedules.isEmpty
                                ? {}
                                : widget
                                    .scheduleController
                                    ._weeklySchedules
                                    .last
                                    .schedule,
                        periode: widget.scheduleController.dateRange!,
                      ),
                    );
                  }),
              style: Theme.of(context).textButtonTheme.style?.copyWith(
                backgroundColor:
                    Theme.of(
                      context,
                    ).elevatedButtonTheme.style!.backgroundColor,
              ),
              child: const Text('Ajouter une période'),
            ),
          ),
      ],
    );
  }
}

class _ScheduleSelector extends StatelessWidget {
  const _ScheduleSelector({
    super.key,
    required this.periodName,
    required this.periodTextSize,
    required this.controller,
    required this.weekIndex,
    required this.onShouldRefresh,
    required this.editMode,
    this.leftPadding,
  });

  final double? leftPadding;
  final String? periodName;
  final double? periodTextSize;
  final WeeklySchedulesController controller;
  final int weekIndex;
  final Function() onShouldRefresh;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    final weeklySchedule = controller._weeklySchedules[weekIndex];
    final useSameScheduleForAllDays =
        controller._useSameScheduleForAllDays[weekIndex];
    int? referenceDayIndex; // Used to determine if it's the first checked day

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (periodName != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: 8.0,
                  bottom: 4.0,
                  left: leftPadding ?? 12,
                ),
                child: Text(
                  periodName!,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: periodTextSize,
                  ),
                ),
              ),
              if (editMode)
                IconButton(
                  onPressed: () {
                    if (controller._weeklySchedules.length > 1) {
                      controller.removedWeeklySchedule(weekIndex);
                    }
                    onShouldRefresh();
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
            ],
          ),
        if (editMode)
          if (periodName == null)
            Text(
              '* Sélectionner les journées et heures du stage',
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
            )
          else
            Text(
              '* Sélectionner les dates, journées et heures de la période de stage',
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
        if (periodName != null)
          Padding(
            padding: EdgeInsets.only(
              top: 8.0,
              left: 8.0,
              right: editMode ? 8.0 : 24.0,
              bottom: leftPadding ?? 12,
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text('${editMode ? '* ' : ''}Date de début'),
                        Text(
                          DateFormat.yMMMEd(
                            'fr_CA',
                          ).format(weeklySchedule.period.start),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text('${editMode ? '* ' : ''}Date de fin'),
                        Text(
                          DateFormat.yMMMEd(
                            'fr_CA',
                          ).format(weeklySchedule.period.end),
                        ),
                      ],
                    ),
                  ],
                ),
                if (editMode)
                  IconButton(
                    icon: const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      _promptChangeWeek(context);
                      onShouldRefresh();
                    },
                  ),
              ],
            ),
          ),
        if (editMode)
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Appliquer le même horaire pour tous les jours du stage',
                  ),
                ),
                Switch(
                  value: useSameScheduleForAllDays,
                  onChanged: (value) {
                    controller.switchApplyToAllDays(
                      value: value,
                      weeklyIndex: weekIndex,
                    );
                    onShouldRefresh();
                  },
                ),
              ],
            ),
          ),
        FormField(
          validator: (value) {
            if (!editMode) return null;
            if (weeklySchedule.schedule.isEmpty) {
              return 'Sélectionner au moins un jour.';
            }
            return null;
          },
          builder: (state) {
            return Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                    child: Column(
                      children: [
                        ...Day.values.asMap().keys.map(
                          (dayIndex) => FormField(
                            validator: (value) {
                              final day = Day.values[dayIndex];
                              final schedule = weeklySchedule.schedule[day];
                              for (final block
                                  in schedule?.blocks ?? <TimeBlock>[]) {
                                if (block.end.isBefore(block.start)) {
                                  return 'La fin du bloc horaire ne peut pas être avant le début.';
                                }
                              }
                              return null;
                            },
                            builder: (state) {
                              final day = Day.values[dayIndex];

                              bool isEnabled = true;
                              if (useSameScheduleForAllDays &&
                                  weeklySchedule.schedule[day] != null) {
                                if (referenceDayIndex == null) {
                                  referenceDayIndex = dayIndex;
                                } else {
                                  isEnabled = false;
                                }
                              }

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildDailyScheduleTile(
                                    context,
                                    day: day,
                                    canChangeTime: isEnabled,
                                  ),
                                  if (state.hasError && isEnabled)
                                    Center(
                                      child: Text(
                                        state.errorText ?? '',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.hasError)
                    Center(
                      child: Text(
                        state.errorText ?? '',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _promptChangeWeek(BuildContext context) async {
    final period = controller._weeklySchedules[weekIndex].period;
    final range = await showCustomDateRangePicker(
      helpText: 'Sélectionner les dates',
      saveText: 'Confirmer',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      context: context,
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDateRange: period,
      firstDate: DateTime(period.start.year - 1),
      lastDate: DateTime(period.start.year + 2),
    );
    if (range == null) return;

    controller.updateDailyScheduleRange(weekIndex, range);
    onShouldRefresh();
  }

  Future<time_utils.TimeOfDay?> _promptTime(
    BuildContext context, {
    required time_utils.TimeOfDay? initial,
    String? title,
  }) async {
    final time = await showCustomTimePicker(
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      helpText: title,
      context: context,
      initialTime: TimeOfDay(
        hour: initial?.hour ?? 12,
        minute: initial?.minute ?? 0,
      ),
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child ?? Container(),
          ),
    );

    if (time == null) return null;
    return time_utils.TimeOfDay(hour: time.hour, minute: time.minute);
  }

  void _updateBlockStart(
    BuildContext context, {
    required DailySchedule schedule,
    required int blockIndex,
    required Day day,
  }) async {
    final time = await _promptTime(
      context,
      initial: schedule.blocks[blockIndex].start,
    );
    if (time == null) return;
    schedule.blocks[blockIndex] = schedule.blocks[blockIndex].copyWith(
      start: time,
    );

    // Use this update as the reference for the next updates
    controller._currentDefaultDaily = schedule.duplicate();
    controller.updateDailyScheduleTime(weekIndex, day, schedule: schedule);
    onShouldRefresh();
  }

  void _updateBlockEnd(
    BuildContext context, {
    required DailySchedule schedule,
    required int blockIndex,
    required Day day,
  }) async {
    final time = await _promptTime(
      context,
      initial: schedule.blocks[blockIndex].end,
    );
    if (time == null) return;
    schedule.blocks[blockIndex] = schedule.blocks[blockIndex].copyWith(
      end: time,
    );

    // Use this update as the reference for the next updates
    controller._currentDefaultDaily = schedule.duplicate();
    controller.updateDailyScheduleTime(weekIndex, day, schedule: schedule);
    onShouldRefresh();
  }

  Widget _buildDailyScheduleTile(
    BuildContext context, {
    required Day day,
    required bool canChangeTime,
  }) {
    final schedule = controller._weeklySchedules[weekIndex].schedule[day];
    final checkboxCallback =
        editMode
            ? () {
              if (schedule == null) {
                controller.updateDailyScheduleTime(
                  weekIndex,
                  day,
                  schedule: controller._currentDefaultDaily.duplicate(),
                );
              } else {
                controller.removeDailyScheduleTime(weekIndex, day);
              }
              onShouldRefresh();
            }
            : null;
    if (!editMode && schedule == null) {
      return SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: checkboxCallback,
          child: SizedBox(
            width: 150,
            child: Row(
              children: [
                Visibility(
                  visible: editMode,
                  maintainAnimation: true,
                  maintainState: true,
                  maintainSize: true,
                  child: Checkbox(
                    value: schedule != null,
                    onChanged: (_) {
                      if (checkboxCallback != null) {
                        checkboxCallback();
                      }
                    },
                  ),
                ),
                Text(day.name),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
            child: Column(
              children:
                  (schedule?.blocks ?? []).asMap().keys.map((i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ClickableTextField(
                            enabled: editMode,
                            schedule!.blocks[i].start.format(context),
                            onTap:
                                canChangeTime
                                    ? () => _updateBlockStart(
                                      context,
                                      schedule: schedule,
                                      blockIndex: i,
                                      day: day,
                                    )
                                    : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text('à'),
                          ),
                          _ClickableTextField(
                            enabled: editMode,
                            schedule.blocks[i].end.format(context),
                            onTap:
                                canChangeTime
                                    ? () => _updateBlockEnd(
                                      context,
                                      schedule: schedule,
                                      blockIndex: i,
                                      day: day,
                                    )
                                    : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child:
                                editMode
                                    ? (i == 0
                                        ? Visibility(
                                          visible: schedule.blocks.length == 1,
                                          maintainAnimation: true,
                                          maintainState: true,
                                          maintainSize: true,
                                          child: _TimeBlockIconButton(
                                            onTap:
                                                canChangeTime
                                                    ? () {
                                                      schedule.blocks.add(
                                                        controller
                                                                    ._currentDefaultDaily
                                                                    .blocks
                                                                    .length >
                                                                1
                                                            ? controller
                                                                ._currentDefaultDaily
                                                                .blocks[1]
                                                            : _defaultDaily
                                                                .blocks[1],
                                                      );
                                                      controller
                                                              ._currentDefaultDaily =
                                                          schedule.duplicate();
                                                      controller
                                                          .updateDailyScheduleTime(
                                                            weekIndex,
                                                            day,
                                                            schedule: schedule,
                                                          );
                                                      onShouldRefresh();
                                                    }
                                                    : null,
                                            icon: Icon(
                                              Icons.add,
                                              color:
                                                  canChangeTime
                                                      ? Colors.green
                                                      : Colors.grey,
                                            ),
                                          ),
                                        )
                                        : _TimeBlockIconButton(
                                          onTap:
                                              canChangeTime
                                                  ? () {
                                                    schedule.blocks.removeAt(i);
                                                    controller
                                                            ._currentDefaultDaily =
                                                        schedule.duplicate();
                                                    controller
                                                        .updateDailyScheduleTime(
                                                          weekIndex,
                                                          day,
                                                          schedule: schedule,
                                                        );
                                                    onShouldRefresh();
                                                  }
                                                  : null,
                                          icon: Icon(
                                            Icons.remove,
                                            color:
                                                canChangeTime
                                                    ? Colors.red
                                                    : Colors.grey,
                                          ),
                                        ))
                                    : Container(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        Container(),
      ],
    );
  }
}

class _TimeBlockIconButton extends StatelessWidget {
  const _TimeBlockIconButton({required this.onTap, required this.icon});

  final Function()? onTap;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: InkWell(
        borderRadius: BorderRadius.circular(25.0),
        hoverColor: icon.color?.withAlpha(10),
        splashColor: icon.color?.withAlpha(30),
        onTap: onTap,
        child: icon,
      ),
    );
  }
}

class _ClickableTextField extends StatefulWidget {
  const _ClickableTextField(
    this.text, {
    required this.onTap,
    required this.enabled,
  });

  final String text;
  final bool enabled;
  final Function()? onTap;

  @override
  State<_ClickableTextField> createState() => _ClickableTextFieldState();
}

class _ClickableTextFieldState extends State<_ClickableTextField> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return widget.enabled
        ? InkWell(
          onTap: widget.onTap,
          onHover: (hovering) {
            setState(() {
              _isHovering = hovering;
            });
          },
          child: Container(
            width: 66,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(4.0),
              color:
                  _isHovering
                      ? Colors.grey[200]
                      : (widget.onTap == null
                          ? Colors.grey[200]
                          : Colors.white),
            ),
            child: Center(child: Text(widget.text)),
          ),
        )
        : SizedBox(width: 50, child: Center(child: Text(widget.text)));
  }
}
