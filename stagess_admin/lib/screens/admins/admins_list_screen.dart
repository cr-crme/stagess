import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/admins/add_admin_dialog.dart';
import 'package:stagess_admin/screens/admins/admin_list_tile.dart';
import 'package:stagess_admin/screens/drawer/main_drawer.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/admin.dart';
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

  List<String>? _filterAdminIds(Map<SchoolBoard?, List<Admin>> schoolBoards) {
    final textToSearch = _searchController.text.toLowerCase().trim();
    if (!_showSearchBar || textToSearch.isEmpty) return null;

    final matchingAdminIds = <String>{};
    for (final admins in schoolBoards.values) {
      matchingAdminIds.addAll(admins
          .where((admin) => admin.fullName.toLowerCase().contains(textToSearch))
          .map((a) => a.id));
    }
    return matchingAdminIds.toList();
  }

  Map<SchoolBoard?, List<Admin>> _getAdmins(BuildContext context) {
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

    final admins = <SchoolBoard?, List<Admin>>{};
    for (final schoolBoard in schoolBoards) {
      admins[schoolBoard] = allAdmins
          .where((admin) => admin.schoolBoardId == schoolBoard.id)
          .toList();
    }

    if (AuthProvider.of(context, listen: false).databaseAccessLevel >=
        AccessLevel.superAdmin) {
      admins[null] =
          allAdmins.where((admin) => admin.schoolBoardId == '').toList();
    }

    return admins;
  }

  Future<void> _showAddAdminDialog(BuildContext context) async {
    final isConfirmed = await showDialog<bool>(
          barrierDismissible: false,
          context: context,
          builder: (context) => AddAdminDialog(),
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
          if (authProvider.databaseAccessLevel >= AccessLevel.superAdmin)
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
            ..._buildTiles(
                context, authProvider, schoolBoardAdmins, filteredAdminIds),
            SizedBox(height: MediaQuery.of(context).size.height * 0.5),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTiles(
    BuildContext context,
    AuthProvider authProvider,
    Map<SchoolBoard?, List<Admin>> schoolBoardAdmins,
    List<String>? filteredAdminIds,
  ) {
    if (schoolBoardAdmins.isEmpty) {
      return [
        const Center(
          child: Text('Aucun centre de services scolaire inscrit'),
        )
      ];
    }

    return switch (authProvider.databaseAccessLevel) {
      AccessLevel.superAdmin => schoolBoardAdmins.entries
          .where((entry) => entry.value.any((admin) =>
              filteredAdminIds == null || filteredAdminIds.contains(admin.id)))
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
                    ...schoolBoardEntry.value
                        .where((admin) =>
                            filteredAdminIds == null ||
                            filteredAdminIds.contains(admin.id))
                        .map(
                          (adminEntry) => AdminListTile(
                            key: ValueKey(adminEntry.id),
                            admin: adminEntry,
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
        schoolBoardAdmins.values.firstOrNull
                ?.where((admin) =>
                    filteredAdminIds == null ||
                    filteredAdminIds.contains(admin.id))
                .map((adminEntry) => AdminListTile(
                      key: ValueKey(adminEntry.id),
                      admin: adminEntry,
                    ))
                .toList() ??
            [],
    };
  }
}
