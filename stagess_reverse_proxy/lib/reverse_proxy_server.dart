import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';

final _logger = Logger('ReverseProxyServer');

class ReverseProxyServer {
  final String? _certPath;
  final String? _keyPath;
  bool get useSecure => _certPath != null && _keyPath != null;

  final InternetAddress bindAddress = InternetAddress.anyIPv4;
  final int bindPort;
  final String backendHost;
  final int backendPort;

  Stream<Socket>? _server;
  bool _isStarted = false;
  bool _isReconnecting = false;

  final int maxLiveConnections;
  final Set<Socket> _clientSockets = {};
  final Set<Socket> _backendSockets = {};

  ReverseProxyServer({
    String? certPath,
    String? keyPath,
    required this.maxLiveConnections,
    required this.bindPort,
    required this.backendHost,
    required this.backendPort,
  })  : _certPath = (certPath?.isEmpty ?? true) ? null : certPath,
        _keyPath = (keyPath?.isEmpty ?? true) ? null : keyPath {
    if ((certPath == null && keyPath != null) ||
        (certPath != null && keyPath == null)) {
      throw ArgumentError(
          'Either both certPath and keyPath must be provided or neither.');
    }
  }

  Future<void> start() async {
    _isStarted = true;
    await _mainLoop();
  }

  Future<void> stop() async {
    _isStarted = false;
    await _closeServer();
    await _closeAllClients('proxy shutting down');
  }

