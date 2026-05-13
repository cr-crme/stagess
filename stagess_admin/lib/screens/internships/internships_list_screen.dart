import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/drawer/main_drawer.dart';
import 'package:stagess_admin/screens/internships/add_internship_dialog.dart';
import 'package:stagess_admin/screens/internships/internship_list_tile.dart';
import 'package:stagess_admin/widgets/select_school_board_dialog.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/search.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class InternshipsListScreen extends StatefulWidget {
  const InternshipsListScreen({super.key});

  static const route = '/internships_list';

  @override
  State<InternshipsListScreen> createState() => _InternshipsListScreenState();
}

class _InternshipsListScreenState extends State<InternshipsListScreen> {
  bool _showSearchBar = false;
  late final _searchController = TextEditingController()
    ..addListener(() => setState(() {}));

  List<String>? _filterInternshipIds(
      Map<SchoolBoard, Map<bool, Map<School, Map<Teacher, List<Internship>>>>>
          internships) {
    final textToSearch = _searchController.text.toLowerCase().trim();
    if (!_showSearchBar || textToSearch.isEmpty) return null;

    final students = StudentsProvider.of(context, listen: false);

    final matchingInternshipIds = <String>{};
    for (final internshipsBySchools in internships.values) {
      for (final internshipsByTeachers in internshipsBySchools.values) {
        for (final internshipsByTeacherEntry in internshipsByTeachers.entries) {
          final school = internshipsByTeacherEntry.key;
          final internshipsByTeacher = internshipsByTeacherEntry.value;

          if (school.name.toLowerCase().contains(textToSearch)) {
            for (var internshipList in internshipsByTeacher.values) {
              matchingInternshipIds.addAll(internshipList.map((i) => i.id));
            }
            continue;
          }

          for (final internshipListEntry in internshipsByTeacher.entries) {
            final teacher = internshipListEntry.key;
            final internshipList = internshipListEntry.value;

            if (teacher.fullName.toLowerCase().contains(textToSearch)) {
              matchingInternshipIds.addAll(internshipList.map((i) => i.id));
              continue;
            }

            for (final internship in internshipList) {
              final student = students.fromIdOrNull(internship.studentId);
              if (student != null &&
                  student.fullName.toLowerCase().contains(textToSearch)) {
                matchingInternshipIds.add(internship.id);
              }
            }
          }
        }
      }
    }
    return matchingInternshipIds.toList();
  }

  Map<SchoolBoard, Map<bool, Map<School, Map<Teacher, List<Internship>>>>>
      _getInternships(BuildContext context) {
    final schoolBoards = SchoolBoardsProvider.of(context, listen: true);
    final teachers = TeachersProvider.of(context, listen: true);

    final internshipsTp = [...InternshipsProvider.of(context, listen: true)];
    internshipsTp.sort((a, b) {
      final nameA = a.studentId.toLowerCase();
      final nameB = b.studentId.toLowerCase();
      return nameA.compareTo(nameB);
    });

    final internships =
        <SchoolBoard, Map<bool, Map<School, Map<Teacher, List<Internship>>>>>{};
    for (final schoolBoard in schoolBoards) {
      final internshipsBySchools =
          <bool, Map<School, Map<Teacher, List<Internship>>>>{};
      final schools = schoolBoard.schools;
      for (final internship in internshipsTp) {
        final teacher = teachers.firstWhereOrNull(
          (teacher) => teacher.id == internship.signatoryTeacherId,
        );
        if (teacher == null) continue;

        final school = schools.firstWhereOrNull(
          (school) => school.id == teacher.schoolId,
        );
        if (school == null) continue;

        if (!internshipsBySchools.containsKey(internship.isActive)) {
          internshipsBySchools[internship.isActive] = {};
        }
        if (!internshipsBySchools[internship.isActive]!.containsKey(school)) {
          internshipsBySchools[internship.isActive]![school] = {};
        }
        if (!internshipsBySchools[internship.isActive]![school]!.containsKey(
          teacher,
        )) {
          internshipsBySchools[internship.isActive]![school]![teacher] = [];
        }
        internshipsBySchools[internship.isActive]![school]![teacher]!.add(
          internship,
        );
      }
      internships[schoolBoard] = internshipsBySchools;
    }

    return internships;
  }

  Future<void> _showAddInternshipDialog(BuildContext context) async {
    final schoolBoard = await showSelectSchoolBoardDialog(context);
    if (schoolBoard == null || !context.mounted) return;

    final answer = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AddInternshipDialog(schoolBoard: schoolBoard),
    );
    if (answer is! Internship || !context.mounted) return;

    final isSuccess = await InternshipsProvider.of(
      context,
      listen: false,
    ).addWithConfirmation(answer);
    if (!context.mounted) return;

