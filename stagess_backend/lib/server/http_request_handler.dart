import 'dart:io';

import 'package:logging/logging.dart';
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

  Future<void> answer(
    HttpRequest request, {
    NetworkRateLimiter? getRequestRateLimiter,
    NetworkRateLimiter? websocketRateLimiter,
    List<Uri> allowedOrigins = const [],
  }) async {
    try {
      // Control the rate of incoming requests to prevent abuse and DoS attacks
      if (getRequestRateLimiter != null &&
          getRequestRateLimiter
              .isRefused(request.connectionInfo?.remoteAddress.address)) {
        throw RateLimitedException();
      }

      // Control the size of incoming requests to prevent abuse and DoS attacks
      if (request.contentLength > 1 * 1024) {
        // 1 KB limit
        throw ConnexionRefusedException('Request size exceeds limit');
      }

      // Handle the request based on its method and path
      if (request.method == 'GET') {
        return await _answerGetRequest(request,
            allowedOrigins: allowedOrigins, rateLimiter: websocketRateLimiter);
      } else {
        // Handle other HTTP methods
        throw ConnexionRefusedException('Unsupported method');
      }
    } on ConnexionRefusedException catch (e) {
      await _sendFailedAndClose(request,
          statusCode: HttpStatus.unauthorized, message: 'Unauthorized: $e');
    } on RateLimitedException catch (e) {
      await _sendFailedAndClose(request,
          statusCode: HttpStatus.tooManyRequests,
          message: 'Too Many Requests: $e');
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
    try {
      _logger.info(
          'Request from ${request.connectionInfo?.remoteAddress.address}:${request.connectionInfo?.remotePort} failed: $message');
      request.response.statusCode = statusCode;
      request.response.write('Connexion refused');
      await request.response.close();
    } catch (e, st) {
      //coverage:ignore-start
      _logger.severe('Failed to send error response', e, st);
      //coverage:ignore-end
    }
  }

  Future<void> _answerGetRequest(
    HttpRequest request, {
    required List<Uri> allowedOrigins,
    NetworkRateLimiter? rateLimiter,
  }) async {
    final ipAddress =
        request.connectionInfo?.remoteAddress.address ?? 'unknown';
    final port = request.connectionInfo?.remotePort ?? 0;

    _logger.info('Received a GET request from $ipAddress:$port '
        'to endpoint ${request.uri.path}');

    // Check the origin header for CORS
    final origin = Uri.parse(request.headers.value('Origin') ?? '');
    if (!allowedOrigins.any((allowed) =>
        allowed.scheme == origin.scheme && allowed.host == origin.host)) {
      throw ConnexionRefusedException('Origin not allowed');
    }

    if (request.uri.path ==
        '/${BackendHelpers.connectEndpoint(useDevDatabase: false)}') {
      try {
        _productionConnexions?.add(
            CustomWebSocket(
                socket: await WebSocketTransformer.upgrade(request),
                ipAddress: ipAddress,
                port: port),
            rateLimiter: rateLimiter);
        return;
      } catch (e) {
        throw ConnexionRefusedException('WebSocket upgrade failed');
      }
    } else if (request.uri.path ==
        '/${BackendHelpers.connectEndpoint(useDevDatabase: true)}') {
      try {
        _devConnexions?.add(
            CustomWebSocket(
                socket: await WebSocketTransformer.upgrade(request),
                ipAddress: ipAddress,
                port: port),
            rateLimiter: rateLimiter);
        return;
      } catch (e) {
        throw ConnexionRefusedException('WebSocket upgrade failed');
      }
    } else {
      throw ConnexionRefusedException('Invalid endpoint');
    }
  }
}
