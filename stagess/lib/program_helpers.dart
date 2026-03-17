import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stagess/firebase_options.dart';
import 'package:stagess/misc/question_file_service.dart';
import 'package:stagess/misc/risk_data_file_service.dart';
import 'package:stagess_common/services/job_data_file_service.dart';

class ProgramInitializer {
  static bool _showDebugElements = kDebugMode;
  static bool get showDebugElements => _showDebugElements;
  static bool _initialized = false;

  static Future<void> initialize({
    bool showDebugElements = false,
    bool mockMe = false,
  }) async {
    _showDebugElements = showDebugElements;
    if (_initialized) return;

    initializeDateFormatting('fr_CA');

    await Future.wait([
      // coverage:ignore-start
      if (!mockMe)
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      // coverage:ignore-end
      ActivitySectorsService.initialize(),
      RiskDataFileService.loadData(),
      QuestionFileService.loadData(),
    ]);

    _initialized = true;
  }
}
