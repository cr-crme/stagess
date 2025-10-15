import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stagess/common/widgets/numbered_tablet.dart';
import 'package:stagess/router.dart';
import 'package:stagess/screens/tasks_to_do/tasks_to_do_screen.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _logOut(BuildContext context) async {
    await AuthProvider.of(context).signOut();
    if (!context.mounted) return;

    await SchoolBoardsProvider.of(context, listen: false).disconnect();
    if (!context.mounted) return;
    InternshipsProvider.of(context, listen: false).disconnect();
    if (!context.mounted) return;
    await Future.wait([
      SchoolBoardsProvider.of(context, listen: false).disconnect(),
      InternshipsProvider.of(context, listen: false).disconnect(),
      StudentsProvider.of(context, listen: false).disconnect(),
      EnterprisesProvider.of(context, listen: false).disconnect(),
      TeachersProvider.of(context, listen: false).disconnect(),
    ]);
    if (!context.mounted) return;

    // TODO Refresh the page when disconnecting
    await launchUrl(Uri.parse('${Uri.base.scheme}://${Uri.base.authority}'));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: false);

    return Drawer(
      width: iconOnly ? 120.0 : null,
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
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (authProvider.isFullySignedIn)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DrawerItem(
                          titleText: 'Entreprises',
                          icon: Icons.factory_rounded,
                          route: Screens.enterprisesList,
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                        _DrawerItem(
                          titleText: 'Mes élèves',
                          icon: Icons.face,
                          route: Screens.studentsList,
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                        _DrawerItem(
                          titleText: 'Tableau des supervisions',
                          icon: Icons.table_chart_rounded,
                          route: Screens.supervisionChart,
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                        _DrawerItem(
                          titleText: 'Tâches à réaliser',
                          icon: Icons.checklist,
                          route: Screens.tasksToDo,
                          trailing: NumberedTablet(
                            number: numberOfTasksToDo(context),
                            hideIfEmpty: true,
                            color: const Color.fromARGB(255, 33, 86, 176),
                          ),
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                        _DrawerItem(
                          titleText: 'Santé et Sécurité au PFAE',
                          icon: Icons.health_and_safety,
                          route: Screens.homeSst,
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                        _DrawerItem(
                          titleText: 'Mon compte',
                          icon: Icons.manage_accounts,
                          route: Screens.myAccountScreen,
                          iconOnly: iconOnly,
                          canPop: canPop,
                        ),
                      ],
                    ),
                  if (authProvider.isAuthenticatorSignedIn)
                    _DrawerItem(
                      titleText: 'Se déconnecter',
                      icon: Icons.logout,
                      onTap: () => _logOut(context),
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
    this.trailing,
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
  final Widget? trailing;
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
              isCurrentlySelectedTile
                  ? Theme.of(context).primaryColor.withAlpha(40)
                  : null,
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
          trailing: trailing,
        ),
      ),
    );
  }
}
