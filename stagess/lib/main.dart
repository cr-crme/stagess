import 'dart:async';

import 'package:crcrme_material_theme/crcrme_material_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess/router.dart';
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
    useSsl: _useSsl,
    isDev: _useDevDatabase,
  );
  final errorReportUri = BackendHelpers.backendUriForBugReport(
    isLocal: _useLocalDatabase,
    useSsl: _useSsl,
  );

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await ProgramInitializer.initialize(
        showDebugElements: showDebugElements,
        mockMe: useMockers,
      );

      runApp(StageSsApp(useMockers: useMockers, backendUri: backendUri));
    },
    (error, stackTrace) =>
        BugReporter.report(error, stackTrace, errorReportUri: errorReportUri),
  );
}
// coverage:ignore-end

class StageSsApp extends StatelessWidget {
  const StageSsApp({
    super.key,
    this.useMockers = false,
    required this.backendUri,
  });

  final bool useMockers;
  final Uri backendUri;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(mockMe: useMockers),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SchoolBoardsProvider>(
          create:
              (context) =>
                  SchoolBoardsProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EnterprisesProvider>(
          create:
              (context) =>
                  EnterprisesProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, InternshipsProvider>(
          create:
              (context) =>
                  InternshipsProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TeachersProvider>(
          create:
              (context) =>
                  TeachersProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, StudentsProvider>(
          create:
              (context) =>
                  StudentsProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
      ],
      child: MaterialApp.router(
        onGenerateTitle: (context) => 'Stagess',
        theme: crcrmeMaterialTheme,
        routerConfig: router,
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
