import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import 'package:stagess/firebase_options.dart';
import 'package:stagess/misc/question_file_service.dart';
import 'package:stagess/misc/risk_data_file_service.dart';
import 'package:stagess/misc/storage_service.dart';
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
    StorageService.instance.isMocked = mockMe;

    _initialized = true;
  }
}

class BugReporter {
  static final _breadcrumbs = [];

  static loggerSetup() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      _breadcrumbs.add({
        'time': record.time.toIso8601String(),
        'level': record.level.name,
        'message': record.message,
        'error': record.error?.toString(),
        'stackTrace': record.stackTrace?.toString(),
      });
    });
  }

  static report(
    Object error,
    StackTrace stackTrace, {
    required errorReportUri,
  }) async {
    // Handle uncaught errors
    await http.post(
      errorReportUri,
      body: jsonEncode({
        'breadcrumbs': _breadcrumbs,
        'error': error.toString(),
        'stack_trace': stackTrace.toString(),
      }),
    );

    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stackTrace');
  }
}
