import 'package:flutter/material.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/profiles/admin_profile_list_tile.dart';
import 'package:stagess_common_flutter/widgets/profiles/teacher_profile_list_tile.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});
  static const String route = '/my-account';

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: false);

    final currentId = authProvider.currentId;
    if (currentId == null) {
      return ResponsiveService.scaffoldOf(
        context,
        appBar: ResponsiveService.appBarOf(
          context,
          title: const Text('Mon compte'),
        ),
        smallDrawer: MainDrawer.small,
        mediumDrawer: MainDrawer.medium,
        largeDrawer: MainDrawer.large,
        body: const Center(
          child: Text(
              'Aucun·e utilisateur·trice trouvé·e, assurez-vous d\'être connecté·e.'),
        ),
      );
    }

    final user = authProvider.isAdmin
        ? AdminsProvider.of(context, listen: false)
            .fetchData(id: currentId, fields: FetchableFields.all)
        : TeachersProvider.of(context, listen: false)
            .fetchData(id: currentId, fields: FetchableFields.all);

    return FutureBuilder(
      future: user,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ResponsiveService.scaffoldOf(
            context,
            appBar: ResponsiveService.appBarOf(
              context,
              title: const Text('Mon compte'),
            ),
            smallDrawer: MainDrawer.small,
            mediumDrawer: MainDrawer.medium,
            largeDrawer: MainDrawer.large,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final currentUser = authProvider.isAdmin
            ? AdminsProvider.of(context, listen: true)
                .where((admin) => admin.id == currentId)
                .firstOrNull
            : TeachersProvider.of(context, listen: true)
                .where((teacher) => teacher.id == currentId)
                .firstOrNull;

        return ResponsiveService.scaffoldOf(
          context,
          appBar: ResponsiveService.appBarOf(
            context,
            title: const Text('Mon compte'),
          ),
          smallDrawer: MainDrawer.small,
          mediumDrawer: MainDrawer.medium,
          largeDrawer: MainDrawer.large,
          body: (currentUser == null
              ? Center(
                  child: Text(
                      'Aucun·e utilisateur·trice trouvé·e, assurez-vous d\'être connecté·e.'))
              : authProvider.isAdmin
                  ? AdminProfileListTile(admin: currentUser as Admin)
                  : TeacherProfileListTile(teacher: currentUser as Teacher)),
        );
      },
    );
  }
}
