import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/extensions/visiting_priorities_extension.dart';
import 'package:stagess_common/models/itineraries/visiting_priority.dart';

void main() {
  group('VisitingPriority', () {
    test('"next" behaves properly', () {
      expect(VisitingPriority.low.next, VisitingPriority.mid);
      expect(VisitingPriority.mid.next, VisitingPriority.high);
      expect(VisitingPriority.high.next, VisitingPriority.low);

      // Test the side effects as well
      expect(VisitingPriority.school.next, VisitingPriority.mid);
      expect(VisitingPriority.notApplicable.next, VisitingPriority.mid);
    });

    test('is the right color', () {
      expect(VisitingPriority.low.color, Colors.green);
      expect(VisitingPriority.mid.color, Colors.orange);
      expect(VisitingPriority.high.color, Colors.red);
      expect(VisitingPriority.school.color, Colors.purple);
      expect(VisitingPriority.notApplicable.color, Colors.grey);
    });

    test('is the right icon', () {
      expect(VisitingPriority.low.icon, Icons.looks_3);
      expect(VisitingPriority.mid.icon, Icons.looks_two);
      expect(VisitingPriority.high.icon, Icons.looks_one);
      expect(VisitingPriority.school.icon, Icons.school);
      expect(VisitingPriority.notApplicable.icon, Icons.cancel);
    });
  });
}
