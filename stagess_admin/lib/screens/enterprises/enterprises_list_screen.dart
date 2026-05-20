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
import 'package:stagess_common_flutter/widgets/search.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class EnterprisesListScreen extends StatefulWidget {
  const EnterprisesListScreen({super.key});

  static const route = '/enterprises_list';

  @override
  State<EnterprisesListScreen> createState() => _EnterprisesListScreenState();
}

class _EnterprisesListScreenState extends State<EnterprisesListScreen> {
  bool _showSearchBar = false;
  late final _searchController = TextEditingController()
    ..addListener(() => setState(() {}));

  List<String>? _filterEnterpriseIds(
      Map<SchoolBoard, List<Enterprise>> schoolBoards) {
    final textToSearch = _searchController.text.toLowerCase().trim();
    if (!_showSearchBar || textToSearch.isEmpty) return null;

    final matchingEnterpriseIds = <String>{};
    for (final enterprises in schoolBoards.values) {
      for (final enterprise in enterprises) {
        if (enterprise.name.toLowerCase().contains(textToSearch)) {
          matchingEnterpriseIds.add(enterprise.id);
        }
      }
    }
    return matchingEnterpriseIds.toList();
  }

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
    final schoolBoardEnterprises = _getEnterprises(context);
    final filteredEnterpriseIds = _filterEnterpriseIds(schoolBoardEnterprises);

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: const Text('Liste des entreprises'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => _showAddEnterpriseDialog(context),
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
            ..._buildTiles(
                context, schoolBoardEnterprises, filteredEnterpriseIds),
            SizedBox(height: MediaQuery.of(context).size.height * 0.5),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTiles(
    BuildContext context,
    Map<SchoolBoard, List<Enterprise>> schoolBoardEnterprises,
    List<String>? filteredEnterpriseIds,
  ) {
    final authProvider = AuthProvider.of(context, listen: true);

    if (schoolBoardEnterprises.isEmpty) {
      return [const Center(child: Text('Aucune entreprise inscrite'))];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin => schoolBoardEnterprises.entries
          .where((entry) => entry.value.any((enterprise) =>
              filteredEnterpriseIds == null ||
              filteredEnterpriseIds.contains(enterprise.id)))
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
                    ...schoolBoardEntry.value
                        .where((enterprise) =>
                            filteredEnterpriseIds == null ||
                            filteredEnterpriseIds.contains(enterprise.id))
                        .map(
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
      AccessLevel.schoolBoardAdmin ||
      AccessLevel.schoolAdmin ||
      AccessLevel.teacher =>
        schoolBoardEnterprises.values.firstOrNull
                ?.where((enterprise) =>
                    filteredEnterpriseIds == null ||
                    filteredEnterpriseIds.contains(enterprise.id))
                .map(
                  (enterprise) => EnterpriseListTile(
                    key: ValueKey(enterprise.id),
                    enterprise: enterprise,
                  ),
                )
                .toList() ??
            [],
      AccessLevel.self || AccessLevel.invalid => throw Exception(
          'Wrong access level: ${authProvider.databaseAccessLevel}'),
    };
  }
}
