import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

import '../utils.dart';

void main() {
  group('ItinerariesProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    test('"add" works', () async {
      final teachers = TeachersProvider(
        uri: Uri.parse('ws://localhost'),
        mockMe: true,
      );
      teachers.initializeAuth(AuthProvider(mockMe: true));
      final itineraries = [...(teachers.currentTeacher?.itineraries ?? [])];

      itineraries.add(dummyItinerary(name: 'TestItinerary 1'));
      itineraries.add(dummyItinerary(name: 'TestItinerary 2'));
      itineraries.add(dummyItinerary(name: 'TestItinerary 3'));

      final teacherItineraries = teachers.currentTeacher?.itineraries ?? [];
      expect(teacherItineraries.length, 0);

      expect(itineraries.length, 3);
      expect(itineraries[0].name, 'TestItinerary 1');
      expect(itineraries[1].name, 'TestItinerary 2');
      expect(itineraries[2].name, 'TestItinerary 3');
    });
  });
}
