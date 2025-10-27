import 'package:intl/intl.dart';
import 'package:stagess_common/models/itineraries/itinerary.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

class ItinerariesHelpers {
  static Future<bool> add(
    Itinerary item, {
    required TeachersProvider teachers,
  }) async {
    final me = teachers.currentTeacher;
    if (me == null) throw Exception('No teacher found in context');

    final itineraries = me.itineraries;
    final index = itineraries.indexWhere((e) => e.date == item.date);
    if (index < 0) {
      itineraries.add(item);
    } else {
      itineraries[index] = item;
    }
    return await teachers.replaceWithConfirmation(
      me.copyWith(itineraries: itineraries),
    );
  }

  static final _dateFormat = DateFormat('dd_MM_yyyy');

  static Itinerary? fromDate(
    DateTime date, {
    required TeachersProvider teachers,
  }) {
    final itineraries = teachers.currentTeacher?.itineraries;
    if (itineraries == null) return null;

    final dateAsString = _dateFormat.format(date);
    return itineraries.firstWhereOrNull(
      (e) => _dateFormat.format(e.date) == dateAsString,
    );
  }
}
