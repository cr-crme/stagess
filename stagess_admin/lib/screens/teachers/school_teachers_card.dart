import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/teachers/teacher_list_tile.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';

class SchoolTeachersCard extends StatelessWidget {
  const SchoolTeachersCard({
    super.key,
    required this.schoolId,
    required this.teachers,
    required this.filteredTeacherIds,
  });

  final String schoolId;
  final List<Teacher> teachers;
  final List<String>? filteredTeacherIds;

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);
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
        if (teachers.isEmpty)
          Center(child: Text('Aucun enseignant·e inscrit·e')),
        if (teachers.isNotEmpty)
          ...teachers
              .where((teacher) =>
                  filteredTeacherIds == null ||
                  filteredTeacherIds!.contains(teacher.id))
              .map((teacher) {
            final canDelete = authProvider.databaseAccessLevel >
                    AccessLevel.schoolBoardAdmin ||
                (authProvider.databaseAccessLevel > AccessLevel.schoolAdmin &&
                    authProvider.schoolBoardId == teacher.schoolBoardId) ||
                (authProvider.databaseAccessLevel > AccessLevel.teacher &&
                    authProvider.schoolBoardId == teacher.schoolBoardId &&
                    authProvider.schoolId == teacher.schoolId);
            final canEdit = canDelete || (authProvider.teacherId == teacher.id);

            return TeacherListTile(
              key: ValueKey(teacher.id),
              teacher: teacher,
              canEdit: canEdit,
              canDelete: canDelete,
            );
          }),
      ],
    );
  }
}
