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
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class InternshipsListScreen extends StatelessWidget {
  const InternshipsListScreen({super.key});

  static const route = '/internships_list';

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

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: const Text('Liste des stages'),
        actions: [
          IconButton(
            onPressed: () => _showAddInternshipDialog(context),
            icon: Icon(Icons.add),
          ),
        ],
      ),
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body: SingleChildScrollView(
        child: Column(children: _buildTiles(context, schoolBoardInternships)),
      ),
    );
  }

  List<Widget> _buildTiles(
    BuildContext context,
    Map<SchoolBoard, Map<bool, Map<School, Map<Teacher, List<Internship>>>>>
    schoolBoardInternships,
  ) {
    final authProvider = AuthProvider.of(context, listen: true);

    if (schoolBoardInternships.isEmpty) {
      return [const Center(child: Text('Aucun stage enregistré'))];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin =>
        schoolBoardInternships.entries
            .map(
              (schoolBoardEntry) => AnimatedExpandingCard(
                header:
                    (ctx, isExpanded) => Padding(
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
                    ),
                    _InternshipsByStatus(
                      key: const ValueKey('closed_internships'),
                      areActive: false,
                      internships: schoolBoardEntry.value[false] ?? {},
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
        ),
        _InternshipsByStatus(
          key: const ValueKey('closed_internships'),
          areActive: false,
          internships: schoolBoardInternships.values.firstOrNull?[false] ?? {},
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
  });

  final Map<School, Map<Teacher, List<Internship>>> internships;
  final bool areActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedExpandingCard(
      header:
          (ctx, isExpanded) => Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 12, bottom: 8.0),
            child: Text(
              areActive ? 'Stages actifs' : 'Stages terminés',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
      initialExpandedState: areActive,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: _InternshipsBySchools(internships: internships),
      ),
    );
  }
}

class _InternshipsBySchools extends StatelessWidget {
  const _InternshipsBySchools({required this.internships});

  final Map<School, Map<Teacher, List<Internship>>> internships;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          internships.entries.map((entry) {
            final school = entry.key;
            final teachers = entry.value;

            return AnimatedExpandingCard(
              key: ValueKey(school.id),
              header:
                  (ctx, isExpanded) => Text(
                    school.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
              initialExpandedState: true,
              elevation: 0,
              child: _InternshipsByTeachers(teachers: teachers),
            );
          }).toList(),
    );
  }
}

class _InternshipsByTeachers extends StatelessWidget {
  const _InternshipsByTeachers({required this.teachers});

  final Map<Teacher, List<Internship>> teachers;

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);
    final canDelete = authProvider.databaseAccessLevel >= AccessLevel.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...teachers.entries.map((entry) {
          final teacher = entry.key;
          final internshipsList = entry.value;

          return Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: AnimatedExpandingCard(
              key: ValueKey(teacher.id),
              header:
                  (ctx, isExpanded) => Text(
                    teacher.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
              elevation: 0,
              initialExpandedState: true,
              child: Column(
                children: [
                  ...internshipsList.map((internship) {
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
