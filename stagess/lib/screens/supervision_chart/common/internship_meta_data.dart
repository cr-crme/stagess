import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/itineraries/visiting_priority.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/providers/helpers/internships_helpers.dart';
import 'package:stagess_common_flutter/providers/helpers/students_helpers.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

class InternshipMetaData {
  final Internship internship;
  final Student student;
  bool isSupervised;
  bool isTeacherSignatory;
  VisitingPriority visitingPriority;

  InternshipMetaData({
    required this.internship,
    required this.student,
    required this.isSupervised,
    required this.visitingPriority,
    required this.isTeacherSignatory,
  });
}

extension InternshipMetaDataList on List<InternshipMetaData> {
  int get supervizedCount =>
      fold(0, (count, metaData) => count + (metaData.isSupervised ? 1 : 0));

  List<InternshipMetaData> filterPriorities(
    List<VisitingPriority> whiteList,
  ) =>
      where(
        (metaData) => whiteList.contains(metaData.visitingPriority),
      ).toList();

  List<InternshipMetaData> filterByText(String text) {
    if (text.isEmpty) return this;
    return where(
      (metaData) => metaData.student.fullName.toLowerCase().contains(text),
    ).toList();
  }

  InternshipMetaData? getSupervized(int index) {
    int count = 0;
    for (final metaData in this) {
      if (metaData.isSupervised) {
        if (count == index) return metaData;
        count++;
      }
    }
    return null;
  }

  static List<InternshipMetaData> internshipsOf(BuildContext context) {
    final currentTeacher =
        TeachersProvider.of(context, listen: true).currentTeacher;
    if (currentTeacher == null) return [];

    final internships = InternshipsProvider.of(context, listen: true);
    final students = StudentsHelpers.studentsInMyGroups(context, listen: true);

    List<InternshipMetaData> out = [];

    for (final internship in internships) {
      if (!internship.isActive) continue;

      final student = students.firstWhereOrNull(
        (student) => student.id == internship.studentId,
      );
      // Skip internships with no student I have access to
      if (student == null) continue;

      out.add(
        InternshipMetaData(
          internship: internship,
          student: students.firstWhere(
            (student) => student.id == internship.studentId,
          ),
          isSupervised: internship.hasAccessToPrivateFields(context),
          visitingPriority: currentTeacher.visitingPriority(internship.id) ==
                  VisitingPriority.notApplicable
              ? VisitingPriority.low
              : currentTeacher.visitingPriority(internship.id),
          isTeacherSignatory:
              internship.signatoryTeacherId == currentTeacher.id,
        ),
      );
    }

    // Sort the internships by student names
    out.sort(
      (a, b) => a.student.lastName.toLowerCase().compareTo(
            b.student.lastName.toLowerCase(),
          ),
    );

    // Return the internships
    return out;
  }
}
