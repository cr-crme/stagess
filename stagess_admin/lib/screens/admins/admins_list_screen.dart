import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/admins/add_admin_dialog.dart';
import 'package:stagess_admin/screens/admins/school_admins_card.dart';
import 'package:stagess_admin/screens/drawer/main_drawer.dart';
import 'package:stagess_admin/widgets/select_school_board_dialog.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/search.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class AdminsListScreen extends StatefulWidget {
  const AdminsListScreen({super.key});

  static const route = '/admins_list';

  @override
  State<AdminsListScreen> createState() => _AdminsListScreenState();
}

class _AdminsListScreenState extends State<AdminsListScreen> {
  bool _showSearchBar = false;
  late final _searchController = TextEditingController()
    ..addListener(() => setState(() {}));

  List<String>? _filterAdminIds(
      Map<SchoolBoard?, Map<School?, List<Admin>>> schoolBoards) {
    final textToSearch = _searchController.text.toLowerCase().trim();
    if (!_showSearchBar || textToSearch.isEmpty) return null;

    final matchingAdminIds = <String>{};
    for (final adminsBySchool in schoolBoards.values) {
      for (final admins in adminsBySchool.values) {
        matchingAdminIds.addAll(admins
            .where(
                (admin) => admin.fullName.toLowerCase().contains(textToSearch))
            .map((a) => a.id));
      }
    }
    return matchingAdminIds.toList();
  }

  Map<SchoolBoard?, Map<School?, List<Admin>>> _getAdmins(
      BuildContext context) {
    final allAdmins = [...AdminsProvider.of(context, listen: true)];
    allAdmins.sort((a, b) {
      final lastNameA = a.lastName.toLowerCase();
      final lastNameB = b.lastName.toLowerCase();
      var comparison = lastNameA.compareTo(lastNameB);
      if (comparison != 0) return comparison;

      final firstNameA = a.firstName.toLowerCase();
      final firstNameB = b.firstName.toLowerCase();
      return firstNameA.compareTo(firstNameB);
    });

    final schoolBoards = SchoolBoardsProvider.of(context);

    final admins = <SchoolBoard?, Map<School?, List<Admin>>>{};
    for (final schoolBoard in schoolBoards) {
      admins[schoolBoard] = {};
      for (final school in [null, ...schoolBoard.schools]) {
        admins[schoolBoard]![school] = allAdmins
            .where((admin) =>
                admin.schoolBoardId == schoolBoard.id &&
                admin.schoolId == (school?.id ?? ''))
            .toList();
      }
    }

    if (AuthProvider.of(context, listen: false).databaseAccessLevel >=
        AccessLevel.superAdmin) {
      admins[null] = {};
      admins[null]![null] =
          allAdmins.where((admin) => admin.schoolBoardId == '').toList();
    }

    return admins;
  }

  Future<void> _showAddAdminDialog(BuildContext context) async {
    final schoolBoard = await showSelectSchoolBoardDialog(context);
    if (schoolBoard == null || !context.mounted) return;

    final isConfirmed = await showDialog<bool>(
          barrierDismissible: false,
          context: context,
          builder: (context) => AddAdminDialog(schoolBoardId: schoolBoard.id),
        ) ??
        false;
    if (!context.mounted) return;

    showSnackBar(
      context,
      message: isConfirmed
          ? 'Administrateur·trice ajouté·e avec succès'
          : 'Aucun administrateur·trice n\'a été ajouté·e',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);
    final schoolBoardAdmins = _getAdmins(context);
    final filteredAdminIds = _filterAdminIds(schoolBoardAdmins);

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: const Text('Liste des administrateurs·trices'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
            icon: const Icon(Icons.search),
          ),
          if (authProvider.databaseAccessLevel >= AccessLevel.schoolBoardAdmin)
            IconButton(
              onPressed: () => _showAddAdminDialog(context),
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
            ..._buildTiles(context, schoolBoardAdmins, filteredAdminIds),
            SizedBox(height: MediaQuery.of(context).size.height * 0.5),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTiles(
    BuildContext context,
    Map<SchoolBoard?, Map<School?, List<Admin>>> schoolBoardAdmins,
    List<String>? filteredAdminIds,
  ) {
    final authProvider = AuthProvider.of(context, listen: true);

    if (schoolBoardAdmins.isEmpty) {
      return [
        const Center(child: Text('Aucun administrateur·trice inscrit·e'))
      ];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin => schoolBoardAdmins.entries
          .where((element) => element.value.values.any((admins) =>
              filteredAdminIds == null ||
              admins.any((admin) => filteredAdminIds.contains(admin.id))))
          .map(
            (schoolBoardEntry) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedExpandingCard(
                header: (ctx, isExpanded) => Text(
                  schoolBoardEntry.key?.name ?? 'Super administrateurs·trices',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(color: Colors.black),
                ),
                elevation: 0.0,
                initialExpandedState: true,
                child: Column(
                  children: [
                    ...schoolBoardEntry.value.entries
                        .where((schoolEntry) => schoolEntry.value.any((admin) =>
                            filteredAdminIds == null ||
                            filteredAdminIds.contains(admin.id)))
                        .map(
                          (schoolEntry) => SchoolAdminsCard(
                            schoolId: schoolEntry.key?.id,
                            admins: schoolEntry.value,
                            filteredAdminIds: filteredAdminIds,
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
        schoolBoardAdmins.values.firstOrNull?.entries
                .where((schoolEntry) => schoolEntry.value.any((admin) =>
                    filteredAdminIds == null ||
                    filteredAdminIds.contains(admin.id))) // Filter schools
                .map((adminEntry) => SchoolAdminsCard(
                      schoolId: adminEntry.key?.id,
                      admins: adminEntry.value,
                      filteredAdminIds: filteredAdminIds,
                    ))
                .toList() ??
            [],
    };
  }
}
