import 'dart:io';

import 'package:logging/logging.dart';
import 'package:stagess_backend/server/bug_report_management.dart';
import 'package:stagess_backend/server/connexions.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_backend/utils/network_rate_limiter.dart';
import 'package:stagess_common/services/backend_helpers.dart';

final _logger = Logger('AnswerHttpRequest');

class HttpRequestHandler {
  final Connexions? _devConnexions;
  final Connexions? _productionConnexions;

  HttpRequestHandler(
      {required Connexions? devConnexions,
      required Connexions? productionConnexions})
      : _devConnexions = devConnexions,
        _productionConnexions = productionConnexions;

  Future<void> answer(HttpRequest request,
      {NetworkRateLimiter? rateLimiter}) async {
    if (rateLimiter != null && rateLimiter.isRefused(request)) {
      request.response.statusCode = HttpStatus.tooManyRequests;
      request.response.write('Too Many Requests');
      await request.response.close();
      return;
    }

    try {
      if (request.method == 'OPTIONS') {
        return await _answerOptionsRequest(request);
      } else if (request.method == 'GET') {
        return await _answerGetRequest(request);
      } else if (request.method == 'POST') {
        return await _answerPostRequest(request);
      } else {
        // Handle other HTTP methods
        return await _sendConnexionRefused(request);
      }
    } on ConnexionRefusedException catch (e) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.write('Unauthorized: $e');
      await request.response.close();
    } catch (e) {
      // This is a catch-all for any exceptions so the server doesn't crash on an
      // unhandled/unexpected exception. This should never actually happens

      // Remove from test coverage (the next four lines)
      // coverage:ignore-start
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal Server Error');
      await request.response.close();
      // coverage:ignore-end
    }
  }

  Future<void> _answerOptionsRequest(HttpRequest request) async {
    // Handle preflight requests
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      // ..set('X-Frame-Options', 'ALLOWALL') // Uncomment this line if InAppWebView is used
      ..set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    await request.response.close();
  }

  Future<void> _answerGetRequest(HttpRequest request) async {
    if (request.uri.path ==
        '/${BackendHelpers.connectEndpoint(isDev: false)}') {
      try {
        _productionConnexions?.add(await WebSocketTransformer.upgrade(request));
        return;
      } catch (e) {
        throw ConnexionRefusedException('WebSocket upgrade failed');
      }
    } else if (request.uri.path ==
        '/${BackendHelpers.connectEndpoint(isDev: true)}') {
      try {
        _devConnexions?.add(await WebSocketTransformer.upgrade(request));
        return;
      } catch (e) {
        throw ConnexionRefusedException('WebSocket upgrade failed');
      }
    } else {
      throw ConnexionRefusedException('Invalid endpoint');
    }
  }

  Future<void> _answerPostRequest(HttpRequest request) async {
    if (request.uri.path == '/${BackendHelpers.bugReportEndpoint}') {
      await answerBugReportRequest(request);
    } else {
      throw ConnexionRefusedException('Invalid endpoint');
    }
  }

  Future<void> _sendConnexionRefused(HttpRequest request) async {
    request.response.statusCode = HttpStatus.unauthorized;
    request.response.write('Unauthorized');
    await request.response.close();
  }
}
