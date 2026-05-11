import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/drawer/main_drawer.dart';
import 'package:stagess_admin/screens/students/add_student_dialog.dart';
import 'package:stagess_admin/screens/students/school_students_card.dart';
import 'package:stagess_admin/widgets/select_school_board_dialog.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

class StudentsListScreen extends StatelessWidget {
  const StudentsListScreen({super.key});

  static const route = '/students_list';

  ///
  /// This complicate structure is basically separating the students by
  /// school and then by class group (associated with a teacher).
  Map<SchoolBoard, Map<School, Map<String, List<Student>>>> _getStudents(
    BuildContext context,
  ) {
    final schoolBoards = SchoolBoardsProvider.of(context);

    final allStudents = [...StudentsProvider.of(context, listen: true)];
    allStudents.sort((a, b) {
      final lastNameA = a.lastName.toLowerCase();
      final lastNameB = b.lastName.toLowerCase();
      var comparison = lastNameA.compareTo(lastNameB);
      if (comparison != 0) return comparison;

      final firstNameA = a.firstName.toLowerCase();
      final firstNameB = b.firstName.toLowerCase();
      comparison = firstNameA.compareTo(firstNameB);
      return comparison;
    });

    // Dispatch students
    final students = <SchoolBoard, Map<School, Map<String, List<Student>>>>{};
    for (final schoolBoard in schoolBoards) {
      final studentsBySchoolsAndGroups = <School, Map<String, List<Student>>>{};
      for (final school in schoolBoard.schools) {
        final studentsInSchool = allStudents
            .where((student) => student.schoolId == school.id)
            .toList();
        final studentsByGroups = <String, List<Student>>{};
        for (final student in studentsInSchool) {
          if (!studentsByGroups.containsKey(student.group)) {
            studentsByGroups[student.group] = [];
          }
          studentsByGroups[student.group]!.add(student);
        }
        studentsBySchoolsAndGroups[school] = studentsByGroups;
      }
      students[schoolBoard] = studentsBySchoolsAndGroups;
    }
    return students;
  }

  Future<void> _showAddStudentDialog(BuildContext context) async {
    final schoolBoard = await showSelectSchoolBoardDialog(context);
    if (schoolBoard == null || !context.mounted) return;

    final answer = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AddStudentDialog(schoolBoard: schoolBoard),
    );
    if (answer is! Student || !context.mounted) return;

    StudentsProvider.of(context, listen: false).add(answer);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);
    final schoolBoardStudents = _getStudents(context);

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: const Text('Liste des élèves'),
        actions: authProvider.databaseAccessLevel >= AccessLevel.admin
            ? [
                IconButton(
                  onPressed: () => _showAddStudentDialog(context),
                  icon: Icon(Icons.add),
                ),
              ]
            : null,
      ),
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._buildTiles(context, schoolBoardStudents),
            SizedBox(height: MediaQuery.of(context).size.height * 0.5),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTiles(
    BuildContext context,
    Map<SchoolBoard, Map<School, Map<String, List<Student>>>>
        schoolBoardStudents,
  ) {
    final authProvider = AuthProvider.of(context, listen: true);

    if (schoolBoardStudents.isEmpty) {
      return [const Center(child: Text('Aucun élève inscrit·e'))];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin => schoolBoardStudents.entries
          .map(
            (schoolBoardEntry) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedExpandingCard(
                header: (ctx, isExpanded) => Text(
                  schoolBoardEntry.key.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(color: Colors.black),
                ),
                elevation: 0.0,
                initialExpandedState: true,
                child: Column(
                  children: [
                    ...schoolBoardEntry.value.entries.map(
                      (schoolEntry) => Column(
                        children: [
                          SchoolStudentsCard(
                            schoolId: schoolEntry.key.id,
                            studentsByGroups: schoolEntry.value,
                            schoolBoard: schoolBoardEntry.key,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
      AccessLevel.admin ||
      AccessLevel.teacher ||
      AccessLevel.invalid =>
        schoolBoardStudents.values.firstOrNull?.entries
                .map(
                  (schoolEntry) => Column(
                    children: [
                      SchoolStudentsCard(
                        schoolId: schoolEntry.key.id,
                        studentsByGroups: schoolEntry.value,
                        schoolBoard: schoolBoardStudents.keys.firstOrNull ??
                            SchoolBoard.empty,
                      ),
                    ],
                  ),
                )
                .toList() ??
            [],
    };
  }
}
