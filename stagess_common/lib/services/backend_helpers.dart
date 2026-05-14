class BackendHelpers {
  static bool get useSsl =>
      const bool.fromEnvironment('STAGESS_USE_SSL', defaultValue: true);

  static String get _httpProtocol => useSsl ? 'https' : 'http';
  static String get _wsProtocol => useSsl ? 'wss' : 'ws';

  static String get backendIp =>
      const String.fromEnvironment('STAGESS_BACKEND_IP',
          defaultValue: 'stagessserver.adoprevit.org');

  static int get backendPort =>
      const int.fromEnvironment('STAGESS_BACKEND_PORT', defaultValue: 8443);

  static String get backendBaseUrl => '$backendIp:$backendPort';

  static Uri backendConnectUri({required bool useDevDatabase}) => Uri.parse(
      '$_wsProtocol://$backendBaseUrl/${connectEndpoint(useDevDatabase: useDevDatabase)}');
  static String connectEndpoint({required bool useDevDatabase}) =>
      '${useDevDatabase ? 'dev-' : ''}connect';

  static String get versionEndpoint => 'version';
  static Uri get versionUri =>
      Uri.parse('$_httpProtocol://$backendBaseUrl/$versionEndpoint');
}
