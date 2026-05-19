import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/students/student_list_tile.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

class SchoolStudentsCard extends StatelessWidget {
  const SchoolStudentsCard({
    super.key,
    required this.schoolId,
    required this.studentsByGroups,
    required this.filteredStudentIds,
  });

  final String schoolId;
  final Map<String, List<Student>> studentsByGroups;
  final List<String>? filteredStudentIds;

  @override
  Widget build(BuildContext context) {
    final groups = studentsByGroups.keys.toList();
    groups.sort((a, b) {
      final groupA = a.toLowerCase();
      final groupB = b.toLowerCase();
      return groupA.compareTo(groupB);
    });

    final school =
        SchoolBoardsProvider.of(context, listen: true).schoolFromId(schoolId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8, bottom: 8),
          child: Text(
            school?.name ?? 'École introuvable',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (studentsByGroups.isEmpty)
          Center(child: Text('Aucun élève inscrit·e à cette école')),
        if (studentsByGroups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 12.0),
            child: Column(
              children: [
                ...groups.where((group) {
                  if (filteredStudentIds == null) return true;
                  return studentsByGroups[group]?.any((student) =>
                          filteredStudentIds!.contains(student.id)) ??
                      false;
                }).map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _GroupStudentsCard(
                      group: group,
                      students: studentsByGroups[group] ?? [],
                      filteredStudentIds: filteredStudentIds,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GroupStudentsCard extends StatelessWidget {
  const _GroupStudentsCard({
    required this.group,
    required this.students,
    required this.filteredStudentIds,
  });

  final String group;
  final List<Student> students;
  final List<String>? filteredStudentIds;

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);
    final teacherProvided = TeachersProvider.of(context, listen: false);
    final teachers = teacherProvided
        .where((teacher) => teacher.groups.contains(group))
        .toList();
    teachers.sort((a, b) {
      final teacherA = a.lastName.toLowerCase();
      final teacherB = b.lastName.toLowerCase();
      var comparison = teacherA.compareTo(teacherB);
      if (comparison != 0) return comparison;
      final firstNameA = a.firstName.toLowerCase();
      final firstNameB = b.firstName.toLowerCase();
      comparison = firstNameA.compareTo(firstNameB);
      return comparison;
    });
    final teachersForGroups = teachers.map((teacher) => teacher.fullName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Groupe : $group - ${teachersForGroups.isNotEmpty ? teachersForGroups.join(', ') : 'Aucun enseignant·e'}',
        ),
        if (students.isEmpty)
          Center(child: Text('Aucun élève inscrit·e dans ce groupe')),
        if (students.isNotEmpty)
          ...students.where((student) {
            if (filteredStudentIds == null) return true;
            return filteredStudentIds!.contains(student.id);
          }).map(
            (student) {
              final canDelete = authProvider.databaseAccessLevel >
                      AccessLevel.schoolBoardAdmin ||
                  (authProvider.databaseAccessLevel > AccessLevel.schoolAdmin &&
                      authProvider.schoolBoardId == student.schoolBoardId) ||
                  (authProvider.databaseAccessLevel > AccessLevel.teacher &&
                      authProvider.schoolBoardId == student.schoolBoardId &&
                      authProvider.schoolId == student.schoolId);
              final canEdit = canDelete;

              return StudentListTile(
                key: ValueKey(student.id),
                student: student,
                canEdit: canEdit,
                canDelete: canDelete,
              );
            },
          ),
      ],
    );
  }
}