  Future<void> _mainLoop() async {
    final maxRetries = 5;
    var retryCount = 0;
    while (_isStarted) {
      _logger
          .info('Checking backend availability $backendHost:$backendPort ...');
      // We need to "test" the connection because there is never a persistent
      // connection to the backend; each client connection creates its own
      // backend connection.
      if (!(await _testBackendConnect())) {
        final delay = Duration(seconds: 5);
        _logger.warning(
            'The backend is not reachable; will retry in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        continue;
      }

      // Backend is reachable — start TLS server
      try {
        await _startReverseProxyServer(maxLiveConnections: maxLiveConnections);
        while (_isStarted && !_isReconnecting) {
          retryCount = 0;
          await Future.delayed(Duration(seconds: 5));
        }
      } catch (e, st) {
        // This error can only happen during server starting
        // If it happens retry up to max retries and then exit
        _logger.severe('Error while running server: $e\n$st');
        if (retryCount < maxRetries) {
          retryCount++;
          _logger
              .warning('Retrying to start server ($retryCount/$maxRetries)...');
          await Future.delayed(Duration(seconds: 5));
        }
      } finally {
        // teardown when reconnecting or stopping
        await _closeServer();
        await _closeAllClients(
            'Backend disconnected / proxy restarting listener');
        _isReconnecting = false;
      }
    }
  }

  Future<bool> _testBackendConnect({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final socket = await Socket.connect(
        backendHost,
        backendPort,
        timeout: timeout,
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _startReverseProxyServer(
      {required int maxLiveConnections}) async {
    if (_server != null) return;
    _logger.info(
        'Starting reverse proxy server on ${bindAddress.address}:$bindPort ...');

    _server = await (useSecure
        ? SecureServerSocket.bind(
            bindAddress,
            bindPort,
            SecurityContext()
              ..useCertificateChain(_certPath!)
              ..usePrivateKey(_keyPath!),
            backlog: maxLiveConnections,
          )
        : ServerSocket.bind(
            bindAddress,
            bindPort,
            backlog: maxLiveConnections,
          ));
    _server!.listen(_handleIncomingClient,
        onError: (e, st) => _logger.severe('TLS server listen error: $e\n$st'),
        onDone: () => _logger.info('TLS server done'));

    _logger.info('TLS server bound; accepting connections');
  }

  Future<void> _closeServer() async {
    if (_server == null) return;

    _logger.info('Closing reverse proxy server (stop accepting new clients)');
    try {
      await (useSecure
          ? (_server as SecureServerSocket).close()
          : (_server as ServerSocket).close());
    } catch (e) {
      _logger.severe('Error closing reverse proxy server: $e');
    } finally {
      _server = null;
    }
  }

  Future<void> _handleIncomingClient(Socket clientSocket) async {
    // If the server is not started, close the client socket immediately
    if (!_isStarted) {
      try {
        clientSocket.destroy();
      } catch (_) {}
      return;
    }

    final remote =
        '${clientSocket.remoteAddress.address}:${clientSocket.remotePort}';
    _logger.info('Incoming client from $remote');

    // Prepare the tunneling by connecting to backend for this client
    Socket? backendSocket;
    try {
      backendSocket = await Socket.connect(backendHost, backendPort);
    } catch (e) {
      // If we cannot connect to backend, inform client and close connection
      _logger.severe('Failed to connect to backend for client $remote: $e');
      try {
        clientSocket.write(
          'HTTP/1.1 503 Service Unavailable\r\n'
          'Connection: close\r\n'
          'Content-Length: 0\r\n'
          '\r\n',
        );
        await clientSocket.flush();
      } catch (_) {}
      clientSocket.destroy();

      // Prepare a full reconnect of the server
      _isReconnecting = true;
      return;
    }

    // Register sockets
    _clientSockets.add(clientSocket);
    _backendSockets.add(backendSocket);

    // Setup the callbacks for handling all the communication protocols
    bool clientIsDisconnected = false;
    void handleConnexionDone([err]) {
      if (clientIsDisconnected) return;
      clientIsDisconnected = true;

      _closeSocketIfMounted(clientSocket);
      _closeSocketIfMounted(backendSocket);
    }

    void handleBackendDone([e]) => handleConnexionDone(e);
    void handleBackendError(e) {
      _logger.severe('Error on backend socket: $e.\nKilling all connexions.');
      _isReconnecting = true;
      handleConnexionDone(e);
    }

    void handleClientDone([e]) => handleConnexionDone(e);
    void handleClientError(e) {
      _logger
          .severe('Error on client ($remote) socket: $e.\nClosing connexion.');
      handleConnexionDone(e);
    }

    void forwardToBackend(Uint8List data) {
      try {
        backendSocket!.add(data);
      } catch (e) {
        handleBackendError(e);
      }
    }

    void forwardToClient(Uint8List data) {
      // Forward to client
      try {
        clientSocket.add(data);
      } catch (e) {
        handleClientError(e);
      }
    }

    // Setup the tunneling between client and backend
    backendSocket
      ..done.then(handleBackendDone).catchError(handleBackendError)
      ..listen(
        forwardToClient,
        onDone: handleBackendDone,
        onError: handleBackendError,
        cancelOnError: true,
      );
    clientSocket
      ..done.then(handleClientDone).catchError(handleClientError)
      ..listen(
        forwardToBackend,
        onDone: handleClientDone,
        onError: handleClientError,
        cancelOnError: true,
      );

    _logger.info(
      'Tunneling established between client $remote and backend $backendHost:$backendPort',
    );
  }

  void _closeSocketIfMounted(Socket? socket) {
    if (socket == null) return;
    if (_clientSockets.remove(socket) || _backendSockets.remove(socket)) {
      try {
        socket.destroy();
      } catch (_) {}
    }
  }

  Future<void> _closeAllClients(String reason) async {
    if (_clientSockets.isEmpty && _backendSockets.isEmpty) return;

    _logger.info(
      'Closing all client/backend sockets: $reason (clients=${_clientSockets.length}, backends=${_backendSockets.length})',
    );
    final clients = Set<Socket>.from(_clientSockets);
    final backends = Set<Socket>.from(_backendSockets);
    _clientSockets.clear();
    _backendSockets.clear();

    for (final socket in clients) {
      try {
        socket.destroy();
      } catch (_) {}
    }
    for (final socket in backends) {
      try {
        socket.destroy();
      } catch (_) {}
    }
  }
}
