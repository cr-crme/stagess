class BackendHelpers {
  static String backendProtocol({required bool useSsl}) =>
      useSsl ? 'wss' : 'ws';
  static String backendIp({required bool useLocal}) =>
      useLocal ? 'localhost' : 'stagessserver.adoprevit.org';
  static int backendPortConnexion({required bool useProxy}) =>
      useProxy ? backendPort : reverseProxyPort;
  static int get backendPort => 3456;
  static int get reverseProxyPort => 3457;
  static String connectEndpoint({required bool isDev}) =>
      '${isDev ? 'dev-' : ''}connect';
  static String get bugReportEndpoint => 'bug-report';

  static Uri backendUri(
          {required bool isLocal,
          required bool useProxy,
          required bool useSsl,
          required bool isDev}) =>
      Uri.parse(
          '${backendProtocol(useSsl: useSsl)}://${backendIp(useLocal: isLocal)}:${backendPortConnexion(useProxy: useProxy)}/${connectEndpoint(isDev: isDev)}');
  static Uri backendUriForBugReport(
          {required bool isLocal,
          required bool useProxy,
          required bool useSsl}) =>
      Uri.parse(
          '${useSsl ? 'https' : 'http'}://${backendIp(useLocal: isLocal)}:${backendPortConnexion(useProxy: useProxy)}/$bugReportEndpoint');
}
