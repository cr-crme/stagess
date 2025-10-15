import 'package:enhanced_containers/enhanced_containers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stagess/screens/enterprise/enterprise_screen.dart';
import 'package:stagess/screens/enterprises_list/enterprises_list_screen.dart';
import 'package:stagess/screens/login/login_screen.dart';
import 'package:stagess/screens/my_account/my_account_screen.dart';
import 'package:stagess/screens/ref_sst/home_sst/home_sst_screen.dart';
import 'package:stagess/screens/ref_sst/incident_history/incident_history_screen.dart';
import 'package:stagess/screens/ref_sst/risks_list/risks_list_screen.dart';
import 'package:stagess/screens/ref_sst/specialization_list_risks_and_skills/specialization_list_screen.dart';
import 'package:stagess/screens/student/student_screen.dart';
import 'package:stagess/screens/students_list/students_list_screen.dart';
import 'package:stagess/screens/supervision_chart/supervision_chart_screen.dart';
import 'package:stagess/screens/supervision_chart/supervision_student_details.dart';
import 'package:stagess/screens/tasks_to_do/tasks_to_do_screen.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';

abstract class Screens {
  static const home = enterprisesList;

  static const login = LoginScreen.route;
  static const myAccountScreen = MyAccountScreen.route;

  static const tasksToDo = TasksToDoScreen.route;

  static const enterprisesList = EnterprisesListScreen.route;
  static const enterprise = EnterpriseScreen.route;

  static const supervisionChart = SupervisionChart.route;
  static const supervisionStudentDetails =
      SupervisionStudentDetailsScreen.route;

  static const studentsList = StudentsListScreen.route;
  static const student = StudentScreen.route;

  static const homeSst = HomeSstScreen.route;
  static const cardsSst = SstCardsScreen.route;
  static const incidentHistorySst = IncidentHistoryScreen.route;
  static const jobSst = SpecializationListScreen.route;

  static Map<String, String> params(id, {jobId}) {
    return {
      'id':
          (id is String)
              ? id
              : (id is ItemSerializable ? id.id : throw TypeError()),
      if (jobId != null)
        'jobId':
            (jobId is String)
                ? jobId
                : (jobId is ItemSerializable ? jobId.id : throw TypeError()),
    };
  }

  static Map<String, String> queryParams({pageIndex, editMode}) {
    return {
      if (pageIndex != null)
        'pageIndex':
            (pageIndex is String)
                ? pageIndex
                : (pageIndex is ItemSerializable
                    ? pageIndex.id
                    : throw TypeError()),
      if (editMode != null)
        'editMode':
            (editMode is String)
                ? editMode
                : (editMode is ItemSerializable
                    ? editMode.id
                    : throw TypeError()),
    };
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
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
      path: Screens.myAccountScreen,
      name: Screens.myAccountScreen,
      builder: (context, state) => const MyAccountScreen(),
    ),
    GoRoute(
      path: Screens.enterprisesList,
      name: Screens.enterprisesList,
      builder: (context, state) => const EnterprisesListScreen(),
      routes: [
        GoRoute(
          path: '${Screens.enterprise}_id=:id',
          name: Screens.enterprise,
          builder:
              (context, state) => EnterpriseScreen(
                id: state.pathParameters['id']!,
                pageIndex: int.parse(state.pathParameters['pageIndex'] ?? '0'),
              ),
        ),
      ],
    ),
    GoRoute(
      path: Screens.studentsList,
      name: Screens.studentsList,
      builder: (context, state) => const StudentsListScreen(),
      routes: [
        GoRoute(
          path: '${Screens.student}_id=:id',
          name: Screens.student,
          builder:
              (context, state) => StudentScreen(
                id: state.pathParameters['id']!,
                initialPage: int.parse(
                  state.uri.queryParameters['pageIndex'] ?? '0',
                ),
              ),
        ),
      ],
    ),
    GoRoute(
      path: Screens.supervisionChart,
      name: Screens.supervisionChart,
      builder: (context, state) => const SupervisionChart(),
      routes: [
        GoRoute(
          path: '${Screens.supervisionStudentDetails}/:id',
          name: Screens.supervisionStudentDetails,
          builder:
              (context, state) => SupervisionStudentDetailsScreen(
                studentId: state.pathParameters['id']!,
              ),
        ),
      ],
    ),
    GoRoute(
      path: Screens.tasksToDo,
      name: Screens.tasksToDo,
      builder: (context, state) => const TasksToDoScreen(),
    ),
    GoRoute(
      path: Screens.homeSst,
      name: Screens.homeSst,
      builder: (context, state) => const HomeSstScreen(),
      routes: [
        GoRoute(
          path: Screens.cardsSst,
          name: Screens.cardsSst,
          builder: (context, state) => const SstCardsScreen(),
        ),
        GoRoute(
          path: Screens.incidentHistorySst,
          name: Screens.incidentHistorySst,
          builder: (context, state) => const IncidentHistoryScreen(),
        ),
        GoRoute(
          path: '${Screens.jobSst}_id=:id',
          name: Screens.jobSst,
          builder: (context, state) {
            return SpecializationListScreen(id: state.pathParameters['id']!);
          },
        ),
      ],
    ),
  ],
);
