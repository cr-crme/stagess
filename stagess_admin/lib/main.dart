import 'package:crcrme_material_theme/crcrme_material_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:stagess_admin/extensions/auth_provider_extension.dart';
import 'package:stagess_admin/firebase_options.dart';
import 'package:stagess_admin/screens/router.dart';
import 'package:stagess_common/services/backend_helpers.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/inactivity_layout.dart';

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
  debugPrint('Welcome to Admin Stagess!');
  debugPrint(
    'We are connecting to the ${useDevDb ? 'development' : 'production'} database '
    'situated at ${BackendHelpers.backendIp}:${BackendHelpers.backendPort}, '
    '${BackendHelpers.useSsl ? '' : 'not '}using a secured connection',
  );

  final useMockers = false;
  final backendUri = BackendHelpers.backendConnectUri(useDevDatabase: useDevDb);

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  initializeDateFormatting('fr_CA');

  runApp(Home(useMockers: useMockers, backendUri: backendUri));
}

class Home extends StatelessWidget {
  const Home({super.key, required this.useMockers, required this.backendUri});

  final bool useMockers;
  final Uri backendUri;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(mockMe: useMockers, requiredAdminAccess: true),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SchoolBoardsProvider>(
          create: (context) =>
              SchoolBoardsProvider(uri: backendUri, mockMe: useMockers),
          update: (context, auth, previous) => previous!..initializeAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminsProvider>(
          create: (context) =>
              AdminsProvider(uri: backendUri, mockMe: useMockers),
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
          onGenerateTitle: (context) => 'Administration de Stagess',
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
