import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/drawer/main_drawer.dart';
import 'package:stagess_admin/screens/teachers/add_teacher_dialog.dart';
import 'package:stagess_admin/screens/teachers/school_teachers_card.dart';
import 'package:stagess_admin/widgets/select_school_board_dialog.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/search.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class TeachersListScreen extends StatefulWidget {
  const TeachersListScreen({super.key});

  static const route = '/teachers_list';

  @override
  State<TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends State<TeachersListScreen> {
  bool _showSearchBar = false;
  late final _searchController = TextEditingController()
    ..addListener(() => setState(() {}));

  List<String>? _filterTeacherIds(
      Map<SchoolBoard, Map<School, List<Teacher>>> schoolBoards) {
    final textToSearch = _searchController.text.toLowerCase().trim();
    if (!_showSearchBar || textToSearch.isEmpty) return null;

    final matchingTeacherIds = <String>{};
    for (final teachersBySchool in schoolBoards.values) {
      for (final teachers in teachersBySchool.values) {
        matchingTeacherIds.addAll(teachers
            .where((teacher) =>
                teacher.fullName.toLowerCase().contains(textToSearch))
            .map((t) => t.id));
      }
    }
    return matchingTeacherIds.toList();
  }

  Map<SchoolBoard, Map<School, List<Teacher>>> _getTeachers(
    BuildContext context,
  ) {
    final teachersProvider = TeachersProvider.of(context, listen: true);
    final schoolBoards = SchoolBoardsProvider.of(context, listen: true);

    // Sort by school name
    final teachers = <SchoolBoard, Map<School, List<Teacher>>>{};
    for (final schoolBoard in schoolBoards) {
      final teachersBySchool = <School, List<Teacher>>{};

      for (final school in schoolBoard.schools) {
        final schoolTeachers = teachersProvider
            .where((teacher) => teacher.schoolId == school.id)
            .toList();

        schoolTeachers.sort((a, b) {
          final lastNameA = a.lastName.toLowerCase();
          final lastNameB = b.lastName.toLowerCase();
          var comparison = lastNameA.compareTo(lastNameB);
          if (comparison != 0) return comparison;

          final firstNameA = a.firstName.toLowerCase();
          final firstNameB = b.firstName.toLowerCase();
          return firstNameA.compareTo(firstNameB);
        });
        teachersBySchool[school] = schoolTeachers;
      }

      teachers[schoolBoard] = teachersBySchool;
    }

    return teachers;
  }

  Future<void> _showAddTeacherDialog(BuildContext context) async {
    final schoolBoard = await showSelectSchoolBoardDialog(context);
    if (schoolBoard == null || !context.mounted) return;

    final isConfirmed = await showDialog<bool>(
          barrierDismissible: false,
          context: context,
          builder: (context) => AddTeacherDialog(schoolBoard: schoolBoard),
        ) ??
        false;
    if (!context.mounted) return;

    showSnackBar(context,
        message: isConfirmed
            ? 'L\'enseignant·e a été ajouté·e avec succès'
            : 'Aucun enseignant·e n\'a été ajouté·e');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);
    final schoolBoardTeachers = _getTeachers(context);
    final filteredTeacherIds = _filterTeacherIds(schoolBoardTeachers);

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: const Text('Liste des enseignant·e·s'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
            icon: const Icon(Icons.search),
          ),
          if (authProvider.databaseAccessLevel >= AccessLevel.admin)
            IconButton(
              onPressed: () => _showAddTeacherDialog(context),
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
            ..._buildTiles(context, schoolBoardTeachers, filteredTeacherIds),
            SizedBox(height: MediaQuery.of(context).size.height * 0.5),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTiles(
    BuildContext context,
    Map<SchoolBoard, Map<School, List<Teacher>>> schoolBoardTeachers,
    List<String>? filteredTeacherIds,
  ) {
    final authProvider = AuthProvider.of(context, listen: true);

    if (schoolBoardTeachers.isEmpty) {
      return [const Center(child: Text('Aucun enseignant·e inscrit·e'))];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin => schoolBoardTeachers.entries
          .where((element) => element.value.values.any((teachers) =>
              filteredTeacherIds == null ||
              teachers
                  .any((teacher) => filteredTeacherIds.contains(teacher.id))))
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
                    ...schoolBoardEntry.value.entries
                        .where((schoolEntry) => schoolEntry.value.any(
                            (teacher) =>
                                filteredTeacherIds == null ||
                                filteredTeacherIds.contains(teacher.id)))
                        .map(
                          (schoolEntry) => SchoolTeachersCard(
                            schoolId: schoolEntry.key.id,
                            teachers: schoolEntry.value,
                            schoolBoard: schoolBoardEntry.key,
                            filteredTeacherIds: filteredTeacherIds,
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
        schoolBoardTeachers.values.firstOrNull?.entries
                .where((schoolEntry) => schoolEntry.value.any((teacher) =>
                    filteredTeacherIds == null ||
                    filteredTeacherIds.contains(teacher.id))) // Filter schools
                .map(
                  (schoolEntry) => SchoolTeachersCard(
                    schoolId: schoolEntry.key.id,
                    teachers: schoolEntry.value,
                    schoolBoard: schoolBoardTeachers.keys.firstOrNull ??
                        SchoolBoard.empty,
                    filteredTeacherIds: filteredTeacherIds,
                  ),
                )
                .toList() ??
            [],
    };
  }
}
