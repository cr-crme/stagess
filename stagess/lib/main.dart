import 'dart:async';

import 'package:crcrme_material_theme/crcrme_material_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:stagess/common/extensions/auth_provider_extension.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess/router.dart';
import 'package:stagess_common/services/backend_helpers.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/inactivity_layout.dart';

// coverage:ignore-start
void main() async {
  // Setup logger to INFO
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '[${record.level.name}] ${record.time}: ${record.loggerName}: ${record.message}'
      '${record.error != null ? ' Error: ${record.error}' : ''}'
      '${record.stackTrace != null ? ' StackTrace: ${record.stackTrace}' : ''}',
    );
  });

  const useDevDb = bool.fromEnvironment(
    'STAGESS_USE_DEV_DB',
    defaultValue: false,
  );
  debugPrint('Welcome to Stagess!');
  debugPrint(
    'We are connecting to the ${useDevDb ? 'development' : 'production'} database '
    'situated at "${BackendHelpers.backendIp}:${BackendHelpers.backendPort}", '
    '${BackendHelpers.useSsl ? '' : 'not '}using a secured connection',
  );

  BugReporter.loggerSetup();
  const showDebugElements = true;
  const useMockers = false;
  final backendUri = BackendHelpers.backendConnectUri(useDevDatabase: useDevDb);
  final errorReportUri = BackendHelpers.backendUriForBugReport();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await ProgramInitializer.initialize(
        showDebugElements: showDebugElements,
        mockMe: useMockers,
      );

      runApp(StagessApp(useMockers: useMockers, backendUri: backendUri));
    },
    (error, stackTrace) =>
        BugReporter.report(error, stackTrace, errorReportUri: errorReportUri),
  );
}
// coverage:ignore-end

class StagessApp extends StatelessWidget {
  const StagessApp({
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
          create: (context) =>
              SchoolBoardsProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EnterprisesProvider>(
          create: (context) =>
              EnterprisesProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, InternshipsProvider>(
          create: (context) =>
              InternshipsProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TeachersProvider>(
          create: (context) =>
              TeachersProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, StudentsProvider>(
          create: (context) =>
              StudentsProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
      ],
      child: InactivityLayout(
        navigatorKey: rootNavigatorKey,
        timeout: const Duration(minutes: 10),
        gracePeriod: const Duration(seconds: 60),
        showGracePeriod: (context) async =>
            AuthProvider.of(context, listen: false).isFullySignedIn,
        onTimedout: (context) async {
          if (!AuthProvider.of(context, listen: false).isFullySignedIn) {
            return true;
          }
          await AuthProviderExtension.disconnectAll(
            context,
            showConfirmDialog: false,
          );
          return true;
        },
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
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
      ),
    );
  }
}
