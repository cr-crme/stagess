import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';
import 'package:stagess_common_flutter/widgets/schedule_selector.dart';

final _logger = Logger('ScheduleStep');

class ScheduleStep extends StatefulWidget {
  const ScheduleStep({super.key});

  @override
  State<ScheduleStep> createState() => ScheduleStepState();
}

class ScheduleStepState extends State<ScheduleStep> {
  final formKey = GlobalKey<FormState>();

  late final weeklyScheduleController = WeeklySchedulesController();

  final _internshipDurationController = TextEditingController();
  int get internshipDuration =>
      int.tryParse(_internshipDurationController.text) ?? 0;

  final _visitFrequenciesController = TextEditingController();
  String get visitFrequencies => _visitFrequenciesController.text;

  void onScheduleChanged() {
    if (weeklyScheduleController.dateRange != null &&
        weeklyScheduleController.weeklySchedules.isEmpty) {
      weeklyScheduleController.addWeeklySchedule(
          WeeklySchedulesController.fillNewScheduleList(
              schedule: weeklyScheduleController.weeklySchedules.isEmpty
                  ? {}
                  : weeklyScheduleController.weeklySchedules.last.schedule,
              periode: weeklyScheduleController.dateRange!));
    }
    setState(() {});
  }

  @override
  void dispose() {
    weeklyScheduleController.dispose();
    _internshipDurationController.dispose();
    _visitFrequenciesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building ScheduleStep widget');

    return FocusScope(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateRange(
              scheduleController: weeklyScheduleController,
              onScheduleChanged: onScheduleChanged,
            ),
            Visibility(
                visible: weeklyScheduleController.dateRange != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SubTitle('Horaire du stage', left: 0),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: ScheduleSelector(
                        scheduleController: weeklyScheduleController,
                        editMode: true,
                      ),
                    ),
                    _Hours(controller: _internshipDurationController),
                    _VisitFrequencies(controller: _visitFrequenciesController),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

class _DateRange extends StatefulWidget {
  const _DateRange(
      {required this.scheduleController, required this.onScheduleChanged});

  final WeeklySchedulesController scheduleController;
  final Function() onScheduleChanged;

  @override
  State<_DateRange> createState() => _DateRangeState();
}

class _DateRangeState extends State<_DateRange> {
  bool _isValid = true;

  Future<void> _promptDateRange(BuildContext context) async {
    final range = await showCustomDateRangePicker(
      helpText: 'Sélectionner les dates',
      saveText: 'Confirmer',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      context: context,
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDateRange: widget.scheduleController.dateRange,
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (range == null) return;

    _isValid = true;
    widget.scheduleController.dateRange = range;

    widget.onScheduleChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Dates de stage', top: 0, left: 0),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: _isValid ? Colors.black : Colors.red),
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
                  )
                ],
              ),
              Visibility(
                visible: widget.scheduleController.dateRange != null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 180,
                      child: TextField(
                        decoration: const InputDecoration(
                            labelText: 'Date de début',
                            labelStyle: TextStyle(color: Colors.black),
                            border: InputBorder.none),
                        style: TextStyle(color: Colors.black),
                        controller: TextEditingController(
                            text: widget.scheduleController.dateRange == null
                                ? null
                                : DateFormat.yMMMEd('fr_CA').format(widget
                                    .scheduleController.dateRange!.start)),
                        enabled: false,
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        decoration: const InputDecoration(
                            labelText: 'Date de fin',
                            labelStyle: TextStyle(color: Colors.black),
                            border: InputBorder.none),
                        style: TextStyle(color: Colors.black),
                        controller: TextEditingController(
                            text: widget.scheduleController.dateRange == null
                                ? null
                                : DateFormat.yMMMEd('fr_CA').format(
                                    widget.scheduleController.dateRange!.end)),
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

class _Hours extends StatelessWidget {
  const _Hours({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Nombre d\'heures', left: 0, bottom: 0),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
                labelText: '* Nombre total d\'heures de stage à faire'),
            validator: (text) =>
                text!.isEmpty ? 'Indiquer un nombre d\'heures.' : null,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}

class _VisitFrequencies extends StatelessWidget {
  const _VisitFrequencies({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Visites de supervision', left: 0, bottom: 0),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
                labelText: 'Fréquence des visites de l\'enseignant\u00b7e'),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}
