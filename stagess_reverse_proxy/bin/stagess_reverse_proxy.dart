import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:stagess_reverse_proxy/reverse_proxy_server.dart';

final _logger = Logger('StagessReverseProxy');

Future<void> main(List<String> args) async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final useSsl = bool.fromEnvironment('STAGESS_USE_SSL', defaultValue: true);
  final reverseProxyServer = ReverseProxyServer(
    maxLiveConnections: 128,
    certPath: useSsl ? Platform.environment['STAGESS_CERT_PEM'] : null,
    keyPath: useSsl ? Platform.environment['STAGESS_KEY_PEM'] : null,
    bindPort:
        int.fromEnvironment('STAGESS_REVERSED_PROXY_PORT', defaultValue: 443),
    backendHost: InternetAddress.loopbackIPv4.address,
    backendPort:
        int.fromEnvironment('STAGESS_BACKEND_PORT', defaultValue: 3456),
  );

  // Shutdown handlers
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
