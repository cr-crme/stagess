import 'package:go_router/go_router.dart';
import 'package:stagess_admin/screens/admins/admins_list_screen.dart';
import 'package:stagess_admin/screens/enterprises/enterprises_list_screen.dart';
import 'package:stagess_admin/screens/internships/internships_list_screen.dart';
import 'package:stagess_admin/screens/login/login_screen.dart';
import 'package:stagess_admin/screens/school_boards/school_boards_list_screen.dart';
import 'package:stagess_admin/screens/students/students_list_screen.dart';
import 'package:stagess_admin/screens/teachers/teachers_list_screen.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';

abstract class Screens {
  static const home = teachersListScreen;

  static const login = LoginScreen.route;
  static const schoolBoardsListScreen = SchoolBoardsListScreen.route;
  static const adminsListScreen = AdminsListScreen.route;
  static const teachersListScreen = TeachersListScreen.route;
  static const studentsListScreen = StudentsListScreen.route;
  static const enterprisesListScreen = EnterprisesListScreen.route;
  static const internshipsListScreen = InternshipsListScreen.route;
}

// Keep a reference of the last requested state so when login is successful, we can redirect to it

final router = GoRouter(
  redirect:
      (context, state) =>
          AuthProvider.of(context).isFullySignedIn ? null : Screens.login,
  routes: [
    GoRoute(
      path: '/',
      redirect:
          (context, state) =>
              AuthProvider.of(context).isFullySignedIn ? null : Screens.login,
    ),
    GoRoute(
      path: Screens.login,
      name: Screens.login,
      builder: (context, state) => const LoginScreen(),
      redirect:
          (context, state) =>
              AuthProvider.of(context).isFullySignedIn
                  ? Screens.home
                  : Screens.login,
    ),
    GoRoute(
      path: Screens.schoolBoardsListScreen,
      name: Screens.schoolBoardsListScreen,
      builder: (context, state) => const SchoolBoardsListScreen(),
    ),
    GoRoute(
      path: Screens.adminsListScreen,
      name: Screens.adminsListScreen,
      builder: (context, state) => const AdminsListScreen(),
    ),
    GoRoute(
      path: Screens.teachersListScreen,
      name: Screens.teachersListScreen,
      builder: (context, state) => const TeachersListScreen(),
    ),
    GoRoute(
      path: Screens.studentsListScreen,
      name: Screens.studentsListScreen,
      builder: (context, state) => const StudentsListScreen(),
    ),
    GoRoute(
      path: Screens.enterprisesListScreen,
      name: Screens.enterprisesListScreen,
      builder: (context, state) => const EnterprisesListScreen(),
    ),
    GoRoute(
      path: Screens.internshipsListScreen,
      name: Screens.internshipsListScreen,
      builder: (context, state) => const InternshipsListScreen(),
    ),
  ],
);
