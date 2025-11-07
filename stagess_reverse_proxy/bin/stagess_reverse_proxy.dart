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

  final useSsl = (Platform.environment['STAGESS_USE_SSL'] ?? 'true') == 'true';
  final reverseProxyServer = ReverseProxyServer(
    maxLiveConnections: 128,
    certPath: useSsl ? Platform.environment['STAGESS_CERT_PEM'] : null,
    keyPath: useSsl ? Platform.environment['STAGESS_KEY_PEM'] : null,
    bindPort:
        int.parse(Platform.environment['STAGESS_REVERSED_PROXY_PORT'] ?? '443'),
    backendHost: InternetAddress.loopbackIPv4.address,
    backendPort:
        int.parse(Platform.environment['STAGESS_BACKEND_PORT'] ?? '3456'),
  );

  // Shutdown handlers
  ProcessSignal.sigint.watch().listen((_) async {
    _logger.info('SIGINT received, shutting down...');
    await reverseProxyServer.stop();
    exit(0);
  });
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) async {
      _logger.info('SIGTERM received, shutting down...');
      await reverseProxyServer.stop();
      exit(0);
    });
  }

  await reverseProxyServer.run();

  _logger.info('Reverse proxy server is now shut down.');
  exit(0);
}
