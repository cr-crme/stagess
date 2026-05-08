import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/drawer/main_drawer.dart';
import 'package:stagess_admin/screens/my_account/profile_list_tile.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});
  static const String route = '/my-account';

  @override
  Widget build(BuildContext context) {
    final currentId = AuthProvider.of(context, listen: false).teacherId;
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

    final coucou = AdminsProvider.of(context, listen: false)
        .fetchData(id: currentId, fields: FetchableFields.all);

    return FutureBuilder(
        future: coucou,
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

          final currentUser = AdminsProvider.of(context, listen: true)
              .where((admin) => admin.id == currentId)
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
                : ProfileListTile(admin: currentUser)),
          );
        });
  }
}
