import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/drawer/main_drawer.dart';
import 'package:stagess_admin/screens/enterprises/add_enterprise_dialog.dart';
import 'package:stagess_admin/screens/enterprises/enterprise_list_tile.dart';
import 'package:stagess_admin/widgets/select_school_board_dialog.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class EnterprisesListScreen extends StatelessWidget {
  const EnterprisesListScreen({super.key});

  static const route = '/enterprises_list';

  Map<SchoolBoard, List<Enterprise>> _getEnterprises(BuildContext context) {
    final schoolBoards = SchoolBoardsProvider.of(context, listen: true);

    final allEnterprises = [...EnterprisesProvider.of(context, listen: true)];
    allEnterprises.sort((a, b) {
      final nameA = a.name.toLowerCase();
      final nameB = b.name.toLowerCase();
      return nameA.compareTo(nameB);
    });

    final enterprises = <SchoolBoard, List<Enterprise>>{};
    for (final schoolBoard in schoolBoards) {
      enterprises[schoolBoard] = allEnterprises
          .where((enterprise) => enterprise.schoolBoardId == schoolBoard.id)
          .toList();
    }
    return enterprises;
  }

  Future<void> _showAddEnterpriseDialog(BuildContext context) async {
    final schoolBoard = await showSelectSchoolBoardDialog(context);
    if (schoolBoard == null || !context.mounted) return;

    final answer = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AddEnterpriseDialog(schoolBoard: schoolBoard),
    );
    if (answer is! Enterprise || !context.mounted) return;

    final isSuccess = await EnterprisesProvider.of(
      context,
      listen: false,
    ).addWithConfirmation(answer);
    if (!context.mounted) return;

    showSnackBar(
      context,
      message: isSuccess
          ? 'Entreprise ajoutée avec succès'
          : 'Échec de l\'ajout du l\'entreprise',
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolBoards = _getEnterprises(context);

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: const Text('Liste des entreprises'),
        actions: [
          IconButton(
            onPressed: () => _showAddEnterpriseDialog(context),
            icon: Icon(Icons.add),
          ),
        ],
      ),
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._buildTiles(context, schoolBoards),
            SizedBox(height: MediaQuery.of(context).size.height * 0.5),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTiles(
    BuildContext context,
    Map<SchoolBoard, List<Enterprise>> schoolBoardEnterprises,
  ) {
    final authProvider = AuthProvider.of(context, listen: true);

    if (schoolBoardEnterprises.isEmpty) {
      return [const Center(child: Text('Aucune entreprise inscrite'))];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin => schoolBoardEnterprises.entries
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
                    ...schoolBoardEntry.value.map(
                      (enterprise) => EnterpriseListTile(
                        key: ValueKey(enterprise.id),
                        enterprise: enterprise,
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
        schoolBoardEnterprises.values.firstOrNull
                ?.map(
                  (enterprise) => EnterpriseListTile(
                    key: ValueKey(enterprise.id),
                    enterprise: enterprise,
                  ),
                )
                .toList() ??
            [],
    };
  }
}
