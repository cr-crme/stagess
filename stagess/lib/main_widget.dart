import 'dart:async';

import 'package:crcrme_material_theme/crcrme_material_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:stagess/common/widgets/dialogs/job_creator_dialog.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job_list.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common/services/backend_helpers.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

const _useLocalDatabase = bool.fromEnvironment(
  'STAGESS_WEB_USE_LOCAL_DB',
  defaultValue: false,
);
const _useSsl = bool.fromEnvironment('STAGESS_WEB_USE_SSL', defaultValue: true);
const _useDevDatabase = bool.fromEnvironment(
  'STAGESS_WEB_USE_DEV_DB',
  defaultValue: false,
);

// coverage:ignore-start
void main() async {
  debugPrint('Welcome to Stagess!');
  debugPrint('Is using local database: $_useLocalDatabase');
  debugPrint('Is using SSL: $_useSsl');
  debugPrint('Is using dev database: $_useDevDatabase');

  BugReporter.loggerSetup();
  const showDebugElements = true;
  const useMockers = false;
  final backendUri = BackendHelpers.backendUri(
    isLocal: _useLocalDatabase,
    useProxy: !_useLocalDatabase,
    useSsl: _useSsl,
    isDev: _useDevDatabase,
  );
  final errorReportUri = BackendHelpers.backendUriForBugReport(
    isLocal: _useLocalDatabase,
    useProxy: !_useLocalDatabase,
    useSsl: _useSsl,
  );

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await ProgramInitializer.initialize(
        showDebugElements: showDebugElements,
        mockMe: useMockers,
      );

      runApp(StagessApp(backendUri: backendUri));
    },
    (error, stackTrace) =>
        BugReporter.report(error, stackTrace, errorReportUri: errorReportUri),
  );
}
// coverage:ignore-end

class StagessApp extends StatelessWidget {
  const StagessApp({super.key, required this.backendUri});

  final bool useMockers = true;
  final Uri backendUri;

  Address get dummyAddress => Address(
    civicNumber: 100,
    street: 'Wunderbar',
    apartment: 'A',
    city: 'Wonderland',
    postalCode: 'H0H 0H0',
  );

  PhoneNumber get dummyPhoneNumber => PhoneNumber.fromString('800-555-5555');

  Person get dummyPerson => Person(
    firstName: 'Jeanne',
    middleName: 'Kathlin',
    lastName: 'Doe',
    address: dummyAddress,
    dateBirth: DateTime(2000, 1, 1),
    email: 'jeanne.k.doe@test.com',
    phone: dummyPhoneNumber,
  );

  Enterprise get dummyEnterprise {
    final jobs = JobList();
    return Enterprise(
      schoolBoardId: 'schoolBoardId',
      id: 'enterpriseId',
      name: 'Not named',
      status: EnterpriseStatus.active,
      activityTypes: {},
      recruiterId: 'Nobody',
      jobs: jobs,
      contact: dummyPerson,
      address: dummyAddress,
      headquartersAddress: dummyAddress,
    );
  }

  School get dummySchool => School(
    id: 'MockedSchoolId',
    name: 'Mocked School',
    address: dummyAddress,
    phone: dummyPhoneNumber,
  );

  SchoolBoard get dummySchoolBoard => SchoolBoard(
    id: 'MockedSchoolBoardId',
    name: 'Mocked School Board',
    logo: null,
    cnesstNumber: '123456789',
    schools: [dummySchool],
  );

  @override
  Widget build(BuildContext context) {
    final authProvided = AuthProvider(mockMe: useMockers);
    final schoolBoardProvided = SchoolBoardsProvider(
      uri: backendUri,
      mockMe: useMockers,
    );
    final enterprisesProvided = EnterprisesProvider(
      uri: backendUri,
      mockMe: useMockers,
    );
    final internshipsProvided = InternshipsProvider(
      uri: backendUri,
      mockMe: useMockers,
    );
    final teachersProvided = TeachersProvider(
      uri: backendUri,
      mockMe: useMockers,
    );
    final studentsProvided = StudentsProvider(
      uri: backendUri,
      mockMe: useMockers,
    );

    authProvided.schoolBoardId = 'MockedSchoolBoardId';
    authProvided.schoolId = 'MockedSchoolId';
    authProvided.teacherId = 'MockedTeacherId';

    schoolBoardProvided.initializeAuth(authProvided);
    enterprisesProvided.initializeAuth(authProvided);
    internshipsProvided.initializeAuth(authProvided);
    teachersProvided.initializeAuth(authProvided);
    studentsProvided.initializeAuth(authProvided);

    schoolBoardProvided.add(dummySchoolBoard);

    final enterprise = dummyEnterprise;
    enterprisesProvided.add(enterprise);

    final widgetToTest = JobCreatorDialog(enterprise: enterprise);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => authProvided),
        ChangeNotifierProvider(create: (context) => schoolBoardProvided),
        ChangeNotifierProvider(create: (context) => enterprisesProvided),
        ChangeNotifierProvider(create: (context) => internshipsProvided),
        ChangeNotifierProvider(create: (context) => teachersProvided),
        ChangeNotifierProvider(create: (context) => studentsProvided),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => 'Stagess',
        theme: crcrmeMaterialTheme,
        home: widgetToTest,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'CA')],
      ),
    );
  }
}

// import 'dart:math';

// import 'package:aad_oauth/aad_oauth.dart';
// import 'package:aad_oauth/model/config.dart';
// import 'package:flutter/material.dart';

// void main() async {
//   final navigatorKey = GlobalKey<NavigatorState>();

//   runApp(MaterialApp(
//     navigatorKey: navigatorKey,
//     home: Scaffold(
//       body: MicrosoftLoginWeb(navigatorKey: navigatorKey),
//     ),
//   ));
// }

// class MicrosoftLoginWeb extends StatefulWidget {
//   const MicrosoftLoginWeb({super.key, required this.navigatorKey});

//   final GlobalKey<NavigatorState> navigatorKey;
//   static const String tenant = 'd9e685e2-1e5c-4bb8-bbae-e8ab8ba845a9';
//   static const String clientId = 'dd26538f-ec32-49d9-8625-ebe2bf1ef53a';
//   static const String redirectUri = 'http://localhost:3456/auth';
//   static const String scope = 'openid profile'; //'email offline_access';
//   static const String responseType = 'code';
//   static const String responseMode = 'post_form';

//   @override
//   State<MicrosoftLoginWeb> createState() => _MicrosoftLoginWebState();
// }

// class _MicrosoftLoginWebState extends State<MicrosoftLoginWeb> {
//   final state = Random().nextInt(1000000).toString();
//   late final oauth = AadOAuth(Config(
//     tenant: MicrosoftLoginWeb.tenant,
//     clientId: MicrosoftLoginWeb.clientId,
//     scope: MicrosoftLoginWeb.scope,
//     redirectUri: MicrosoftLoginWeb.redirectUri,
//     webUseRedirect: true,
//     navigatorKey: widget.navigatorKey,
//     state: state,
//     responseMode: 'form_post',
//     loginHint: 'benjamin.michaud@partenaire.cssda.ca',
//   ));

//   Future<String?> _login() async {
//     final result = await oauth.login();
//     return result.fold(
//       (l) {
//         debugPrint('Login Failed: $l');
//         return null;
//       },
//       (r) {
//         debugPrint('Login Successful: $r');
//         return r.accessToken;
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: _login,
//       child: const Text('Login with Microsoft'),
//     );
//   }
// }
