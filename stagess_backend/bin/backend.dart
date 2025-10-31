import 'dart:io';

import 'package:firebase_admin/firebase_admin.dart';
import 'package:firebase_admin/src/auth/credential.dart';
import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:stagess_backend/repositories/admins_repository.dart';
import 'package:stagess_backend/repositories/enterprises_repository.dart';
import 'package:stagess_backend/repositories/internships_repository.dart';
import 'package:stagess_backend/repositories/school_boards_repository.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/repositories/students_repository.dart';
import 'package:stagess_backend/repositories/teachers_repository.dart';
import 'package:stagess_backend/server/connexions.dart';
import 'package:stagess_backend/server/database_manager.dart';
import 'package:stagess_backend/server/http_request_handler.dart';
import 'package:stagess_backend/utils/network_rate_limiter.dart';
import 'package:stagess_common/services/backend_helpers.dart';

final _logger = Logger('BackendServer');

enum DatabaseBackend {
  mariadb,
  mysql,
  mock;

  static DatabaseBackend fromString(String value) {
    return switch (value.toLowerCase()) {
      'mariadb' => DatabaseBackend.mariadb,
      'mysql' => DatabaseBackend.mysql,
      'mock' => DatabaseBackend.mock,
      _ => throw ArgumentError('Unknown database backend: $value'),
    };
  }
}

final _databaseBackend =
    DatabaseBackend.fromString(_getFromEnvironment('STAGESS_DATABASE_BACKEND'));
final _backendIp = InternetAddress.anyIPv4;
final _backendPort = BackendHelpers.backendPort;
final _devSettings = ConnectionSettings(
  host: 'localhost',
  port: int.parse(_getFromEnvironment('STAGESS_DATABASE_DEV_PORT')),
  user: _getFromEnvironment('STAGESS_DATABASE_DEV_USER'),
  password: _getFromEnvironment('STAGESS_DATABASE_DEV_PASSWORD'),
  db: _getFromEnvironment('STAGESS_DATABASE_DEV_NAME'),
);
final _productionSettings = ConnectionSettings(
  host: 'localhost',
  port: int.parse(_getFromEnvironment('STAGESS_DATABASE_PRODUCTION_PORT')),
  user: _getFromEnvironment('STAGESS_DATABASE_PRODUCTION_USER'),
  password: _getFromEnvironment('STAGESS_DATABASE_PRODUCTION_PASSWORD'),
  db: _getFromEnvironment('STAGESS_DATABASE_PRODUCTION_NAME'),
);

void main() async {
  // Set up logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Connect to the authentication service
  FirebaseAdmin.instance.initializeApp(
    AppOptions(
      credential:
          ServiceAccountCredential('backendFirebaseServiceAccountKey.json'),
    ),
  );
  // Get the Firebase API key from the environment variable
  final firebaseApiKey = _getFromEnvironment('STAGESS_FIREBASE_WEB_API_KEY');

  // Create an HTTP server listening on localhost:_backendPort
  const useSecure = bool.fromEnvironment('STAGESS_USE_SSL', defaultValue: true);
  print(useSecure);
  final server = await _bindServer(useSecure: useSecure);

  _logger.info(
      'Server running on ${useSecure ? 'https' : 'http'}://${_backendIp.address}:$_backendPort/');
  _logger.info('Using database backend: ${_databaseBackend.name}');

  final devConnexions = await _connectDatabase(
    databaseBackend: _databaseBackend,
    firebaseApiKey: firebaseApiKey,
    settings: _devSettings,
    skipLog: true,
  );

  final productionConnexions = await _connectDatabase(
    databaseBackend: _databaseBackend,
    firebaseApiKey: firebaseApiKey,
    settings: _productionSettings,
    skipLog: false,
  );

  _logger.info('Server ready and waiting for requests...');
  final requestHandler = HttpRequestHandler(
      devConnexions: devConnexions, productionConnexions: productionConnexions);

  final rateLimiter =
      NetworkRateLimiter(maxRequests: 50, duration: Duration(minutes: 1));

  server.listen(
    (HttpRequest request) =>
        requestHandler.answer(request, rateLimiter: rateLimiter),
    onError: (error, stackTrace) =>
        _logger.severe('Error in server: $error\n$stackTrace'),
    cancelOnError: false,
  );

  if (_databaseBackend == DatabaseBackend.mysql) {
    await (devConnexions.database.sqlInterface.connection as MySqlConnection)
        .close();
    await (productionConnexions.database.sqlInterface.connection
            as MySqlConnection)
        .close();
  }
}

