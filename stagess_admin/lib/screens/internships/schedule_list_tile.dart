import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';
import 'package:stagess_common_flutter/widgets/schedule_selector.dart';

class ScheduleListTile extends StatefulWidget {
  const ScheduleListTile({
    super.key,
    required this.scheduleController,
    required this.editMode,
  });

  final bool editMode;
  final WeeklySchedulesController scheduleController;

  @override
  State<ScheduleListTile> createState() => _ScheduleListTileState();
}

class _ScheduleListTileState extends State<ScheduleListTile> {
  final formKey = GlobalKey<FormState>();

  void onScheduleChanged() {
    if (widget.scheduleController.dateRange != null &&
        widget.scheduleController.weeklySchedules.isEmpty) {
      widget.scheduleController.addWeeklySchedule(
        WeeklySchedulesController.fillNewScheduleList(
          schedule: widget.scheduleController.weeklySchedules.isEmpty
              ? {}
              : widget.scheduleController.weeklySchedules.last.schedule,
          periode: widget.scheduleController.dateRange!,
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateRange(
            scheduleController: widget.scheduleController,
            onScheduleChanged: onScheduleChanged,
            editMode: widget.editMode,
          ),
          Visibility(
            visible: widget.scheduleController.dateRange != null,
            child: ScheduleSelector(
              title: const Text('Horaire du stage'),
              scheduleController: widget.scheduleController,
              editMode: widget.editMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRange extends StatefulWidget {
  const _DateRange({
    required this.scheduleController,
    required this.onScheduleChanged,
    required this.editMode,
  });

  final WeeklySchedulesController scheduleController;
  final Function() onScheduleChanged;
  final bool editMode;

  @override
  State<_DateRange> createState() => _DateRangeState();
}

class _DateRangeState extends State<_DateRange> {
  bool _isValid = true;

  late final _scheduleStartController = TextEditingController(
    text: widget.scheduleController.dateRange == null
        ? null
        : DateFormat.yMMMEd(
            'fr_CA',
          ).format(widget.scheduleController.dateRange!.start),
  );
  late final _scheduleEndController = TextEditingController(
    text: widget.scheduleController.dateRange == null
        ? null
        : DateFormat.yMMMEd(
            'fr_CA',
          ).format(widget.scheduleController.dateRange!.end),
  );

  Future<void> _promptDateRange(BuildContext context) async {
    final referenceDate =
        (widget.scheduleController.dateRange?.start ?? DateTime.now());
    final range = await showCustomDateRangePicker(
      helpText: 'Sélectionner les dates',
      saveText: 'Confirmer',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      context: context,
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDateRange: widget.scheduleController.dateRange,
      firstDate: DateTime(referenceDate.year - 1),
      lastDate: DateTime(referenceDate.year + 2),
    );
    if (range == null) return;

    _isValid = true;
    widget.scheduleController.dateRange = range;
    _scheduleStartController.text = DateFormat.yMMMEd(
      'fr_CA',
    ).format(range.start);
    _scheduleEndController.text = DateFormat.yMMMEd('fr_CA').format(range.end);

    widget.onScheduleChanged();
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant _DateRange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editMode) return;

    final startDate = (widget.scheduleController.dateRange == null
            ? null
            : DateFormat.yMMMEd(
                'fr_CA',
              ).format(widget.scheduleController.dateRange!.start)) ??
        '';
    if (_scheduleStartController.text != startDate) {
      _scheduleStartController.text = startDate;
    }

    final endDate = (widget.scheduleController.dateRange == null
            ? null
            : DateFormat.yMMMEd(
                'fr_CA',
              ).format(widget.scheduleController.dateRange!.end)) ??
        '';
    if (_scheduleEndController.text != endDate) {
      _scheduleEndController.text = endDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dates de stage'),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.editMode)
                Row(
                  children: [
                    FormField<void>(
                      validator: (value) {
                        if (widget.scheduleController.dateRange == null) {
                          _isValid = false;
                          setState(() {});
                          return 'Nope';
                        } else {
                          _isValid = true;
                          setState(() {});
                          return null;
                        }
                      },
                      builder: (state) => Text(
                        '* Sélectionner les dates',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall!.copyWith(
                              color: _isValid ? Colors.black : Colors.red,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.blue,
                      ),
                      onPressed: () async {
                        await _promptDateRange(context);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              Visibility(
                visible: widget.scheduleController.dateRange != null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Date de début',
                          labelStyle: TextStyle(color: Colors.black),
                          border: InputBorder.none,
                        ),
                        controller: _scheduleStartController,
                        style: TextStyle(color: Colors.black),
                        enabled: false,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Date de fin',
                          labelStyle: TextStyle(color: Colors.black),
                          border: InputBorder.none,
                        ),
                        controller: _scheduleEndController,
                        style: TextStyle(color: Colors.black),
                        enabled: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
