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
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/search.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  static const route = '/students_list';

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  bool _showSearchBar = false;
  late final _searchController = TextEditingController()
    ..addListener(() => setState(() {}));

  List<String>? _filterStudentIds(
      Map<SchoolBoard, Map<School, Map<String, List<Student>>>> schoolBoards) {
    final textToSearch = _searchController.text.toLowerCase().trim();
    if (!_showSearchBar || textToSearch.isEmpty) return null;

    final teachers = TeachersProvider.of(context, listen: false);

    final matchingStudentIds = <String>{};
    for (final studentsBySchool in schoolBoards.values) {
      for (final studentsByGroupsEntry in studentsBySchool.entries) {
        final school = studentsByGroupsEntry.key;
        final studentsByGroups = studentsByGroupsEntry.value;

        if (school.name.toLowerCase().contains(textToSearch)) {
          for (final students in studentsByGroups.values) {
            matchingStudentIds.addAll(students.map((s) => s.id));
          }
          continue;
        }

        for (final studentsEntry in studentsByGroups.entries) {
          final group = studentsEntry.key.toLowerCase();
          final students = studentsEntry.value;

          if (group.contains(textToSearch) ||
              teachers.any((teacher) =>
                  teacher.groups.contains(group) &&
                  teacher.fullName.toLowerCase().contains(textToSearch))) {
            matchingStudentIds.addAll(students.map((s) => s.id));
            continue;
          }

          for (final student in students) {
            final fullName = student.fullName.toLowerCase();
            if (fullName.contains(textToSearch)) {
              matchingStudentIds.add(student.id);
            }
          }
        }
      }
    }
    return matchingStudentIds.toList();
  }

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
    final filteredStudentIds = _filterStudentIds(schoolBoardStudents);

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: const Text('Liste des élèves'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
            icon: const Icon(Icons.search),
          ),
          if (authProvider.databaseAccessLevel >= AccessLevel.schoolAdmin)
            IconButton(
              onPressed: () => _showAddStudentDialog(context),
              icon: Icon(Icons.add),
            ),
        ],
        bottom: _showSearchBar ? Search(controller: _searchController) : null,
      ),
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._buildTiles(context, schoolBoardStudents, filteredStudentIds),
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
    List<String>? filteredStudentIds,
  ) {
    final authProvider = AuthProvider.of(context, listen: true);

    if (schoolBoardStudents.isEmpty) {
      return [const Center(child: Text('Aucun élève inscrit·e'))];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin => schoolBoardStudents.entries
          .where((schoolBoardEntry) {
            if (filteredStudentIds == null) return true;
            return schoolBoardEntry.value.values.any((studentsByGroups) =>
                studentsByGroups.values.any((students) => students.any(
                    (student) => filteredStudentIds.contains(student.id))));
          })
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
                    ...schoolBoardEntry.value.entries.where((schoolEntry) {
                      if (filteredStudentIds == null) return true;
                      return schoolEntry.value.values.any((students) =>
                          students.any((student) =>
                              filteredStudentIds.contains(student.id)));
                    }).map(
                      (schoolEntry) => Column(
                        children: [
                          SchoolStudentsCard(
                            schoolId: schoolEntry.key.id,
                            studentsByGroups: schoolEntry.value,
                            schoolBoard: schoolBoardEntry.key,
                            filteredStudentIds: filteredStudentIds,
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
      AccessLevel.schoolBoardAdmin ||
      AccessLevel.schoolAdmin ||
      AccessLevel.teacher ||
      AccessLevel.invalid =>
        schoolBoardStudents.values.firstOrNull?.entries
                .where((schoolEntry) {
                  if (filteredStudentIds == null) return true;
                  return schoolEntry.value.values.any((students) =>
                      students.any((student) =>
                          filteredStudentIds.contains(student.id)));
                })
                .map(
                  (schoolEntry) => Column(
                    children: [
                      SchoolStudentsCard(
                        schoolId: schoolEntry.key.id,
                        studentsByGroups: schoolEntry.value,
                        schoolBoard: schoolBoardStudents.keys.firstOrNull ??
                            SchoolBoard.empty,
                        filteredStudentIds: filteredStudentIds,
                      ),
                    ],
                  ),
                )
                .toList() ??
            [],
    };
  }
}
