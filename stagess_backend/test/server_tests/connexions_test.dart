import 'dart:async';
import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:stagess_backend/repositories/admins_repository.dart';
import 'package:stagess_backend/repositories/enterprises_repository.dart';
import 'package:stagess_backend/repositories/internships_repository.dart';
import 'package:stagess_backend/repositories/school_boards_repository.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/repositories/students_repository.dart';
import 'package:stagess_backend/repositories/teachers_repository.dart';
import 'package:stagess_backend/server/connexions.dart';
import 'package:stagess_backend/server/database_manager.dart';
import 'package:stagess_backend/utils/custom_web_socket.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:test/test.dart';

import '../mockers/sql_connection_mock.dart';
import '../mockers/web_socket_mock.dart';

class ConnexionsMock extends Connexions {
  ConnexionsMock({
    required super.database,
    required super.firebaseApiKey,
    super.timeout,
    required super.skipLog,
  });

  @override
  Future<Map<String, dynamic>?> extractJwt(String token) async {
    try {
      final jwt = JWT.verify(token, SecretKey('secret passphrase'));
      if (jwt.payload['app_secret'] != 'dummy_app_secret') {
        return null;
      }
      return jwt.payload;
    } catch (e) {
      return null;
    }
  }
}

String _prepareHandshake() {
  return jsonEncode(
      CommunicationProtocol(requestType: RequestType.handshake, data: {
    'token': JWT({
      'app_secret': 'dummy_app_secret',
      'school_board_id': 'dummy_school_board_id',
      'user_id': 'dummy_user_id',
      'email': 'john.doe@email.com',
    }).sign(SecretKey('secret passphrase')),
  }).serialize());
}

Future<DatabaseManager> get _mockedDatabase async {
  final schoolBoardsRepository = SchoolBoardsRepositoryMock();
  final adminsRepository = AdminsRepositoryMock();
  final teachersRepository = TeachersRepositoryMock();
  final studentsRepository = StudentsRepositoryMock();
  final enterprisesRepository = EnterprisesRepositoryMock();
  final internshipsRepository = InternshipsRepositoryMock();
  return DatabaseManager(
    sqlInterface: await MySqlInterface.connect(
        connectToDatabase: () async => DummyMySqlConnection(
              schoolBoardsRepository: schoolBoardsRepository,
              adminsRepository: adminsRepository,
              teachersRepository: teachersRepository,
              studentsRepository: studentsRepository,
              enterprisesRepository: enterprisesRepository,
              internshipsRepository: internshipsRepository,
            )),
    schoolBoardsDatabase: schoolBoardsRepository,
    adminsDatabase: adminsRepository,
    teachersDatabase: teachersRepository,
    studentsDatabase: studentsRepository,
    enterprisesDatabase: enterprisesRepository,
    internshipsDatabase: internshipsRepository,
  );
}

Future<CommunicationProtocol> _sendAndReceive({required String toSend}) async {
  final connexions = ConnexionsMock(
      database: await _mockedDatabase, firebaseApiKey: '', skipLog: true);
  final socket = WebSocketMock();
  final client =
      CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
  connexions.add(client);
  socket.streamController.add(_prepareHandshake());

  // Listen to incoming messages from connexions
  final handshakeCompleter = Completer<CommunicationProtocol>();
  final protocolCompleter = Completer<CommunicationProtocol>();
  socket.incommingStreamController.stream.listen((message) {
    final protocol = CommunicationProtocol.deserialize(jsonDecode(message));
    if (protocol.requestType == RequestType.handshake) {
      handshakeCompleter.complete(protocol);
      return;
    }
    protocolCompleter.complete(protocol);
  });
  addTearDown(() => socket.incommingStreamController.close());

  await handshakeCompleter.future.timeout(Duration(seconds: 1), onTimeout: () {
    fail('Timeout waiting for handshake');
  });
  socket.streamController.add(toSend);

  // Wait for the response to be sent to the client
  final protocol = await protocolCompleter.future.timeout(Duration(seconds: 1),
      onTimeout: () => fail('Timeout waiting for protocol update'));
  return protocol;
}

