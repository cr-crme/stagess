import 'package:stagess_common/models/itineraries/itinerary.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

class ItinerariesHelpers {
  static Future<bool> add(
    Itinerary item, {
    required TeachersProvider teachers,
  }) async {
    final me = teachers.currentTeacher;
    if (me == null) throw Exception('No teacher found in context');

    final itineraries = me.itineraries;

    final index =
        itineraries.indexWhere((itinerary) => itinerary.id == item.id);

    if (index < 0) {
      itineraries.add(item);
    } else {
      itineraries[index] = item;
    }

    return await teachers.replaceWithConfirmation(
      me.copyWith(itineraries: itineraries),
    );
  }
}