String _getFromEnvironment(String key) {
  final value = Platform.environment[key];
  if (value == null || value.isEmpty) {
    _logger.severe('$key environment variable is not set.');
    exit(1);
  }
  return value;
}

Future<HttpServer> _bindServer({required bool useSecure}) async {
  if (useSecure) {
    final certPem = _getFromEnvironment('STAGESS_CERT_PEM');
    final keyPem = _getFromEnvironment('STAGESS_KEY_PEM');
    if (certPem.isEmpty || keyPem.isEmpty) {
      _logger.severe(
          'STAGESS_CERT_PEM and STAGESS_KEY_PEM environment variables must be set for secure connections.');
      exit(1);
    }

    return await HttpServer.bindSecure(
        _backendIp,
        _backendPort,
        SecurityContext()
          ..useCertificateChain(certPem)
          ..usePrivateKey(keyPem));
  } else {
    return await HttpServer.bind(_backendIp, _backendPort);
  }
}

Future<Connexions> _connectDatabase({
  required DatabaseBackend databaseBackend,
  required String firebaseApiKey,
  required ConnectionSettings settings,
  required bool skipLog,
}) async {
  final sqlInterface = switch (databaseBackend) {
    DatabaseBackend.mock => null,
    DatabaseBackend.mysql => await MySqlInterface.connect(
        connectToDatabase: () async => await MySqlConnection.connect(settings)),
    DatabaseBackend.mariadb => await MariaDbSqlInterface.connect(
        connectToDatabase: () async => await MySqlConnection.connect(settings)),
  };
  if (databaseBackend == DatabaseBackend.mariadb) {
    await sqlInterface!.tryQuery('SET SESSION group_concat_max_len = 1000000');
  }

  // Give a bit of time just in case
  await Future.delayed(Duration(milliseconds: 100));

  final connexions = Connexions(
      firebaseApiKey: firebaseApiKey,
      database: DatabaseManager(
        sqlInterface: sqlInterface!,
        schoolBoardsDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql ||
          DatabaseBackend.mariadb =>
            MySqlSchoolBoardsRepository(sqlInterface: sqlInterface),
          DatabaseBackend.mock => SchoolBoardsRepositoryMock()
        },
        adminsDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql ||
          DatabaseBackend.mariadb =>
            MySqlAdminsRepository(sqlInterface: sqlInterface),
          DatabaseBackend.mock => AdminsRepositoryMock()
        },
        teachersDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql ||
          DatabaseBackend.mariadb =>
            MySqlTeachersRepository(sqlInterface: sqlInterface),
          DatabaseBackend.mock => TeachersRepositoryMock()
        },
        studentsDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql ||
          DatabaseBackend.mariadb =>
            MySqlStudentsRepository(sqlInterface: sqlInterface),
          DatabaseBackend.mock => StudentsRepositoryMock()
        },
        enterprisesDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql ||
          DatabaseBackend.mariadb =>
            MySqlEnterprisesRepository(sqlInterface: sqlInterface),
          DatabaseBackend.mock => EnterprisesRepositoryMock()
        },
        internshipsDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql ||
          DatabaseBackend.mariadb =>
            MySqlInternshipsRepository(sqlInterface: sqlInterface),
          DatabaseBackend.mock => InternshipsRepositoryMock()
        },
      ),
      skipLog: skipLog);
  return connexions;
}
