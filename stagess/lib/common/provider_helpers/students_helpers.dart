import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

class StudentsHelpers {
  ///
  /// This returns the students the teacher should have read/write access too.
  /// These are the students from the group the teacher teaches too (even though
  /// they are not supervising them personnally)
  static List<Student> studentsInMyGroups(BuildContext context,
      {bool listen = true}) {
    final acceptedGroups =
        TeachersProvider.of(context, listen: false).currentTeacher?.groups;
    if (acceptedGroups == null || acceptedGroups.isEmpty) return [];

    return StudentsProvider.of(
      context,
      listen: listen,
    ).where((e) => acceptedGroups.contains(e.group)).toList();
  }

  ///
  /// Get all the supervized students. If [activeOnly], the students without an
  /// active internship are ignored
  static List<Student> mySupervizedStudents(
    BuildContext context, {
    listen = true,
    bool activeOnly = false,
  }) {
    final allStudents = studentsInMyGroups(context, listen: listen);
    final internships = InternshipsProvider.of(context, listen: false);
    final currentTeacherId =
        TeachersProvider.of(context, listen: false).currentTeacher?.id;
    if (currentTeacherId == null || internships.isEmpty) return [];

    // Get the student I supervise by default
    final List<Student> out = [];
    // Add them those that were transfered to me
    for (final internship in internships) {
      // If I am not in charge of this internship
      if (!internship.supervisingTeacherIds.contains(currentTeacherId)) {
        continue;
      }

      // If it is not active (or that we should keep the inactive)
      if (activeOnly && internship.isNotActive) continue;

      // Get the student from that internship
      final student = allStudents.firstWhereOrNull(
        (e) => e.id == internship.studentId,
      );

      // If none of the students I can access is assigned to that internship
      if (student == null) continue;

      // If the student assigned to that internship was already added
      if (out.any((e) => e.id == student.id)) continue;

      // Otherwise all this, add it to the pool
      out.add(student);
    }

    return out;
  }
}
