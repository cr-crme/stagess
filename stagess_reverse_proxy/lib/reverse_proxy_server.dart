import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

final _logger = Logger('ReverseProxyServer');

class ReverseProxyServer {
  final String? certPath;
  final String? keyPath;
  bool get useSecure => certPath != null && keyPath != null;

  final InternetAddress bindAddress = InternetAddress.anyIPv4;
  final int bindPort = 3457;
  final String backendHost;
  final int backendPort;

  ServerSocket? _unsecuredServer;
  SecureServerSocket? _securedServer;
  get _server => useSecure ? _securedServer : _unsecuredServer;

  final Set<Socket> _clientSockets = {};
  final Set<Socket> _backendSockets = {};
  bool _isStarted = false;
  bool _isReconnecting = false;

  ReverseProxyServer({
    this.certPath,
    this.keyPath,
    required this.backendHost,
    required this.backendPort,
  }) {
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
    while (_isStarted) {
      _logger
          .info('checking backend availability $backendHost:$backendPort ...');
      if (!(await _testBackendConnect())) {
        final delay = Duration(seconds: 5);
        _logger.warning(
            'The backend is not reachable; will retry in ${delay.inSeconds}s');
        await Future.delayed(delay);
        continue;
      }

      // Backend is reachable — start TLS server
      try {
        await _startReverseProxyServer();

        // wait until we need to reconnection (set when any backend socket closes)
        while (_isStarted && !_isReconnecting) {
          // simple sleep loop to yield; server accepts connections via listener
          await Future.delayed(Duration(milliseconds: 200));
        }
      } catch (e, st) {
        _logger.severe('error while running server: $e\n$st');
      } finally {
        // teardown when reconnecting or stopping
        await _closeServer();
        await _closeAllClients(
          'backend disconnected / proxy restarting listener',
        );
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

  Future<void> _startReverseProxyServer() async {
    if (_server != null) return;
    _logger.info(
        'starting reverse proxy server on ${bindAddress.address}:$bindPort ...');

    if (useSecure) {
      final ctx = SecurityContext();
      ctx.useCertificateChain(certPath!);
      ctx.usePrivateKey(keyPath!);

      _securedServer = await SecureServerSocket.bind(
        bindAddress,
        bindPort,
        ctx,
        backlog: 128,
      );

      _securedServer!.listen(
        (SecureSocket clientSocket) {
          if (!_isStarted) {
            try {
              clientSocket.destroy();
            } catch (_) {}
            return;
          }
          _handleIncomingClient(clientSocket);
        },
        onError: (e, st) {
          _logger.severe('TLS server listen error: $e\n$st');
        },
        onDone: () {
          _logger.info('TLS server done');
        },
      );
    } else {
      _unsecuredServer =
          await ServerSocket.bind(bindAddress, bindPort, backlog: 128);
    }

    _logger.info('TLS server bound; accepting connections');
  }

  Future<void> _closeServer() async {
    if (_server == null) return;

    _logger.info(
        'closing secured reverse proxy server (stop accepting new clients)');
    try {
      await _securedServer?.close();
      await _unsecuredServer?.close();
    } catch (e) {
      _logger.severe('error closing secured reverse proxy server: $e');
    } finally {
      _securedServer = null;
      _unsecuredServer = null;
    }
  }

  Future<void> _handleIncomingClient(SecureSocket clientSock) async {
    _logger.info(
      'incoming client from ${clientSock.remoteAddress.address}:${clientSock.remotePort}',
    );
    Socket? backendSock;
    try {
      // try connect to backend for this client
      backendSock = await Socket.connect(backendHost, backendPort);
    } catch (e) {
      _logger.severe(
        'failed to connect to backend for client ${clientSock.remoteAddress.address}:${clientSock.remotePort}: $e',
      );
      // respond with 503 and close
      try {
        clientSock.write(
          'HTTP/1.1 503 Service Unavailable\r\n'
          'Connection: close\r\n'
          'Content-Length: 0\r\n'
          '\r\n',
        );
        await clientSock.flush();
      } catch (_) {}
      clientSock.destroy();
      return;
    }

    // Register
    _clientSockets.add(clientSock);
    _backendSockets.add(backendSock);

    // When either side closes/error, we must close both and — if this was a backend socket — trigger global reconnect.
    void handleBackendDone([dynamic err]) {
      _logger.severe(
        'backend socket for client ${clientSock.remoteAddress.address}:${clientSock.remotePort} closed/errored: $err',
      );
      // mark to trigger global reconnect sequence
      _isReconnecting = true;
      _closeSocketIfMounted(backendSock);
      _closeSocketIfMounted(clientSock);
    }

    void handleClientDone([dynamic err]) {
      _logger.severe(
        'client ${clientSock.remoteAddress.address}:${clientSock.remotePort} closed/errored: $err',
      );
      _closeSocketIfMounted(clientSock);
      _closeSocketIfMounted(backendSock);
      // If the client disconnected normally not necessarily meaning backend died; do not trigger reconnect here.
    }

    backendSock.done
        .then((_) => handleBackendDone())
        .catchError((e) => handleBackendDone(e));
    clientSock.done
        .then((_) => handleClientDone())
        .catchError((e) => handleClientDone(e));

    backendSock.listen(
      (data) {
        // forward bytes to client (re-encrypt automatically by SecureSocket)
        try {
          clientSock.add(data);
        } catch (e) {
          _logger.severe('error writing to client socket: $e');
          handleClientDone(e);
        }
      },
      onError: (e) {
        handleBackendDone(e);
      },
      onDone: () {
        handleBackendDone();
      },
      cancelOnError: true,
    );

    clientSock.listen(
      (data) {
        // forward bytes to backend
        try {
          backendSock!.add(data);
        } catch (e) {
          _logger.severe('error writing to backend socket: $e');
          handleBackendDone(e);
        }
      },
      onError: (e) {
        handleClientDone(e);
      },
      onDone: () {
        handleClientDone();
      },
      cancelOnError: true,
    );

    _logger.info(
      'tunneling established between client ${clientSock.remoteAddress.address}:${clientSock.remotePort} and backend $backendHost:$backendPort',
    );
  }

  void _closeSocketIfMounted(Socket? s) {
    if (s == null) return;
    if (_clientSockets.remove(s) || _backendSockets.remove(s)) {
      try {
        s.destroy();
      } catch (_) {}
    }
  }

  Future<void> _closeAllClients(String reason) async {
    if (_clientSockets.isEmpty && _backendSockets.isEmpty) return;
    _logger.info(
      'closing all client/backend sockets: $reason (clients=${_clientSockets.length}, backends=${_backendSockets.length})',
    );
    final clients = Set<Socket>.from(_clientSockets);
    final backends = Set<Socket>.from(_backendSockets);
    _clientSockets.clear();
    _backendSockets.clear();

    for (final s in clients) {
      try {
        // best-effort notify — but client might be mid-protocol; destroy afterwards
        s.destroy();
      } catch (_) {}
    }
    for (final s in backends) {
      try {
        s.destroy();
      } catch (_) {}
    }
  }
}
