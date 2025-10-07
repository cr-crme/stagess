import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

extension InternshipExtension on Internship {
  Internship copyWithTeacher(context, {required String teacherId}) {
    if (teacherId == signatoryTeacherId ||
        supervisingTeacherIds.contains(teacherId)) {
      // If the teacher is already assigned, do nothing
      return this;
    }

    // Make sure the student is in a group supervised by the teacher
    final students = StudentsProvider.of(context, listen: false);
    final student = students.firstWhere((e) => e.id == studentId);
    final teacher = TeachersProvider.of(context, listen: false)[teacherId];
    if (!teacher.groups.contains(student.group)) {
      // TODO: This currently creates a problem with "tableau de supervision" where some students appear but cannot be assigned to a teacher
      throw Exception(
        'The teacher ${teacher.fullName} is not assigned to the group ${student.group}',
      );
    }

    return copyWith(
      extraSupervisingTeacherIds: [...extraSupervisingTeacherIds, teacherId],
    );
  }

  Internship copyWithoutTeacher(context, {required String teacherId}) {
    if (teacherId == signatoryTeacherId ||
        !supervisingTeacherIds.contains(teacherId)) {
      // If the teacher is not assigned, do nothing
      return this;
    }

    return copyWith(
      extraSupervisingTeacherIds:
          extraSupervisingTeacherIds.where((id) => id != teacherId).toList(),
    );
  }
}
