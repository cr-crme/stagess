import 'package:flutter/material.dart';
import 'package:stagess_common/models/itineraries/visiting_priority.dart';

extension VisitingPrioritiesExtension on VisitingPriority {
  Color get color {
    switch (this) {
      case (VisitingPriority.low):
        return const Color.fromARGB(255, 0, 130, 20);
      case (VisitingPriority.mid):
        return const Color.fromARGB(255, 225, 135, 0);
      case (VisitingPriority.high):
        return const Color.fromARGB(255, 210, 50, 35);
      case (VisitingPriority.school):
        return Colors.purple;
      case (VisitingPriority.notApplicable):
        return const Color.fromARGB(255, 100, 100, 100);
    }
  }

  IconData get icon {
    switch (this) {
      case (VisitingPriority.low):
        return Icons.looks_3;
      case (VisitingPriority.mid):
        return Icons.looks_two;
      case (VisitingPriority.high):
        return Icons.looks_one;
      case (VisitingPriority.school):
        return Icons.school;
      case (VisitingPriority.notApplicable):
        return Icons.cancel;
    }
  }

  IconData get waypointIcon {
    switch (this) {
      case (VisitingPriority.school):
        return Icons.school;
      case (VisitingPriority.low):
      case (VisitingPriority.mid):
      case (VisitingPriority.high):
        return Icons.face;
      case (VisitingPriority.notApplicable):
        return Icons.cancel;
    }
  }

  Color? get waypointColor {
    switch (this) {
      case (VisitingPriority.school):
        return Colors.purple;
      case (VisitingPriority.low):
      case (VisitingPriority.mid):
      case (VisitingPriority.high):
        return null; // Main theme color
      case (VisitingPriority.notApplicable):
        return Colors.grey;
    }
  }
}