void main() {
  test('Add new client with handshake timeout', () async {
    final connexions = Connexions(
        timeout: Duration(milliseconds: 200),
        database: await _mockedDatabase,
        firebaseApiKey: '',
        skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
    final isConnectedFuture = connexions.add(client);

    final protocolCompleter = Completer<CommunicationProtocol>();
    socket.incommingStreamController.stream.listen((message) {
      protocolCompleter
          .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
    });
    addTearDown(() => socket.incommingStreamController.close());

    // Simulate a timeout
    expect(await isConnectedFuture, false);
    expect(socket.isConnected, false);

    final protocol = await protocolCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocol.requestType, RequestType.response);
    expect(protocol.field, isNull);
    expect(protocol.data, isA<Map<String, dynamic>>());
    expect(protocol.data!['error'], isA<String>());
    expect(protocol.data!['error'], 'Handshake timeout');
    expect(protocol.response, Response.failure);
  });

  test('Request something without sending handshake', () async {
    final connexions = Connexions(
        timeout: Duration(milliseconds: 200),
        database: await _mockedDatabase,
        firebaseApiKey: '',
        skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
    final isConnectedFuture = connexions.add(client);

    final protocolNotVerifiedCompleter = Completer<CommunicationProtocol>();
    final protocolHandshakeCompleter = Completer<CommunicationProtocol>();
    socket.incommingStreamController.stream.listen((message) {
      // The first message should be the refusal of the GET request
      if (!protocolNotVerifiedCompleter.isCompleted) {
        protocolNotVerifiedCompleter
            .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
        return;
      } else if (!protocolHandshakeCompleter.isCompleted) {
        protocolHandshakeCompleter
            .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
        return;
      } else {
        fail('Unexpected third message: $message');
      }
    });
    addTearDown(() => socket.incommingStreamController.close());

    // Simulate a missing handshake
    socket.streamController.add(jsonEncode(
        CommunicationProtocol(requestType: RequestType.get).serialize()));

    final protocolNotVerified = await protocolNotVerifiedCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocolNotVerified.requestType, RequestType.response);
    expect(protocolNotVerified.field, isNull);
    expect(protocolNotVerified.data, isA<Map<String, dynamic>>());
    expect(protocolNotVerified.data!['error'], isA<String>());
    expect(protocolNotVerified.data!['error'], 'Client not verified');
    expect(protocolNotVerified.response, Response.connexionRefused);

    expect(await isConnectedFuture, false);
    expect(socket.isConnected, false);

    final protocolHandshake = await protocolHandshakeCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocolHandshake.requestType, RequestType.response);
    expect(protocolHandshake.field, isNull);
    expect(protocolHandshake.data, isA<Map<String, dynamic>>());
    expect(protocolHandshake.data!['error'], isA<String>());
    expect(protocolHandshake.data!['error'], 'Handshake timeout');
    expect(protocolHandshake.response, Response.failure);
  });

  test('Add new client with missing handshake data request', () async {
    final connexions = Connexions(
        timeout: Duration(milliseconds: 200),
        database: await _mockedDatabase,
        firebaseApiKey: '',
        skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
    final isConnectedFuture = connexions.add(client);

    // Simulate an invalid handshake
    final protocolMissingCompleter = Completer<CommunicationProtocol>();
    final protocolHandshakeCompleter = Completer<CommunicationProtocol>();
    socket.incommingStreamController.stream.listen((message) {
      // The first message should be the rejection of the handshake
      if (!protocolMissingCompleter.isCompleted) {
        protocolMissingCompleter
            .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
        return;
      } else if (!protocolHandshakeCompleter.isCompleted) {
        protocolHandshakeCompleter
            .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
        return;
      } else {
        fail('Unexpected third message: $message');
      }
    });
    addTearDown(() => socket.incommingStreamController.close());

    socket.streamController.add(jsonEncode(
        CommunicationProtocol(requestType: RequestType.handshake).serialize()));

    expect(await isConnectedFuture, false);
    expect(socket.isConnected, false);

    final protocolMissing = await protocolMissingCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocolMissing.requestType, RequestType.response);
    expect(protocolMissing.field, isNull);
    expect(protocolMissing.data, isA<Map<String, dynamic>>());
    expect(protocolMissing.data!['error'], isA<String>());
    expect(protocolMissing.data!['error'],
        'Data is required to validate the handshake');
    expect(protocolMissing.response, Response.connexionRefused);

    final protocolHandshake = await protocolHandshakeCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocolHandshake.requestType, RequestType.response);
    expect(protocolHandshake.field, isNull);
    expect(protocolHandshake.data, isA<Map<String, dynamic>>());
    expect(protocolHandshake.data!['error'], isA<String>());
    expect(protocolHandshake.data!['error'], 'Handshake timeout');
    expect(protocolHandshake.response, Response.failure);
  });

  test('Add new client with missing token', () async {
    final connexions = Connexions(
        timeout: Duration(milliseconds: 200),
        database: await _mockedDatabase,
        firebaseApiKey: '',
        skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
    final isConnectedFuture = connexions.add(client);

    // Simulate an invalid handshake
    final protocolMissingCompleter = Completer<CommunicationProtocol>();
    final protocolHandshakeCompleter = Completer<CommunicationProtocol>();
    socket.incommingStreamController.stream.listen((message) {
      // The first message should be the rejection of the handshake
      if (!protocolMissingCompleter.isCompleted) {
        protocolMissingCompleter
            .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
        return;
      } else if (!protocolHandshakeCompleter.isCompleted) {
        protocolHandshakeCompleter
            .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
        return;
      } else {
        fail('Unexpected third message: $message');
      }
    });
    addTearDown(() => socket.incommingStreamController.close());

    socket.streamController.add(jsonEncode(
        CommunicationProtocol(requestType: RequestType.handshake, data: {})
            .serialize()));

    expect(await isConnectedFuture, false);
    expect(socket.isConnected, false);

    final protocolMissing = await protocolMissingCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocolMissing.requestType, RequestType.response);
    expect(protocolMissing.field, isNull);
    expect(protocolMissing.data, isA<Map<String, dynamic>>());
    expect(protocolMissing.data!['error'], isA<String>());
    expect(protocolMissing.data!['error'],
        'Token is required to validate the handshake');
    expect(protocolMissing.response, Response.connexionRefused);

    final protocolHandshake = await protocolHandshakeCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocolHandshake.requestType, RequestType.response);
    expect(protocolHandshake.field, isNull);
    expect(protocolHandshake.data, isA<Map<String, dynamic>>());
    expect(protocolHandshake.data!['error'], isA<String>());
    expect(protocolHandshake.data!['error'], 'Handshake timeout');
    expect(protocolHandshake.response, Response.failure);
  });

  test('Add new client with invalid token', () async {
    final connexions = Connexions(
        timeout: Duration(milliseconds: 200),
        database: await _mockedDatabase,
        firebaseApiKey: '',
        skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
    final isConnectedFuture = connexions.add(client);

    // Simulate an invalid handshake
    final protocolMissingCompleter = Completer<CommunicationProtocol>();
    final protocolHandshakeCompleter = Completer<CommunicationProtocol>();
    socket.incommingStreamController.stream.listen((message) {
      // The first message should be the rejection of the handshake
      if (!protocolMissingCompleter.isCompleted) {
        protocolMissingCompleter
            .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
        return;
      } else if (!protocolHandshakeCompleter.isCompleted) {
        protocolHandshakeCompleter
            .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
        return;
      } else {
        fail('Unexpected third message: $message');
      }
    });
    addTearDown(() => socket.incommingStreamController.close());

    socket.streamController.add(jsonEncode(
        CommunicationProtocol(requestType: RequestType.handshake, data: {
      'token': JWT({'app_secret': 'invalid'}).sign(SecretKey('invalid'))
    }).serialize()));

    expect(await isConnectedFuture, false);
    expect(socket.isConnected, false);

    final protocolMissing = await protocolMissingCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocolMissing.requestType, RequestType.response);
    expect(protocolMissing.field, isNull);
    expect(protocolMissing.data, isA<Map<String, dynamic>>());
    expect(protocolMissing.data!['error'], isA<String>());
    expect(protocolMissing.data!['error'], 'Invalid token');
    expect(protocolMissing.response, Response.connexionRefused);

    final protocolHandshake = await protocolHandshakeCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocolHandshake.requestType, RequestType.response);
    expect(protocolHandshake.field, isNull);
    expect(protocolHandshake.data, isA<Map<String, dynamic>>());
    expect(protocolHandshake.data!['error'], isA<String>());
    expect(protocolHandshake.data!['error'], 'Handshake timeout');
    expect(protocolHandshake.response, Response.failure);
  });

  test('Add new client with incomplete token', () async {
    final connexions = Connexions(
        timeout: Duration(milliseconds: 200),
        database: await _mockedDatabase,
        firebaseApiKey: '',
        skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
    final isConnectedFuture = connexions.add(client);

    // Simulate an invalid handshake
    final protocolMissingCompleter = Completer<CommunicationProtocol>();
    final protocolHandshakeCompleter = Completer<CommunicationProtocol>();
    socket.incommingStreamController.stream.listen((message) {
      // The first message should be the rejection of the handshake
      if (!protocolMissingCompleter.isCompleted) {
        protocolMissingCompleter
            .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
        return;
      } else if (!protocolHandshakeCompleter.isCompleted) {
        protocolHandshakeCompleter
            .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
        return;
      } else {
        fail('Unexpected third message: $message');
      }
    });
    addTearDown(() => socket.incommingStreamController.close());

    socket.streamController.add(jsonEncode(
        CommunicationProtocol(requestType: RequestType.handshake, data: {
      'token': JWT({
        'app_secret': 'dummy_app_secret',
        'school_board_id': 'dummy_school_board_id',
      }).sign(SecretKey('secret passphrase'))
    }).serialize()));

    expect(await isConnectedFuture, false);
    expect(socket.isConnected, false);

    final protocolMissing = await protocolMissingCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocolMissing.requestType, RequestType.response);
    expect(protocolMissing.field, isNull);
    expect(protocolMissing.data, isA<Map<String, dynamic>>());
    expect(protocolMissing.data!['error'], isA<String>());
    expect(protocolMissing.data!['error'], 'Invalid token');
    expect(protocolMissing.response, Response.connexionRefused);

    final protocolHandshake = await protocolHandshakeCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocolHandshake.requestType, RequestType.response);
    expect(protocolHandshake.field, isNull);
    expect(protocolHandshake.data, isA<Map<String, dynamic>>());
    expect(protocolHandshake.data!['error'], isA<String>());
    expect(protocolHandshake.data!['error'], 'Handshake timeout');
    expect(protocolHandshake.response, Response.failure);
  });

  test('Add a new client to Connexions and disconnect', () async {
    final connexions = ConnexionsMock(
        database: await _mockedDatabase, firebaseApiKey: '', skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);

    // Listen to incoming messages from connexions
    final protocolCompleter = Completer<CommunicationProtocol>();
    socket.incommingStreamController.stream.listen((message) {
      protocolCompleter
          .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
    });
    addTearDown(() => socket.incommingStreamController.close());

    // Send the handshake message
    final isConnectedFuture = connexions.add(client);
    socket.streamController.add(_prepareHandshake());

    expect(await isConnectedFuture, true);
    expect(socket.isConnected, true);
    expect(connexions.clientCount, 1);
    final protocol = await protocolCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocol.requestType, RequestType.handshake);
    expect(protocol.field, isNull);
    expect(protocol.data, isA<Map<String, dynamic>>());
    expect(protocol.data, {
      'user_id': '0',
      'school_board_id': '100',
      'school_id': null,
      'access_level': 2
    });
    expect(protocol.response, Response.success);

    // Simulate a client disconnect
    await socket.close();
    await Future.delayed(Duration(milliseconds: 100));
    expect(connexions.clientCount, 0);
  });

  test('Add a new client to Connexions and experience error', () async {
    final connexions = Connexions(
        database: await _mockedDatabase, firebaseApiKey: '', skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
    connexions.add(client);

    // Send the handshake message
    socket.streamController.add(_prepareHandshake());
    expect(connexions.clientCount, 1);

    // Simulate an error
    socket.streamController.addError('Simulated error');
    await Future.delayed(Duration(milliseconds: 100));
    expect(connexions.clientCount, 0);
  });

  test('New client disconnect during handshake', () async {
    final connexions = Connexions(
        database: await _mockedDatabase, firebaseApiKey: '', skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
    connexions.add(client);

    // The strategy is to send an invalid handshake message to immediately disconnect.
    socket.incommingStreamController.stream.listen((message) => socket.close());
    addTearDown(() => socket.incommingStreamController.close());
    socket.streamController.add('Invalid handshake message');

    // Simulate a client disconnect
    await Future.delayed(Duration(milliseconds: 100));

    expect(connexions.clientCount, 0);
  });

  test('Send a GET request with missing field', () async {
    // Simulate a GET request with missing field
    final protocol = await _sendAndReceive(
        toSend: jsonEncode(CommunicationProtocol(
            requestType: RequestType.get, field: null, data: {}).serialize()));

    expect(protocol.requestType, RequestType.response);
    expect(protocol.field, isNull);
    expect(protocol.data, isA<Map<String, dynamic>>());
    expect(protocol.response, Response.failure);
  });

  test('Send a GET teachers request', () async {
    // Simulate a GET teachers request
    final protocol = await _sendAndReceive(
        toSend: jsonEncode(CommunicationProtocol(
            requestType: RequestType.get,
            field: RequestFields.teachers,
            data: {}).serialize()));

    expect(protocol.requestType, RequestType.response);
    expect(protocol.field, RequestFields.teachers);
    expect(protocol.data, isA<Map<String, dynamic>>());
    expect(protocol.data!['0'], isA<Map<String, dynamic>>());
    expect(protocol.data!['0']['first_name'], isA<String>());
    expect(protocol.data!['0']['first_name'], 'John');
    expect(protocol.data!['0']['last_name'], isA<String>());
    expect(protocol.data!['0']['last_name'], 'Doe');
    expect(protocol.data!['0']['school_id'], isA<String>());
    expect(protocol.data!['0']['school_id'], '10');
    expect(protocol.data!['0']['groups'], isA<List>());
    expect(protocol.data!['0']['groups'], ['100', '101']);
    expect(protocol.data!['0']['phone'], isA<Map>());
    expect(protocol.data!['0']['phone']['phone_number'], '(098) 765-4321');
    expect(protocol.data!['1']['first_name'], isA<String>());
    expect(protocol.data!['1']['first_name'], 'Jane');
    expect(protocol.data!['1']['last_name'], isA<String>());
    expect(protocol.data!['1']['last_name'], 'Doe');
    expect(protocol.response, Response.success);
  });

  test('Send a POST request with missing field', () async {
    // Simulate a POST request with missing field
    final protocol = await _sendAndReceive(
        toSend: jsonEncode(CommunicationProtocol(
            requestType: RequestType.post, field: null, data: {}).serialize()));
    expect(protocol.requestType, RequestType.response);
    expect(protocol.field, isNull);
    expect(protocol.data, isA<Map<String, dynamic>>());
    expect(protocol.response, Response.failure);
  });

  test('Send a POST teacher request and receive the update', () async {
    final connexions = ConnexionsMock(
        database: await _mockedDatabase, firebaseApiKey: '', skipLog: true);
    final socket1 = WebSocketMock();
    final client1 =
        CustomWebSocket(socket: socket1, ipAddress: '127.0.0.1', port: 8080);
    final socket2 = WebSocketMock();
    final client2 =
        CustomWebSocket(socket: socket2, ipAddress: '127.0.0.1', port: 8081);

    connexions.add(client1);
    connexions.add(client2);
    socket1.streamController.add(_prepareHandshake());
    socket2.streamController.add(_prepareHandshake());

    // Listen to incoming messages from connexions
    final handshakeCompleter1 = Completer<CommunicationProtocol>();
    final handshakeCompleter2 = Completer<CommunicationProtocol>();
    final updateCompleter1 = Completer<CommunicationProtocol>();
    final updateCompleter2 = Completer<CommunicationProtocol>();
    socket1.incommingStreamController.stream.listen((message) {
      final protocol1 = CommunicationProtocol.deserialize(jsonDecode(message));
      if (protocol1.requestType == RequestType.handshake) {
        handshakeCompleter1.complete(protocol1);
        return;
      } else if (protocol1.requestType == RequestType.update) {
        updateCompleter1.complete(protocol1);
      }
    });
    socket2.incommingStreamController.stream.listen((message) {
      final protocol2 = CommunicationProtocol.deserialize(jsonDecode(message));
      if (protocol2.requestType == RequestType.handshake) {
        handshakeCompleter2.complete(protocol2);
        return;
      } else if (protocol2.requestType == RequestType.update) {
        updateCompleter2.complete(protocol2);
      }
    });
    addTearDown(() => socket1.incommingStreamController.close());
    addTearDown(() => socket2.incommingStreamController.close());

    await Future.wait([
      handshakeCompleter1.future.timeout(Duration(seconds: 1), onTimeout: () {
        fail('Timeout waiting for handshake 1');
      }),
      handshakeCompleter2.future.timeout(Duration(seconds: 1), onTimeout: () {
        fail('Timeout waiting for handshake 2');
      }),
    ]);

    // Simulate a POST request
    socket1.streamController.add(
      jsonEncode(CommunicationProtocol(
              requestType: RequestType.post,
              field: RequestFields.teacher,
              data: {'id': '1', 'first_name': 'John', 'last_name': 'Smith'})
          .serialize()),
    );

    // Wait for the update to be sent to both clients
    final protocol1 = await updateCompleter1.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol1 update');
    });
    final protocol2 = await updateCompleter2.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol2 update');
    });
    expect(connexions.clientCount, 2);

    expect(protocol1.requestType, RequestType.update);
    expect(protocol1.field, RequestFields.teacher);
    expect(protocol1.data, isA<Map<String, dynamic>>());
    expect(protocol1.data!['updated_fields'],
        ['first_name', 'last_name', 'has_registered_account']);
    expect(protocol1.response, isNull);
    expect(protocol2.requestType, RequestType.update);
    expect(protocol2.field, RequestFields.teacher);
    expect(protocol2.data, isA<Map<String, dynamic>>());
    expect(protocol2.data!['updated_fields'],
        ['first_name', 'last_name', 'has_registered_account']);
    expect(protocol2.response, isNull);
  });

  test('Send an ill-formed message', () async {
    // Simulate an ill-formed message
    final protocol = await _sendAndReceive(toSend: 'ill-formed message');
    expect(protocol.requestType, RequestType.response);
    expect(protocol.field, isNull);
    expect(protocol.data, isA<Map<String, dynamic>>());
    expect(protocol.response, Response.failure);
  });

  test('Send invalid DELETE request', () async {
    // Simulate an invalid DELETE request
    final protocol = await _sendAndReceive(
        toSend: jsonEncode(CommunicationProtocol(
            requestType: RequestType.delete,
            field: null,
            data: {}).serialize()));
    expect(protocol.requestType, RequestType.response);
    expect(protocol.field, isNull);
    expect(protocol.data, isA<Map<String, dynamic>>());
    expect(protocol.response, Response.failure);
  });

  test('Send invalid RESPONSE request', () async {
    // Simulate an invalid RESPONSE request
    final protocol = await _sendAndReceive(
        toSend: jsonEncode(CommunicationProtocol(
            requestType: RequestType.response,
            field: null,
            data: {}).serialize()));

    expect(protocol.requestType, RequestType.response);
    expect(protocol.field, isNull);
    expect(protocol.data, isA<Map<String, dynamic>>());
    expect(protocol.response, Response.failure);
  });
  test('Send invalid UPDATE request', () async {
    final connexions = ConnexionsMock(
        database: await _mockedDatabase, firebaseApiKey: '', skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
    connexions.add(client);
    socket.streamController.add(_prepareHandshake());

    // Listen to incoming messages from connexions
    final handshakeCompleter = Completer<CommunicationProtocol>();
    final protocolCompleter = Completer<CommunicationProtocol>();
    socket.incommingStreamController.stream.listen((message) {
      final protocol = CommunicationProtocol.deserialize(jsonDecode(message));
      if (protocol.requestType == RequestType.handshake) {
        handshakeCompleter.complete(protocol);
        return;
      }
      protocolCompleter
          .complete(CommunicationProtocol.deserialize(jsonDecode(message)));
    });
    addTearDown(() => socket.incommingStreamController.close());
    await handshakeCompleter.future.timeout(Duration(seconds: 1),
        onTimeout: () {
      fail('Timeout waiting for handshake');
    });

    // Simulate an invalid UPDATE request
    socket.streamController.add(
      jsonEncode(CommunicationProtocol(
          requestType: RequestType.update, field: null, data: {}).serialize()),
    );

    // Wait for the response to be sent to the client
    final protocol = await protocolCompleter.future
        .timeout(Duration(seconds: 1), onTimeout: () {
      fail('Timeout waiting for protocol update');
    });
    expect(protocol.requestType, RequestType.response);
    expect(protocol.field, isNull);
    expect(protocol.data, isA<Map<String, dynamic>>());
    expect(protocol.response, Response.failure);
  });

  test('Send a message to a disconnected client', () async {
    final connexions = Connexions(
        database: await _mockedDatabase, firebaseApiKey: '', skipLog: true);
    final socket = WebSocketMock();
    final client =
        CustomWebSocket(socket: socket, ipAddress: '127.0.0.1', port: 8080);
    connexions.add(client);
    socket.streamController.add(_prepareHandshake());

    // Simulate a POST request
    socket.isConnected = false; // Simulate client2 silent disconnection
    socket.streamController.add(
      jsonEncode(CommunicationProtocol(
          requestType: RequestType.post,
          field: RequestFields.teacher,
          data: {'id': '1', 'name': 'John Smith', 'age': 45}).serialize()),
    );

    // Wait for the update to be sent to both clients
    await Future.delayed(Duration(milliseconds: 100));
    expect(connexions.clientCount, 0);
  });
}
