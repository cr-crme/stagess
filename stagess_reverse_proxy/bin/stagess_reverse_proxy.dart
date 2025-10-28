import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:stagess_reverse_proxy/reverse_proxy_server.dart';
import 'package:stagess_common/services/backend_helpers.dart';

final _logger = Logger('BackendServer');

Future<void> main(List<String> args) async {
  final useSecure = _getFromEnvironment('STAGESS_USE_SSL') == 'true';
  final certPem = useSecure ? _getFromEnvironment('STAGESS_CERT_PEM') : null;
  final keyPem = useSecure ? _getFromEnvironment('STAGESS_KEY_PEM') : null;
  final backendHost = InternetAddress.loopbackIPv4.address;
  final backendPort = BackendHelpers.backendPort;

  final reverseProxyServer = ReverseProxyServer(
    certPath: certPem,
    keyPath: keyPem,
    backendHost: backendHost,
    backendPort: backendPort,
  );

  // graceful shutdown handlers
  ProcessSignal.sigint.watch().listen((_) async {
    _logger.info('SIGINT received, shutting down...');
    await reverseProxyServer.stop();
    exit(0);
  });
  ProcessSignal.sigterm.watch().listen((_) async {
    _logger.info('SIGTERM received, shutting down...');
    await reverseProxyServer.stop();
    exit(0);
  });

  await reverseProxyServer.start();
}

String _getFromEnvironment(String key) {
  final value = Platform.environment[key];
  if (value == null || value.isEmpty) {
    _logger.severe('$key environment variable is not set.');
    exit(1);
  }
  return value;
}
