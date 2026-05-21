import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/admins/admin_list_tile.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';

class SchoolAdminsCard extends StatelessWidget {
  const SchoolAdminsCard({
    super.key,
    required this.schoolId,
    required this.admins,
    required this.filteredAdminIds,
  });

  final String? schoolId;
  final List<Admin> admins;
  final List<String>? filteredAdminIds;

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);
    final school = schoolId == null
        ? null
        : SchoolBoardsProvider.of(context, listen: true)
            .schoolFromId(schoolId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8, bottom: 8),
          child: Text(
            school?.name ?? 'Centre de service scolaire',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (admins.isEmpty)
          Center(child: Text('Aucun administrateur·trice inscrit·e')),
        if (admins.isNotEmpty)
          ...admins
              .where((admin) =>
                  filteredAdminIds == null ||
                  filteredAdminIds!.contains(admin.id))
              .map((Admin admin) {
            final canDelete =
                authProvider.databaseAccessLevel > admin.accessLevel;
            final canEdit = canDelete || (authProvider.teacherId == admin.id);

            return AdminListTile(
              key: ValueKey(admin.id),
              admin: admin,
              canEdit: canEdit,
              canDelete: canDelete,
            );
          }),
      ],
    );
  }
}
