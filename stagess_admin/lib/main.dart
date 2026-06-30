import 'package:crcrme_material_theme/crcrme_material_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:stagess_admin/extensions/auth_provider_extension.dart';
import 'package:stagess_admin/firebase_options.dart';
import 'package:stagess_admin/screens/router.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/services/backend_helpers.dart';
import 'package:stagess_common_flutter/helpers/program_helpers.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/boot_loader_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/screens/connection_error_screen.dart';
import 'package:stagess_common_flutter/screens/in_maintenance_screen.dart';
import 'package:stagess_common_flutter/screens/wrong_version_screen.dart';
import 'package:stagess_common_flutter/widgets/inactivity_layout.dart';
import 'package:stagess_common_flutter/widgets/single_instance_manager/single_instance_manager.dart';

// TODO Fix reset link not appearing on admin

const useDevDb =
    bool.fromEnvironment('STAGESS_USE_DEV_DB', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ProgramInitializer.configureLogger(
      showLogs:
          const bool.fromEnvironment('STAGESS_SHOW_LOGS', defaultValue: false));

  // Configuration
  final inMaintenanceMode = const bool.fromEnvironment(
      'STAGESS_MAINTENANCE_MODE',
      defaultValue: false);
  const useMockers =
      bool.fromEnvironment('STAGESS_USE_MOCKERS', defaultValue: false);
  final backendUri = BackendHelpers.backendConnectUri(useDevDatabase: useDevDb);
  final isBackendCompatible = await ProgramInitializer.isBackendCompatible();

  // Say hello
  debugPrint(
      'Bienvenue à l\'administration de Stagess, version ${CommunicationProtocol.version}!');
  if (isBackendCompatible == null) {
    debugPrint(
        'Impossible de vérifier la compatibilité avec le serveur. Assurez-vous d\'être connecté à Internet.');
  } else if (!isBackendCompatible) {
    debugPrint(
        'Attention, cette version est incompatible avec celle du serveur. '
        'Veuillez rafraichir la page pour mettre à jour votre application.');
  }
  debugPrint(
    'Nous nous connectons à la base de données ${useDevDb ? 'de développement' : 'de production'} '
    'située à "${BackendHelpers.backendIp}:${BackendHelpers.backendPort}", '
    'en utilisant une connexion ${BackendHelpers.useSsl ? '' : 'non-'}sécurisée',
  );

  if (inMaintenanceMode ||
      isBackendCompatible == null ||
      !isBackendCompatible) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => inMaintenanceMode
          ? 'Stagess en maintenance'
          : (isBackendCompatible == null
              ? 'Impossible de se connecter au serveur'
              : 'Version incorrecte de Stagess'),
      theme: crcrmeMaterialTheme,
      home: inMaintenanceMode
          ? const InMaintenanceScreen()
          : (isBackendCompatible == null
              ? const ConnectionErrorScreen()
              : const WrongVersionScreen()),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'CA')],
    ));
  } else {
    // Normal app initialization
    await ProgramInitializer.initialize(
      firebaseOptions:
          useMockers ? null : DefaultFirebaseOptions.currentPlatform,
      useActivitySectorsService: true,
      useRiskDataFileService: true,
      useQuestionFileService: true,
      useTileProvider: true,
      useReverseGeocodingProvider: true,
    );
    runApp(StagessAdministrationApp(
        useMockers: useMockers, backendUri: backendUri));
  }
}

class StagessAdministrationApp extends StatelessWidget {
  const StagessAdministrationApp(
      {super.key, required this.useMockers, required this.backendUri});

  final bool useMockers;
  final Uri backendUri;

  @override
  Widget build(BuildContext context) {
    return SingleInstanceManager(
      isNotAllowedChild: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => 'Stagess',
        theme: crcrmeMaterialTheme,
        home: Scaffold(
          body: Center(
            child: Text(
                'Une seule page de Stagess ne peut être ouverte à la fois.\n'
                'Veuillez fermer les autres onglets ou fenêtres et rafraîchir cette page.'),
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'CA')],
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) =>
                AuthProvider(mockMe: useMockers, requiredAdminAccess: true),
          ),
          ChangeNotifierProxyProvider<AuthProvider, BootLoaderProvider>(
            create: (context) =>
                BootLoaderProvider(uri: backendUri, mockMe: useMockers),
            update: (context, auth, previous) =>
                previous!..initializeAuth(auth),
          ),
          ChangeNotifierProxyProvider<AuthProvider, SchoolBoardsProvider>(
            create: (context) =>
                SchoolBoardsProvider(uri: backendUri, mockMe: useMockers),
            update: (context, auth, previous) =>
                previous!..initializeAuth(auth),
          ),
          ChangeNotifierProxyProvider<AuthProvider, AdminsProvider>(
            create: (context) =>
                AdminsProvider(uri: backendUri, mockMe: useMockers),
            update: (context, auth, previous) =>
                previous!..initializeAuth(auth),
          ),
          ChangeNotifierProxyProvider<AuthProvider, TeachersProvider>(
            create: (context) =>
                TeachersProvider(uri: backendUri, mockMe: useMockers),
            update: (context, auth, previous) =>
                previous!..initializeAuth(auth),
          ),
          ChangeNotifierProxyProvider<AuthProvider, StudentsProvider>(
            create: (context) =>
                StudentsProvider(uri: backendUri, mockMe: useMockers),
            update: (context, auth, previous) =>
                previous!..initializeAuth(auth),
          ),
          ChangeNotifierProxyProvider<AuthProvider, EnterprisesProvider>(
            create: (context) =>
                EnterprisesProvider(uri: backendUri, mockMe: useMockers),
            update: (context, auth, previous) =>
                previous!..initializeAuth(auth),
          ),
          ChangeNotifierProxyProvider<AuthProvider, InternshipsProvider>(
            create: (context) =>
                InternshipsProvider(uri: backendUri, mockMe: useMockers),
            update: (context, auth, previous) =>
                previous!..initializeAuth(auth),
          ),
        ],
        child: InactivityLayout(
          navigatorKey: rootNavigatorKey,
          timeout: const Duration(minutes: 10),
          gracePeriod: const Duration(seconds: 60),
          showGracePeriod: (context) async =>
              AuthProvider.of(context, listen: false).isFullySignedIn,
          onTimedOut: _disconnect,
          onDisconnect: _disconnect,
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
      ),
    );
  }
}

Future<bool> _disconnect(BuildContext context) async {
  if (!AuthProvider.of(context, listen: false).isFullySignedIn) {
    return true;
  }
  await AuthProviderExtension.disconnectAll(
    context,
    showConfirmDialog: false,
  );
  return true;
}
