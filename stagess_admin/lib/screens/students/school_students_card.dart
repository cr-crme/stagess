import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/students/student_list_tile.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common/utils.dart' as utils;
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

class SchoolStudentsCard extends StatelessWidget {
  const SchoolStudentsCard({
    super.key,
    required this.schoolId,
    required this.studentsByGroups,
    required this.schoolBoard,
  });

  final String schoolId;
  final Map<String, List<Student>> studentsByGroups;
  final SchoolBoard schoolBoard;

  @override
  Widget build(BuildContext context) {
    final groups = studentsByGroups.keys.toList();
    groups.sort((a, b) {
      final groupA = a.toLowerCase();
      final groupB = b.toLowerCase();
      return groupA.compareTo(groupB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8, bottom: 8),
          child: Text(
            utils.IterableExtensions(
                  schoolBoard.schools,
                ).firstWhereOrNull((school) => school.id == schoolId)?.name ??
                'École introuvable',
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
                ...groups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _GroupStudentsCard(
                      group: group,
                      students: studentsByGroups[group] ?? [],
                      schoolBoard: schoolBoard,
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
    required this.schoolBoard,
  });

  final String group;
  final List<Student> students;
  final SchoolBoard schoolBoard;

  @override
  Widget build(BuildContext context) {
    final authProvided = AuthProvider.of(context, listen: true);
    final teacherProvided = TeachersProvider.of(context, listen: false);
    final teachers =
        teacherProvided
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
          ...students.map(
            (student) => StudentListTile(
              key: ValueKey(student.id),
              student: student,
              schoolBoard: schoolBoard,
              canEdit: authProvided.databaseAccessLevel >= AccessLevel.admin,
              canDelete: authProvided.databaseAccessLevel >= AccessLevel.admin,
            ),
          ),
      ],
    );
  }
}
