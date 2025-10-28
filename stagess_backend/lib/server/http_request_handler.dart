import 'dart:io';

import 'package:logging/logging.dart';
import 'package:stagess_backend/server/bug_report_management.dart';
import 'package:stagess_backend/server/connexions.dart';
import 'package:stagess_backend/utils/custom_web_socket.dart';
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
    try {
      if (rateLimiter != null && rateLimiter.isRefused(request)) {
        throw RateLimitedException();
      }

      if (request.method == 'OPTIONS') {
        return await _answerOptionsRequest(request);
      } else if (request.method == 'GET') {
        return await _answerGetRequest(request);
      } else if (request.method == 'POST') {
        return await _answerPostRequest(request);
      } else {
        // Handle other HTTP methods
        throw ConnexionRefusedException('Unsupported method');
      }
    } on ConnexionRefusedException catch (e) {
      await _sendFailedAndClose(request,
          statusCode: HttpStatus.unauthorized, message: 'Unauthorized: $e');
    } on RateLimitedException catch (e) {
      await _sendFailedAndClose(request,
          statusCode: HttpStatus.tooManyRequests, message: 'Unauthorized: $e');
    } catch (e) {
      // This is a catch-all for any exceptions so the server doesn't crash on an
      // unhandled/unexpected exception. This should never actually happens

      // Remove from test coverage (the next four lines)
      // coverage:ignore-start
      await _sendFailedAndClose(request,
          statusCode: HttpStatus.internalServerError,
          message: 'Internal Server Error');
      // coverage:ignore-end
    }
  }

  Future<void> _sendFailedAndClose(HttpRequest request,
      {required int statusCode, required String message}) async {
    _logger.info(
        'Request from ${request.connectionInfo?.remoteAddress.address}:${request.connectionInfo?.remotePort} failed: $message');
    request.response.statusCode = statusCode;
    request.response.write(message);
    await request.response.close();
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
    final ipAddress =
        request.connectionInfo?.remoteAddress.address ?? 'unknown';
    final port = request.connectionInfo?.remotePort ?? 0;

    _logger.info('Received a GET request from $ipAddress:$port '
        'to endpoint ${request.uri.path}');

    if (request.uri.path ==
        '/${BackendHelpers.connectEndpoint(useDevDatabase: false)}') {
      try {
        _productionConnexions?.add(CustomWebSocket(
            socket: await WebSocketTransformer.upgrade(request),
            ipAddress: ipAddress,
            port: port));
        return;
      } catch (e) {
        throw ConnexionRefusedException('WebSocket upgrade failed');
      }
    } else if (request.uri.path ==
        '/${BackendHelpers.connectEndpoint(useDevDatabase: true)}') {
      try {
        _devConnexions?.add(CustomWebSocket(
            socket: await WebSocketTransformer.upgrade(request),
            ipAddress: ipAddress,
            port: port));
        return;
      } catch (e) {
        throw ConnexionRefusedException('WebSocket upgrade failed');
      }
    } else {
      throw ConnexionRefusedException('Invalid endpoint');
    }
  }

  Future<void> _answerPostRequest(HttpRequest request) async {
    _logger.info(
        'Received a POST request from ${request.connectionInfo?.remoteAddress.address}:${request.connectionInfo?.remotePort} '
        'to endpoint ${request.uri.path}');

    if (request.uri.path == '/${BackendHelpers.bugReportEndpoint}') {
      await answerBugReportRequest(request);
    } else {
      throw ConnexionRefusedException('Invalid endpoint');
    }
  }
}
