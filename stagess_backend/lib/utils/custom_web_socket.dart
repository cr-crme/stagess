import 'dart:async';
import 'dart:io';

class CustomWebSocket {
  final WebSocket _socket;
  final String _ipAddress;
  final int _port;

  CustomWebSocket({
    required WebSocket socket,
    required String ipAddress,
    required int port,
  })  : _socket = socket,
        _ipAddress = ipAddress,
        _port = port;

  /// Interface to get the IP address of the socket
  String get ipAddress => _ipAddress;

  /// Interface to get the port of the socket
  int get port => _port;

  ///
  /// Interface to listen socket
  StreamSubscription<dynamic> listen(
    void Function(dynamic event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _socket.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  ///
  /// Interface to add data to socket
  void add(dynamic data) => _socket.add(data);

  ///
  /// Interface to close socket
  Future<void> close([int? code, String? reason]) =>
      _socket.close(code, reason);
}