    showSnackBar(
      context,
      message:
          isSuccess ? 'Stage ajouté avec succès' : 'Échec de l\'ajout du stage',
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolBoardInternships = _getInternships(context);
    final filteredInternshipIds = _filterInternshipIds(schoolBoardInternships);

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: const Text('Liste des stages'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => _showAddInternshipDialog(context),
            icon: Icon(Icons.add),
          ),
        ],
        bottom: _showSearchBar ? Search(controller: _searchController) : null,
      ),
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body: SingleChildScrollView(
        child: Column(children: [
          ..._buildTiles(
              context, schoolBoardInternships, filteredInternshipIds),
          SizedBox(height: MediaQuery.of(context).size.height * 0.5),
        ]),
      ),
    );
  }

  List<Widget> _buildTiles(
    BuildContext context,
    Map<SchoolBoard, Map<bool, Map<School, Map<Teacher, List<Internship>>>>>
        schoolBoardInternships,
    List<String>? filteredInternshipIds,
  ) {
    final authProvider = AuthProvider.of(context, listen: true);

    if (schoolBoardInternships.isEmpty) {
      return [const Center(child: Text('Aucun stage enregistré'))];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin => schoolBoardInternships.entries
          .where(
            (entry) => entry.value.values.any(
              (internshipsBySchool) => internshipsBySchool.values.any(
                (internshipsByTeacher) => internshipsByTeacher.values.any(
                  (internshipList) => internshipList.isNotEmpty,
                ),
              ),
            ),
          )
          .map(
            (schoolBoardEntry) => AnimatedExpandingCard(
              header: (ctx, isExpanded) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  schoolBoardEntry.key.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(color: Colors.black),
                ),
              ),
              elevation: 0.0,
              initialExpandedState: true,
              child: Column(
                children: [
                  _InternshipsByStatus(
                    key: const ValueKey('active_internships'),
                    areActive: true,
                    internships: schoolBoardEntry.value[true] ?? {},
                    filteredInternshipIds: filteredInternshipIds,
                  ),
                  _InternshipsByStatus(
                    key: const ValueKey('closed_internships'),
                    areActive: false,
                    internships: schoolBoardEntry.value[false] ?? {},
                    filteredInternshipIds: filteredInternshipIds,
                  ),
                ],
              ),
            ),
          )
          .toList(),
      AccessLevel.admin || AccessLevel.teacher || AccessLevel.invalid => [
          _InternshipsByStatus(
            key: const ValueKey('active_internships'),
            areActive: true,
            internships: schoolBoardInternships.values.firstOrNull?[true] ?? {},
            filteredInternshipIds: filteredInternshipIds,
          ),
          _InternshipsByStatus(
            key: const ValueKey('closed_internships'),
            areActive: false,
            internships:
                schoolBoardInternships.values.firstOrNull?[false] ?? {},
            filteredInternshipIds: filteredInternshipIds,
          ),
        ],
    };
  }
}

class _InternshipsByStatus extends StatelessWidget {
  const _InternshipsByStatus({
    super.key,
    required this.areActive,
    required this.internships,
    required this.filteredInternshipIds,
  });

  final Map<School, Map<Teacher, List<Internship>>> internships;
  final bool areActive;
  final List<String>? filteredInternshipIds;

  @override
  Widget build(BuildContext context) {
    return AnimatedExpandingCard(
      header: (ctx, isExpanded) => Padding(
        padding: const EdgeInsets.only(left: 12.0, top: 12, bottom: 8.0),
        child: Text(
          areActive ? 'Stages actifs' : 'Stages terminés',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      initialExpandedState: areActive,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: _InternshipsBySchools(
            internships: internships,
            filteredInternshipIds: filteredInternshipIds),
      ),
    );
  }
}

class _InternshipsBySchools extends StatelessWidget {
  const _InternshipsBySchools({
    required this.internships,
    required this.filteredInternshipIds,
  });

  final Map<School, Map<Teacher, List<Internship>>> internships;
  final List<String>? filteredInternshipIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: internships.entries
          .where(
        (entry) => entry.value.values.any(
          (internshipList) => internshipList.any(
            (internship) =>
                filteredInternshipIds == null ||
                filteredInternshipIds!.contains(internship.id),
          ),
        ),
      )
          .map((entry) {
        final school = entry.key;
        final teachers = entry.value;

        return AnimatedExpandingCard(
          key: ValueKey(school.id),
          header: (ctx, isExpanded) => Text(
            school.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          initialExpandedState: true,
          elevation: 0,
          child: _InternshipsByTeachers(
              teachers: teachers, filteredInternshipIds: filteredInternshipIds),
        );
      }).toList(),
    );
  }
}

class _InternshipsByTeachers extends StatelessWidget {
  const _InternshipsByTeachers({
    required this.teachers,
    required this.filteredInternshipIds,
  });

  final Map<Teacher, List<Internship>> teachers;
  final List<String>? filteredInternshipIds;

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);
    final canDelete = authProvider.databaseAccessLevel >= AccessLevel.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...teachers.entries
            .where((entry) => entry.value.any(
                  (internship) =>
                      filteredInternshipIds == null ||
                      filteredInternshipIds!.contains(internship.id),
                ))
            .map((entry) {
          final teacher = entry.key;
          final internshipsList = entry.value;

          return Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: AnimatedExpandingCard(
              key: ValueKey(teacher.id),
              header: (ctx, isExpanded) => Text(
                teacher.fullName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              elevation: 0,
              initialExpandedState: true,
              child: Column(
                children: [
                  ...internshipsList
                      .where((internship) =>
                          filteredInternshipIds == null ||
                          filteredInternshipIds!.contains(internship.id))
                      .map((internship) {
                    return InternshipListTile(
                      key: ValueKey(internship.id),
                      internship: internship,
                      canEdit: true,
                      canDelete: canDelete,
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
