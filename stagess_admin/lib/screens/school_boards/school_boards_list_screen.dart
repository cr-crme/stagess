import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/drawer/main_drawer.dart';
import 'package:stagess_admin/screens/school_boards/add_school_board_dialog.dart';
import 'package:stagess_admin/screens/school_boards/school_board_list_tile.dart';
import 'package:stagess_admin/screens/school_boards/school_list_tile.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class SchoolBoardsListScreen extends StatelessWidget {
  const SchoolBoardsListScreen({super.key});

  static const route = '/schoolboards_list';

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
          : 'Échec de l\'ajout de la centre de services scolaire',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: Text(
          authProvider.databaseAccessLevel == AccessLevel.superAdmin
              ? 'Liste des centres de services scolaires'
              : 'Liste des écoles',
        ),
        actions: authProvider.databaseAccessLevel >= AccessLevel.superAdmin
            ? [
                IconButton(
                  onPressed: () => _showAddSchoolBoardDialog(context),
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
            ..._buildTiles(authProvider, _getSchoolBoards(context)),
            SizedBox(height: MediaQuery.of(context).size.height * 0.5)
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTiles(
    AuthProvider authProvider,
    List<SchoolBoard> schoolBoards,
  ) {
    if (schoolBoards.isEmpty) {
      return [
        const Center(child: Text('Aucun centre de services scolaire inscrit')),
      ];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin || AccessLevel.admin => schoolBoards
          .map(
            (schoolBoard) => SchoolBoardListTile(
              key: ValueKey(schoolBoard.id),
              schoolBoard: schoolBoard,
              elevation: authProvider.databaseAccessLevel == AccessLevel.admin
                  ? 0
                  : null,
            ),
          )
          .toList(),
      AccessLevel.teacher ||
      AccessLevel.invalid =>
        schoolBoards.firstOrNull?.schools
                .map(
                  (school) => SchoolListTile(
                    key: ValueKey(school.id),
                    school: school,
                    schoolBoard: schoolBoards.firstOrNull ?? SchoolBoard.empty,
                    canEdit: false,
                    canDelete: false,
                  ),
                )
                .toList() ??
            [],
    };
  }
}
