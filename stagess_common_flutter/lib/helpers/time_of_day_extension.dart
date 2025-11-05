import 'package:flutter/material.dart';
import 'package:stagess_common/models/internships/time_utils.dart'
    as time_utils;

extension TimeOfDayExtension on time_utils.TimeOfDay {
  String format(BuildContext context) {
    TimeOfDay timeOfDay = TimeOfDay(hour: hour, minute: minute);
    return timeOfDay.format(context).toString();
  }
}
