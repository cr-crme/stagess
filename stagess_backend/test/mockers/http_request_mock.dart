import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'web_socket_mock.dart';

class HttpHeadersMock implements HttpHeaders {
  bool isConnected = false;
  final Map<String, String> current = {};

  HttpHeadersMock({required this.forceFailToUpgradeToWebSocket});

  bool forceFailToUpgradeToWebSocket;
  late final Map<String, List<String>> _headers = forceFailToUpgradeToWebSocket
      ? {}
      : {
          'connection': ['Upgrade'],
          'upgrade': ['websocket'],
          'sec-websocket-version': ['13'],
          'sec-websocket-key': [
            'dGhlIHNhbXBsZSBub25jZQ=='
          ], // just a base64 string
        };

  @override
  bool get chunkedTransferEncoding => throw UnimplementedError();

  @override
  int get contentLength => throw UnimplementedError();

  @override
  ContentType get contentType => throw UnimplementedError();

  @override
  DateTime get date => throw UnimplementedError();

  @override
  DateTime get expires => throw UnimplementedError();

  @override
  String? host;

  @override
  DateTime? ifModifiedSince;

  @override
  bool get persistentConnection => throw UnimplementedError();

  @override
  int? port;

  @override
  List<String>? operator [](String name) {
    return _headers[name.toLowerCase()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void clear() {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    current[name] = value.toString();
  }

  @override
  String? value(String name) {
    return _headers[name.toLowerCase()]?.firstOrNull;
  }

  @override
  set chunkedTransferEncoding(bool chunkedTransferEncoding) {}

  @override
  set contentLength(int contentLength) {}

  @override
  set contentType(ContentType? contentType) {}

  @override
  set date(DateTime? date) {}

  @override
  set expires(DateTime? expires) {}

  @override
  set persistentConnection(bool persistentConnection) {}
}

class HttpResponseMock implements HttpResponse {
  bool isClosed = false;
  Object? response;
  bool forceFailToUpgradeToWebSocket = false;

  HttpResponseMock({this.forceFailToUpgradeToWebSocket = false});
  late final _headers = HttpHeadersMock(
      forceFailToUpgradeToWebSocket: forceFailToUpgradeToWebSocket);

  @override
  bool get bufferOutput => throw UnimplementedError();

  @override
  int get contentLength => throw UnimplementedError();

  @override
  Duration? get deadline => throw UnimplementedError();

  @override
  Encoding get encoding => throw UnimplementedError();

  @override
  bool get persistentConnection => throw UnimplementedError();

  @override
  String get reasonPhrase => throw UnimplementedError();

  @override
  int get statusCode => throw UnimplementedError();

  @override
  void add(List<int> data) {
    throw UnimplementedError();
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    throw UnimplementedError();
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    throw UnimplementedError();
  }

  @override
  Future close() async {
    isClosed = true;
  }

  @override
  HttpConnectionInfo? get connectionInfo => throw UnimplementedError();

  @override
  List<Cookie> get cookies => throw UnimplementedError();

  @override
  Future<Socket> detachSocket({bool writeHeaders = true}) async {
    return SocketMock();
  }

  @override
  Future get done => throw UnimplementedError();

  @override
  Future flush() {
    throw UnimplementedError();
  }

  @override
  HttpHeaders get headers => _headers;

  @override
  Future redirect(Uri location, {int status = HttpStatus.movedTemporarily}) {
    throw UnimplementedError();
  }

  @override
  void write(Object? object) {
    response = object;
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = ""]) {}

  @override
  set bufferOutput(bool bufferOutput) {}

  @override
  set contentLength(int contentLength) {}

  @override
  set deadline(Duration? deadline) {}

  @override
  set encoding(Encoding encoding) {}

  @override
  set persistentConnection(bool persistentConnection) {}

  @override
  set reasonPhrase(String reasonPhrase) {}

  @override
  set statusCode(int statusCode) {}
}

class HttpConnectionsInfoMock implements HttpConnectionInfo {
  final InternetAddress localAddress;

  @override
  final int localPort;

  @override
  final InternetAddress remoteAddress;

  @override
  final int remotePort;

  HttpConnectionsInfoMock({
    required this.localAddress,
    required this.localPort,
    required this.remoteAddress,
    required this.remotePort,
  });
}

class HttpRequestMock implements HttpRequest {
  final String _method;
  final Uri _uri;

  final bool forceFailToUpgradeToWebSocket;
  late final _response = HttpResponseMock(
      forceFailToUpgradeToWebSocket: forceFailToUpgradeToWebSocket);
  late final _headers = HttpHeadersMock(
      forceFailToUpgradeToWebSocket: forceFailToUpgradeToWebSocket);

  HttpRequestMock(
      {required String method,
      required Uri uri,
      this.forceFailToUpgradeToWebSocket = false})
      : _method = method,
        _uri = uri;

