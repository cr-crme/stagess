import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stagess_admin/dummy_data.dart';
import 'package:stagess_admin/dummy_data_tutorial.dart';
import 'package:stagess_admin/extensions/auth_provider_extension.dart';
import 'package:stagess_admin/screens/router.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    super.key,
    this.showTitle = true,
    this.iconOnly = false,
    this.canPop = true,
    this.roundedCorners = true,
  });

  static MainDrawer get small => const MainDrawer();
  static MainDrawer get medium =>
      const MainDrawer(iconOnly: true, canPop: false, roundedCorners: false);
  static MainDrawer get large =>
      const MainDrawer(canPop: false, roundedCorners: false);

  final bool showTitle;
  final bool iconOnly;
  final bool canPop;
  final bool roundedCorners;

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: true);

    return Drawer(
      width: iconOnly ? 80.0 : null,
      shape:
          roundedCorners
              ? null
              : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
      child: Scaffold(
        appBar:
            showTitle
                ? AppBar(
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.menu),
                      SizedBox(width: 8.0),
                      if (!iconOnly) const Text('Menu'),
                    ],
                  ),
                  automaticallyImplyLeading: false,
                )
                : null,
        body: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (authProvider.isAuthenticatorSignedIn &&
                  !authProvider.isFullySignedIn)
                _DrawerItem(
                  titleText: 'Se déconnecter',
                  icon: Icons.logout,
                  onTap: () => AuthProviderExtension.disconnectAll(context),
                  iconOnly: iconOnly,
                  canPop: canPop,
                ),
              if (authProvider.isFullySignedIn)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        _DrawerItem(
                          titleText: 'Écoles',
                          icon: Icons.school,
                          route: Screens.schoolBoardsListScreen,
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                        if (authProvider.databaseAccessLevel >=
                            AccessLevel.superAdmin)
                          _DrawerItem(
                            titleText: 'Administrateurs·trices',
                            icon: Icons.admin_panel_settings,
                            route: Screens.adminsListScreen,
                            iconOnly: iconOnly,
                            canPop: canPop,
                          ),
                        _DrawerItem(
                          titleText: 'Enseignant·e·s',
                          icon: Icons.groups_3_outlined,
                          route: Screens.teachersListScreen,
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                        _DrawerItem(
                          titleText: 'Élèves',
                          icon: Icons.face,
                          route: Screens.studentsListScreen,
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                        _DrawerItem(
                          titleText: 'Entreprises',
                          icon: Icons.factory,
                          route: Screens.enterprisesListScreen,
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                        _DrawerItem(
                          titleText: 'Stages',
                          icon: Icons.assignment,
                          route: Screens.internshipsListScreen,
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                        _DrawerItem(
                          titleText: 'Se déconnecter',
                          icon: Icons.logout,
                          onTap:
                              () =>
                                  AuthProviderExtension.disconnectAll(context),
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                      ],
                    ),
                  ),
                ),
              if (authProvider.isFullySignedIn &&
                  authProvider.databaseAccessLevel == AccessLevel.superAdmin)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DrawerItem(
                      titleText: 'Réinitialiser la base de données (Tutoriel)',
                      icon: Icons.restore_from_trash_outlined,
                      onTap: () async {
                        await resetDummyDataTutorial(context);
                        if (context.mounted && canPop) Navigator.pop(context);
                      },
                      tileColor: Colors.red,
                      iconOnly: iconOnly,
                      canPop: canPop,
                    ),
                    _DrawerItem(
                      titleText: 'Réinitialiser la base de données (Dev)',
                      icon: Icons.restore_from_trash_outlined,
                      onTap: () async {
                        await resetDummyData(context);
                        if (context.mounted && canPop) Navigator.pop(context);
                      },
                      tileColor: Colors.red,
                      iconOnly: iconOnly,
                      canPop: canPop,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.titleText,
    required this.icon,
    this.route,
    this.onTap,
    this.tileColor,
    required this.iconOnly,
    required this.canPop,
  }) : assert(
         (route != null || onTap != null) && (route == null || onTap == null),
         'One parameter has to be null while the other one is not.',
       );

  final String? route;
  final IconData icon;
  final String titleText;
  final void Function()? onTap;
  final Color? tileColor;
  final bool iconOnly;
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    final isCurrentlySelectedTile =
        ModalRoute.of(context)!.settings.name == route;

    final onPressed =
        onTap ??
        () {
          if (isCurrentlySelectedTile && canPop) Navigator.pop(context);
          GoRouter.of(context).goNamed(route!);
        };

    final leadingIcon = Icon(
      icon,
      color:
          isCurrentlySelectedTile
              ? Theme.of(context).primaryColor
              : Colors.black54,
    );

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color:
              tileColor ??
              (isCurrentlySelectedTile
                  ? Theme.of(context).primaryColor.withAlpha(40)
                  : null),
        ),
        child: ListTile(
          onTap: onPressed,
          leading: leadingIcon,
          title:
              iconOnly
                  ? null
                  : Text(
                    titleText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
        ),
      ),
    );
  }
}
