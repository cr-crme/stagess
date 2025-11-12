class BackendHelpers {
  static bool get useSsl =>
      const bool.fromEnvironment('STAGESS_USE_SSL', defaultValue: true);

  static String get _wsProtocol => useSsl ? 'wss' : 'ws';
  static String get _httpProtocol => useSsl ? 'https' : 'http';

  static String get backendIp =>
      const String.fromEnvironment('STAGESS_BACKEND_IP',
          defaultValue: 'stagessserver.adoprevit.org');

  static int get backendPort =>
      const int.fromEnvironment('STAGESS_BACKEND_PORT', defaultValue: 8443);

  static Uri backendConnectUri({required bool useDevDatabase}) => Uri.parse(
      '$_wsProtocol://$backendIp:$backendPort/${connectEndpoint(useDevDatabase: useDevDatabase)}');
  static String connectEndpoint({required bool useDevDatabase}) =>
      '${useDevDatabase ? 'dev-' : ''}connect';
  static String get bugReportEndpoint => 'bug-report';

  static Uri backendUriForBugReport() =>
      Uri.parse('$_httpProtocol://$backendIp:$backendPort/$bugReportEndpoint');
}
