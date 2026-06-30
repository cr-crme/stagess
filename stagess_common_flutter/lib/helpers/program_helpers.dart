import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/map_providers.dart';
import 'package:stagess_common/services/backend_helpers.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/services/question_file_service.dart';
import 'package:stagess_common_flutter/services/risk_data_file_service.dart';

class ProgramInitializer {
  static bool _initialized = false;

  static void configureLogger({required bool showLogs}) {
    Logger.root.level = showLogs ? Level.INFO : Level.WARNING;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print(
        '[${record.level.name}] ${record.time}: ${record.loggerName}: ${record.message}'
        '${record.error != null ? ' Error: ${record.error}' : ''}'
        '${record.stackTrace != null ? ' StackTrace: ${record.stackTrace}' : ''}',
      );
    });
  }

  static Future<void> initialize({
    FirebaseOptions? firebaseOptions,
    bool useActivitySectorsService = false,
    bool useRiskDataFileService = false,
    bool useQuestionFileService = false,
    bool useTileProvider = false,
    bool useReverseGeocodingProvider = false,
  }) async {
    if (_initialized) return;

    initializeDateFormatting('fr_CA');

    await Future.wait([
      // coverage:ignore-start
      if (firebaseOptions != null)
        Firebase.initializeApp(options: firebaseOptions),
      // coverage:ignore-end
      if (useActivitySectorsService) ActivitySectorsService.initialize(),
      if (useRiskDataFileService) RiskDataFileService.loadData(),
      if (useQuestionFileService) QuestionFileService.loadData(),
      if (useTileProvider)
        TileProvider.instance.initialize(provider: MapTileProvider.googleMaps),
      if (useReverseGeocodingProvider)
        ReverseGeocodingProvider.instance
            .initialize(provider: MapReverseGeocodingProvider.googleMaps),
    ]);

    _initialized = true;
  }

  static Future<bool?> isBackendCompatible() async {
    try {
      final response = await http.get(BackendHelpers.versionUri);
      if (response.statusCode == 200) {
        return response.body.trim() == CommunicationProtocol.version;
      }
    } catch (e) {
      // Ignore errors and consider the backend incompatible
    }
    return null;
  }
}
