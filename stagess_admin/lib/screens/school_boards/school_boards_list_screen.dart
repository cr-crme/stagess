import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/drawer/main_drawer.dart';
import 'package:stagess_admin/screens/school_boards/add_school_board_dialog.dart';
import 'package:stagess_admin/screens/school_boards/school_board_list_tile.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/search.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class SchoolBoardsListScreen extends StatefulWidget {
  const SchoolBoardsListScreen({super.key});

  static const route = '/schoolboards_list';

  @override
  State<SchoolBoardsListScreen> createState() => _SchoolBoardsListScreenState();
}

class _SchoolBoardsListScreenState extends State<SchoolBoardsListScreen> {
  bool _showSearchBar = false;
  late final _searchController = TextEditingController()
    ..addListener(() => setState(() {}));

  List<String>? _filterSchoolIds(List<SchoolBoard> schoolBoards) {
    final textToSearch = _searchController.text.toLowerCase().trim();
    if (!_showSearchBar || textToSearch.isEmpty) return null;

    final matchingSchoolIds = <String>{};
    for (final schoolBoard in schoolBoards) {
      matchingSchoolIds.addAll(schoolBoard.schools
          .where((school) => school.name.toLowerCase().contains(textToSearch))
          .map((s) => s.id));
    }
    return matchingSchoolIds.toList();
  }

  List<SchoolBoard> _getSchoolBoards(BuildContext context) {
    final schoolBoards = [...SchoolBoardsProvider.of(context, listen: true)];
    schoolBoards.sort((a, b) {
      final nameA = a.name.toLowerCase();
      final nameB = b.name.toLowerCase();
      return nameA.compareTo(nameB);
    });

    return schoolBoards;
  }

  Future<void> _showAddSchoolBoardDialog(BuildContext context) async {
    final answer = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) =>
          AddSchoolBoardDialog(schoolBoard: SchoolBoard.empty),
    );
    if (answer is! SchoolBoard || !context.mounted) return;

    final isSuccess = await SchoolBoardsProvider.of(
      context,
      listen: false,
    ).addWithConfirmation(answer);
    if (!context.mounted) return;

    showSnackBar(
      context,
      message: isSuccess
          ? 'Centre de services scolaire ajoutée avec succès'
          : 'Échec de l\'ajout du Centre de services scolaire',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);
    final schoolBoards = _getSchoolBoards(context);
    final filteredSchoolIds = _filterSchoolIds(schoolBoards);

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: Text(
          authProvider.databaseAccessLevel == AccessLevel.superAdmin
              ? 'Liste des Centres de services scolaire'
              : 'Liste des écoles',
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
            icon: const Icon(Icons.search),
          ),
          if (authProvider.databaseAccessLevel >= AccessLevel.superAdmin)
            IconButton(
              onPressed: () => _showAddSchoolBoardDialog(context),
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
            ..._buildTiles(authProvider, schoolBoards, filteredSchoolIds),
            SizedBox(height: MediaQuery.of(context).size.height * 0.5)
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTiles(
    AuthProvider authProvider,
    List<SchoolBoard> schoolBoards,
    List<String>? filteredSchoolIds,
  ) {
    if (schoolBoards.isEmpty) {
      return [
        const Center(child: Text('Aucun Centre de services scolaire inscrit')),
      ];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin ||
      AccessLevel.schoolBoardAdmin ||
      AccessLevel.schoolAdmin ||
      AccessLevel.teacher =>
        schoolBoards
            .map(
              (schoolBoard) => SchoolBoardListTile(
                key: ValueKey(schoolBoard.id),
                schoolBoard: schoolBoard,
                elevation:
                    authProvider.databaseAccessLevel >= AccessLevel.superAdmin
                        ? null
                        : 0,
                filteredSchoolIds: filteredSchoolIds,
              ),
            )
            .toList(),
      AccessLevel.self || AccessLevel.invalid => throw Exception(
          'Wrong access level: ${authProvider.databaseAccessLevel}'),
    };
  }
}