  @override
  Future<bool> any(bool Function(Uint8List element) test) {
    throw UnimplementedError();
  }

  @override
  Stream<Uint8List> asBroadcastStream(
      {void Function(StreamSubscription<Uint8List> subscription)? onListen,
      void Function(StreamSubscription<Uint8List> subscription)? onCancel}) {
    throw UnimplementedError();
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(Uint8List event) convert) {
    throw UnimplementedError();
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(Uint8List event) convert) {
    throw UnimplementedError();
  }

  @override
  Stream<R> cast<R>() {
    throw UnimplementedError();
  }

  @override
  X509Certificate? get certificate => throw UnimplementedError();

  @override
  HttpConnectionInfo? get connectionInfo => HttpConnectionsInfoMock(
        remoteAddress: InternetAddress.loopbackIPv4,
        remotePort: 12345,
        localAddress: InternetAddress.loopbackIPv4,
        localPort: 80,
      );

  @override
  Future<bool> contains(Object? needle) {
    throw UnimplementedError();
  }

  @override
  int get contentLength => throw UnimplementedError();

  @override
  List<Cookie> get cookies => throw UnimplementedError();

  @override
  Stream<Uint8List> distinct(
      [bool Function(Uint8List previous, Uint8List next)? equals]) {
    throw UnimplementedError();
  }

  @override
  Future<E> drain<E>([E? futureValue]) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> elementAt(int index) {
    throw UnimplementedError();
  }

  @override
  Future<bool> every(bool Function(Uint8List element) test) {
    throw UnimplementedError();
  }

  @override
  Stream<S> expand<S>(Iterable<S> Function(Uint8List element) convert) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> get first => throw UnimplementedError();

  @override
  Future<Uint8List> firstWhere(bool Function(Uint8List element) test,
      {Uint8List Function()? orElse}) {
    throw UnimplementedError();
  }

  @override
  Future<S> fold<S>(
      S initialValue, S Function(S previous, Uint8List element) combine) {
    throw UnimplementedError();
  }

  @override
  Future<void> forEach(void Function(Uint8List element) action) {
    throw UnimplementedError();
  }

  @override
  Stream<Uint8List> handleError(Function onError,
      {bool Function(dynamic error)? test}) {
    throw UnimplementedError();
  }

  @override
  HttpHeaders get headers => _headers;

  @override
  bool get isBroadcast => throw UnimplementedError();

  @override
  Future<bool> get isEmpty => throw UnimplementedError();

  @override
  Future<String> join([String separator = ""]) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> get last => throw UnimplementedError();

  @override
  Future<Uint8List> lastWhere(bool Function(Uint8List element) test,
      {Uint8List Function()? orElse}) {
    throw UnimplementedError();
  }

  @override
  Future<int> get length => throw UnimplementedError();

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    throw UnimplementedError();
  }

  @override
  Stream<S> map<S>(S Function(Uint8List event) convert) {
    throw UnimplementedError();
  }

  @override
  String get method => _method;

  @override
  bool get persistentConnection => throw UnimplementedError();

  @override
  Future pipe(StreamConsumer<Uint8List> streamConsumer) {
    throw UnimplementedError();
  }

  @override
  String get protocolVersion => throw UnimplementedError();

  @override
  Future<Uint8List> reduce(
      Uint8List Function(Uint8List previous, Uint8List element) combine) {
    throw UnimplementedError();
  }

  @override
  Uri get requestedUri => throw UnimplementedError();

  @override
  HttpResponse get response => _response;

  @override
  HttpSession get session => throw UnimplementedError();

  @override
  Future<Uint8List> get single => throw UnimplementedError();

  @override
  Future<Uint8List> singleWhere(bool Function(Uint8List element) test,
      {Uint8List Function()? orElse}) {
    throw UnimplementedError();
  }

  @override
  Stream<Uint8List> skip(int count) {
    throw UnimplementedError();
  }

  @override
  Stream<Uint8List> skipWhile(bool Function(Uint8List element) test) {
    throw UnimplementedError();
  }

  @override
  Stream<Uint8List> take(int count) {
    throw UnimplementedError();
  }

  @override
  Stream<Uint8List> takeWhile(bool Function(Uint8List element) test) {
    throw UnimplementedError();
  }

  @override
  Stream<Uint8List> timeout(Duration timeLimit,
      {void Function(EventSink<Uint8List> sink)? onTimeout}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Uint8List>> toList() {
    throw UnimplementedError();
  }

  @override
  Future<Set<Uint8List>> toSet() {
    throw UnimplementedError();
  }

  @override
  Stream<S> transform<S>(StreamTransformer<Uint8List, S> streamTransformer) {
    throw UnimplementedError();
  }

  @override
  Uri get uri => _uri;

  @override
  Stream<Uint8List> where(bool Function(Uint8List event) test) {
    throw UnimplementedError();
  }
}
