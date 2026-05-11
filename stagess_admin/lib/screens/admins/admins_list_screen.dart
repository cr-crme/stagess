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
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class AdminsListScreen extends StatelessWidget {
  const AdminsListScreen({super.key});

  static const route = '/admins_list';

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

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(
        title: const Text('Liste des administrateurs·trices'),
        actions: [
          if (authProvider.databaseAccessLevel >= AccessLevel.superAdmin)
            IconButton(
              onPressed: () => _showAddAdminDialog(context),
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
            ..._buildTiles(context, authProvider, schoolBoardAdmins),
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
                    ...schoolBoardEntry.value.map(
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
                ?.map((adminEntry) => AdminListTile(
                      key: ValueKey(adminEntry.id),
                      admin: adminEntry,
                    ))
                .toList() ??
            [],
    };
  }
}
