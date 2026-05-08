import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/drawer/main_drawer.dart';
import 'package:stagess_admin/screens/my_account/profile_list_tile.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});
  static const String route = '/my-account';

  @override
  Widget build(BuildContext context) {
    final currentUser = AdminsProvider.of(context)
        .where(
          (admin) =>
              admin.id == AuthProvider.of(context, listen: true).teacherId,
        )
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
                  'Aucun utilisateur trouvé, assurez-vous d\'être connecté·e.'))
          : ProfileListTile(admin: currentUser)),
    );
  }
}
