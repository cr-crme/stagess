import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/server/database_manager.dart';
import 'package:stagess_backend/utils/custom_web_socket.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_backend/utils/network_rate_limiter.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/utils.dart';

final _logger = Logger('Connections');

class Connections {
  final Map<CustomWebSocket, DatabaseUser> _clients = {};
  int get clientCount => _clients.length;
  final DatabaseManager _database;
  DatabaseManager get database => _database;
  final Duration _timeout;
  final String _firebaseApiKey;
  final bool skipLog;

  // coverage:ignore-start
  Connections(
      {Duration timeout = const Duration(seconds: 5),
      required DatabaseManager database,
      required String firebaseApiKey,
      required this.skipLog})
      : _timeout = timeout,
        _database = database,
        _firebaseApiKey = firebaseApiKey;
  // coverage:ignore-end

  Future<bool> add(
    CustomWebSocket client, {
    NetworkRateLimiter? rateLimiter,
  }) async {
    try {
      _clients[client] = DatabaseUser.empty();

      client.listen(
          (message) => _incomingMessage(client,
              message: message, rateLimiter: rateLimiter),
          onDone: () =>
              _onConnectionClosed(client, message: 'Client disconnected'),
          onError: (error) =>
              _onConnectionClosed(client, message: 'Connection error $error'));

      final startTime = DateTime.now();
      while (_clients[client]?.isNotVerified ?? true) {
        await Future.delayed(Duration(milliseconds: 100));

        // If client disconnected before the handshake was completed
        if (!_clients.containsKey(client)) return false;
        if (startTime.add(_timeout).isBefore(DateTime.now())) {
          throw ConnectionRefusedException('Handshake timeout');
        }
      }

      // Disconnect other connections the same user might have
      final currentId = _clients[client]!.userId;
      final clientKeys = _clients.keys.toList();
      for (final otherClient in clientKeys) {
        final otherId = _clients[otherClient]?.userId;
        if (otherClient == client || otherId != currentId) continue;

        _logger.info('Closing duplicate connection of user $currentId');
        try {
          await _send(otherClient,
              message: CommunicationProtocol(
                  requestType: RequestType.disconnectRequest,
                  field: null,
                  data: {'error': 'Duplicate connection'}));
        } catch (e) {
          _logger.warning(
              'Failed to send disconnect request to duplicate connection: $e');
        }

        try {
          await _onConnectionClosed(otherClient,
              message: 'Closing duplicate connection');
        } catch (e) {
          _logger.warning(
              'Failed to close duplicate connection. Manually removing client from active connections. Error: $e');
          _clients.remove(otherClient);
        }
      }
    } catch (e) {
      await _refuseConnection(client, e.toString());
      return false;
    }

    return true;
  }

  Future<void> _incomingMessage(
    CustomWebSocket client, {
    required dynamic message,
    required NetworkRateLimiter? rateLimiter,
  }) async {
    CommunicationProtocol? protocol;
    try {
      // Control the rate of incoming messages to prevent abuse and DoS attacks
      if (rateLimiter != null && rateLimiter.isRefused(client.ipAddress)) {
        throw RateLimitedException();
      }

      // Control type and size of the messages to prevent abuse and DoS attacks
      if (message is! String) {
        throw InvalidRequestTypeException('Invalid message format');
      }
      if (message.isEmpty) {
        throw InvalidRequestTypeException('Empty message');
      } else if (message.length > 10 * 1024 * 1024) {
        // 10 MB limit
        throw InvalidRequestTypeException('Message too long');
      }

      final map = jsonDecode(message);
      protocol = CommunicationProtocol.deserialize(map);

      // Prevent unauthorized access to the database
      if ((_clients[client]?.isNotVerified ?? true) &&
          protocol.requestType != RequestType.handshake) {
        throw ConnectionRefusedException('Client not verified');
      }

      switch (protocol.requestType) {
        case RequestType.handshake:
          await _handleHandshake(client, protocol: protocol);
          break;

        case RequestType.getLock:
        case RequestType.releaseLock:
        case RequestType.get:
        case RequestType.post:
        case RequestType.delete:
          await _handleDatabaseRequest(client: client, protocol: protocol);
          break;

        case RequestType.registerUser:
          await _handleRegisterUser(client: client, protocol: protocol);
          break;

        case RequestType.unregisterUser:
          await _handleUnregisterUser(client: client, protocol: protocol);
          break;

        case RequestType.disconnectRequest:
        case RequestType.response:
        case RequestType.update:
          throw InvalidRequestTypeException(
              'Invalid request type: ${protocol.requestType}');
      }
    } on ConnectionRefusedException catch (e) {
      if (!skipLog) {
        _logger.info(
            'Refusing connection of client (${client.hashCode}:${_clients[client]?.userId}, ip=${client.ipAddress}:${client.port}): $e');
      }
      await _send(client,
          message: CommunicationProtocol(
              id: protocol?.id,
              field: protocol?.field,
              requestType: RequestType.response,
              data: {'error': 'Connection refused'},
              response: Response.connectionRefused));
    } on InternshipBankException catch (e, st) {
      if (!skipLog) {
        _logger.severe(
            'Error while processing request from client (${client.hashCode}:${_clients[client]?.userId}, ip=${client.ipAddress}:${client.port})',
            e,
            st);
      }
      await _send(client,
          message: CommunicationProtocol(
              id: protocol?.id,
              field: protocol?.field,
              requestType: RequestType.response,
              data: {'error': 'Invalid request'},
              response: Response.failure));
    } catch (e, st) {
      if (!skipLog) {
        _logger.severe(
          'Internal error while processing request from client '
          '(${client.hashCode}:${_clients[client]?.userId}, ip=${client.ipAddress}:${client.port})',
          e,
          st,
        );
      }
      await _send(client,
          message: CommunicationProtocol(
              id: protocol?.id,
              field: protocol?.field,
              requestType: RequestType.response,
              data: {'error': 'Invalid request'},
              response: Response.failure));
    }
  }

  Future<void> _handleRegisterUser({
    required CustomWebSocket client,
    required CommunicationProtocol protocol,
  }) async {
    final myAccessLevel = _clients[client]?.accessLevel ?? AccessLevel.invalid;
    final email = protocol.data?['email'] as String?;
    final userType = AccessLevel.fromSerialized(protocol.data?['user_type']);
    if (email == null || userType == AccessLevel.invalid) {
      throw ConnectionRefusedException('Invalid request data.');
    }

    final app = FirebaseAdmin.instance.app();
    if (app == null) {
      throw ConnectionRefusedException(
          'Firebase app is not initialized. Please check your configuration.');
    }

    // Get the related user data
    late Map<String, dynamic>? user;
    switch (userType) {
      case AccessLevel.teacher:
        if (myAccessLevel < AccessLevel.schoolAdmin) {
          throw ConnectionRefusedException(
              'Client is not authorized to register user');
        }
        user = await _getTeacherFromDatabase(
            user: _clients[client]!,
            sqlInterface: _database.sqlInterface,
            email: email);
        break;
      case AccessLevel.schoolAdmin:
        if (myAccessLevel < AccessLevel.schoolBoardAdmin) {
          throw ConnectionRefusedException(
              'Client is not authorized to register user');
        }
        user = await _getAdminFromDatabase(
            user: _clients[client]!,
            sqlInterface: _database.sqlInterface,
            email: email);
        break;
      case AccessLevel.schoolBoardAdmin:
        if (myAccessLevel < AccessLevel.superAdmin) {
          throw ConnectionRefusedException(
              'Client is not authorized to register user');
        }
        user = await _getAdminFromDatabase(
            user: _clients[client]!,
            sqlInterface: _database.sqlInterface,
            email: email);
        break;
      case AccessLevel.superAdmin:
      case AccessLevel.self:
      case AccessLevel.invalid:
        throw ConnectionRefusedException(
            'Client is not authorized to register user.');
    }

    // Make sure only previously added teachers can be registered
    if (user == null) {
      throw ConnectionRefusedException(
          'No user found with email $email. Please add the user to the database before registering them.');
    }

    // Register the user in Firebase
    try {
      await app.auth().createUser(email: email, emailVerified: false);
      await _sendPasswordResetEmail(email, _firebaseApiKey);
    } on FirebaseAuthError catch (e) {
      if (e.code == 'auth/email-already-exists') {
        // Continue as it means the user is registered but might need to reset their password
      } else {
        rethrow;
      }
    }

    // Send a reset password email to the user
    await _sendPasswordResetEmail(email, _firebaseApiKey);

    // Send confirmation to the client
    await _send(client,
        message: CommunicationProtocol(
            id: protocol.id,
            requestType: RequestType.response,
            field: protocol.field,
            response: Response.success));

    // Add the confirmation to the database
    final field = switch (userType) {
      AccessLevel.teacher => RequestFields.teacher,
      AccessLevel.schoolAdmin ||
      AccessLevel.schoolBoardAdmin =>
        RequestFields.admin,
      AccessLevel.superAdmin ||
      AccessLevel.self ||
      AccessLevel.invalid =>
        throw 'Client is not authorized to register user.',
    };
    await _database.put(field,
        data: {'id': user['id'], 'has_registered_account': true},
        user: _clients[client]!);

    // Notify all clients that the teacher has registered an account
    await _sendAll(CommunicationProtocol(
      requestType: RequestType.update,
      field: field,
      data: {
        'id': user['id'],
        'updated_fields': ['has_registered_account']
      },
    ));

    if (!skipLog) {
      _logger.info(
          'Client (${client.hashCode}:${_clients[client]?.userId}) has registered user $email');
    }
  }

  Future<void> _handleUnregisterUser({
    required CustomWebSocket client,
    required CommunicationProtocol protocol,
  }) async {
    final myAccessLevel = _clients[client]?.accessLevel ?? AccessLevel.invalid;
    final email = protocol.data?['email'] as String?;
    final userType = AccessLevel.fromSerialized(protocol.data?['user_type']);
    if (email == null || userType == AccessLevel.invalid) {
      throw ConnectionRefusedException('Invalid request data.');
    }

    final app = FirebaseAdmin.instance.app();
    if (app == null) {
      throw ConnectionRefusedException(
          'Firebase app is not initialized. Please check your configuration.');
    }

    // Delete the user from Firebase
    try {
      final user = await app.auth().getUserByEmail(email);
      await app.auth().deleteUser(user.uid);
    } on FirebaseAuthError catch (e) {
      if (e.code == 'auth/user-not-found') {
        // Continue as it means the user is not registered
      } else {
        rethrow;
      }
    }
    // Send confirmation to the client
    await _send(client,
        message: CommunicationProtocol(
            id: protocol.id,
            requestType: RequestType.response,
            field: protocol.field,
            response: Response.success));

    // Adjust the internal database to reflect the unregistration
    late Map<String, dynamic>? user;
    switch (userType) {
      case AccessLevel.teacher:
        if (myAccessLevel < AccessLevel.schoolAdmin) {
          throw ConnectionRefusedException(
              'Client is not authorized to register user');
        }
        user = await _getTeacherFromDatabase(
            user: _clients[client]!,
            sqlInterface: _database.sqlInterface,
            email: email);
        break;
      case AccessLevel.schoolAdmin:
        if (myAccessLevel < AccessLevel.schoolBoardAdmin) {
          throw ConnectionRefusedException(
              'Client is not authorized to register user');
        }
        user = await _getAdminFromDatabase(
            user: _clients[client]!,
            sqlInterface: _database.sqlInterface,
            email: email);
        break;
      case AccessLevel.schoolBoardAdmin:
        if (myAccessLevel < AccessLevel.superAdmin) {
          throw ConnectionRefusedException(
              'Client is not authorized to register user');
        }
        user = await _getAdminFromDatabase(
            user: _clients[client]!,
            sqlInterface: _database.sqlInterface,
            email: email);
        break;
      case AccessLevel.superAdmin:
      case AccessLevel.self:
      case AccessLevel.invalid:
        throw ConnectionRefusedException(
            'Client is not authorized to register user.');
    }

    if (user != null) {
      // Remove the confirmation from the database
      final field = switch (userType) {
        AccessLevel.teacher => RequestFields.teacher,
        AccessLevel.schoolAdmin ||
        AccessLevel.schoolBoardAdmin =>
          RequestFields.admin,
        AccessLevel.superAdmin ||
        AccessLevel.self ||
        AccessLevel.invalid =>
          throw 'Client is not authorized to register user.',
      };

      await _database.put(field,
          data: {'id': user['id'], 'has_registered_account': false},
          user: _clients[client]!);
      // Notify all clients that the teacher has unregistered an account
      await _sendAll(CommunicationProtocol(
        requestType: RequestType.update,
        field: field,
        data: {
          'id': user['id'],
          'updated_fields': ['has_registered_account']
        },
      ));
    }

    if (!skipLog) {
      _logger.info(
          'Client (${client.hashCode}:${_clients[client]?.userId}) has unregistered user $email');
    }
  }

  Future<void> _handleDatabaseRequest({
    required CustomWebSocket client,
    required CommunicationProtocol protocol,
  }) async {
    if (protocol.field == null) {
      throw MissingFieldException(
          'Field is required to ${protocol.requestType.name} data');
    }

    final response = switch (protocol.requestType) {
      RequestType.get => await _database.get(protocol.field!,
          data: protocol.data, user: _clients[client]!),
      RequestType.post => await _database.put(protocol.field!,
          data: protocol.data, user: _clients[client]!),
      RequestType.delete => await _database.delete(protocol.field!,
          data: protocol.data, user: _clients[client]!),
      RequestType.getLock => await _database.getLock(protocol.field!,
          data: protocol.data, user: _clients[client]!),
      RequestType.releaseLock => await _database.releaseLock(protocol.field!,
          data: protocol.data, user: _clients[client]!),
      _ => throw InvalidRequestTypeException(
          'Invalid request type: ${protocol.requestType}'),
    };

    if (!skipLog) {
      final method = switch (protocol.requestType) {
        RequestType.get => 'get-requested',
        RequestType.post => 'post-requested',
        RequestType.delete => 'delete-requested',
        RequestType.getLock => 'get-lock-requested',
        RequestType.releaseLock => 'release-lock-requested',
        _ => 'invalid-requested',
      };
      final request = protocol.data?['id'] != null
          ? 'id=${protocol.data!['id']}'
          : 'all elements';
      final field = switch (protocol.field!) {
        RequestFields.none => throw MissingFieldException(
            'Field is required to ${protocol.requestType.name} data'),
        RequestFields.schoolBoards ||
        RequestFields.schoolBoard =>
          'school boards',
        RequestFields.admins || RequestFields.admin => 'admins',
        RequestFields.teachers || RequestFields.teacher => 'teachers',
        RequestFields.students || RequestFields.student => 'students',
        RequestFields.enterprises || RequestFields.enterprise => 'enterprises',
        RequestFields.internships || RequestFields.internship => 'internships',
      };
      _logger.info(
          'Client (${client.hashCode}:${_clients[client]?.userId}) has $method $request of $field');
    }

    await _send(client,
        message: CommunicationProtocol(
            id: protocol.id,
            requestType: RequestType.response,
            field: protocol.field,
            data: response.data,
            response: Response.success));

    // Notify all clients for the fields that were updated, but do not send the
    // actual new data. The client must request it for security reasons
    for (final field in response.updatedData?.keys ?? <RequestFields>[]) {
      for (final updatedId in response.updatedData![field]!.keys) {
        final updateFields = response.updatedData![field]![updatedId];
        if (updateFields?.isEmpty ?? true) continue;

        await _sendAll(CommunicationProtocol(
          requestType: RequestType.update,
          field: field,
          data: {'id': updatedId, 'updated_fields': updateFields!.serialized},
        ));
      }
    }

    // Notify all clients for the fields that were deleted
    for (final field in response.deletedData?.keys ?? <RequestFields>[]) {
      for (final deletedId in response.deletedData![field]!.keys) {
        final deletedFields = response.deletedData![field]![deletedId];
        if (deletedFields?.isEmpty ?? true) continue;

        await _sendAll(CommunicationProtocol(
          requestType: RequestType.delete,
          field: field,
          data: {'id': deletedId, 'deleted_fields': deletedFields!.serialized},
        ));
      }
    }
  }

  Future<void> _send(CustomWebSocket client,
      {required CommunicationProtocol message}) async {
    try {
      client.add(
          jsonEncode(message.copyWith(socketId: client.hashCode).serialize()));
    } catch (e) {
      // If we can't send the message, we can assume the client is disconnected
      await _onConnectionClosed(client,
          message: 'Connection closed unexpectedly: $e');
    }
  }

  Future<void> _sendAll(CommunicationProtocol message) async {
    for (final client in _clients.keys) {
      _send(client, message: message);
    }
  }

  Future<void> _handleHandshake(CustomWebSocket client,
      {required CommunicationProtocol protocol}) async {
    if (protocol.data == null) {
      throw ConnectionRefusedException(
          'Data is required to validate the handshake');
    }
    if (protocol.data!['token'] == null) {
      throw ConnectionRefusedException(
          'Token is required to validate the handshake');
    }

    final payload = await extractJwt(protocol.data!['token']);
    if (payload == null) {
      throw ConnectionRefusedException('Invalid token');
    }
    final authenticatorId = payload['user_id'] as String?;
    final email = payload['email'] as String?;
    if (authenticatorId == null || email == null) {
      throw ConnectionRefusedException('Invalid token payload');
    }

    // Get the user information from the database to first verify its identity
    late final DatabaseUser? user;
    try {
      user = await getValidatedUser(_database.sqlInterface,
          id: authenticatorId, email: email);
    } catch (e) {
      user = null;
    }
    if (user == null) throw ConnectionRefusedException('Invalid user');
    _clients[client] = user;

    // Success, send the handshake to the client
    if (!skipLog) {
      _logger.info('Client (${client.hashCode}:${_clients[client]?.userId}, '
          'ip=${client.ipAddress}:${client.port}) has successfully '
          'connected as ${_clients[client]!.accessLevel.name} '
          'for school board ${_clients[client]!.schoolBoardId} '
          'and school ${_clients[client]!.schoolId}');
    }
    await _send(client,
        message: CommunicationProtocol(
            requestType: RequestType.handshake,
            response: Response.success,
            data: _clients[client]!.serialize()));
  }

  Future<void> _refuseConnection(CustomWebSocket client, String message) async {
    await _send(client,
        message: CommunicationProtocol(
            requestType: RequestType.response,
            field: null,
            data: {'error': 'Connection refused'},
            response: Response.failure));
    await _onConnectionClosed(client, message: message);
  }

  Future<void> _onConnectionClosed(CustomWebSocket client,
      {required String message}) async {
    if (!skipLog) {
      _logger.info(
          'Closing connection of client (${client.hashCode}:${_clients[client]?.userId}, ip=${client.ipAddress}:${client.port}): $message');
    }

    await client.close();
    _clients.remove(client);
  }

  Future<Map<String, dynamic>?> extractJwt(String token) async {
    try {
      var jwt = JWT.decode(token);
      final kid = jwt.header?['kid'];
      if (kid == null) return null;

      // The "kid" is generated by the Google service on the Firebase behalf. We
      // can check that this kid is valid to ensure that the JWT is from the
      // Firebase service.
      final keyResponse = await http.get(Uri.parse(
          'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'));
      if (keyResponse.statusCode != 200) return null;
      final keys = jsonDecode(keyResponse.body) as Map<String, dynamic>;
      if (!keys.containsKey(kid)) return null;
      final pemKey = keys[kid] as String?;
      if (pemKey?.isEmpty ?? false) return null;
      final jwk = RSAPublicKey.cert(pemKey!);

      // Verify the JWT with the public key
      jwt = JWT.verify(token, jwk); // Throws if verification fails

      // Step 4: Validate claims
      final projectName = 'stagess-39d8f';
      if (jwt.payload['aud'] != projectName) return null;

      if (jwt.payload['iss'] != 'https://securetoken.google.com/$projectName') {
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (jwt.payload['exp'] < now) return null;

      // If we reach this point, the JWT is valid
      return jwt.payload;
    } catch (e) {
      return null;
    }
  }

  Future<DatabaseUser?> getValidatedUser(SqlInterface sqlInterface,
      {required String id, required String email}) async {
    // There are 3 possible cases:
    // 1. The user has previously connected so they will be in the 'users' table.
    //    We can retrieve their information from there and return it.
    // 2. The user has never connected before, but was added to the teachers database.
    //    We can retrieve their information from the 'teachers' table and provide
    //    them with an AccessLevel of 'user', register them in the 'users' table
    //    and return the user.
    // 3. The user has never connected before, and is not in the teachers database.
    //    This is probably someone who is not supposed to be using the app, so we
    //    return null to indicate that the user is not valid.

    // Slowly build the user object as we go through the cases
    var user = DatabaseUser.empty(authenticatorId: id);

    // At this point, we know the JWT is valid and secure. So we can safely use the email
    // to fetch the user information.
    // First, try to login via the 'users' table
    var users = await _getAdminFromDatabase(
        user: user, sqlInterface: sqlInterface, email: email);

    user = user.copyWith(
      userId: users?['id'],
      schoolBoardId: users?['school_board_id'],
      schoolId: users?['school_id'],
      accessLevel: AccessLevel.fromSerialized(users?['access_level']),
    );
    // This will be true if the user is an admin or a super admin
    if (user.isVerified) return user;

    // If there is information missing in the user structure, then we are not admin (case 1)
    // We therefore try to log using the information from the 'teachers' table
    final teacher = await _getTeacherFromDatabase(
        user: user, sqlInterface: sqlInterface, email: email);
    // If there is no teacher with that email, the user is not valid (case 3)
    if (teacher == null) return null;
    (teacher as Map).addAll((teacher['teachers'] as List).firstOrNull);

    // Otherwise, we probably are logging in a teacher (case 2
    user = user.copyWith(
      userId: teacher['id'],
      schoolBoardId: teacher['school_board_id'],
      schoolId: teacher['school_id'],
      accessLevel: AccessLevel.teacher,
    );

    // Just make sure, even though at this point it should always be verified
    if (user.isNotVerified) return null;
    return user;
  }
}

Future<Map<String, dynamic>?> _getTeacherFromDatabase(
    {required DatabaseUser user,
    required SqlInterface sqlInterface,
    required String email}) async {
  final teacher = (await sqlInterface.performSelectQuery(
          user: user.copyWith(accessLevel: AccessLevel.superAdmin),
          tableName: 'users',
          fieldsToFetch: [
        'email'
      ],
          filters: {
        'email': email
      },
          subqueries: [
        sqlInterface.selectSubquery(
          dataTableName: 'teachers',
          idNameToDataTable: 'id',
          fieldsToFetch: [
            'id',
            'school_board_id',
            'school_id',
            'has_registered_account',
          ],
        ),
      ]) as List)
      .firstOrNull;
  if (teacher == null || teacher['teachers'] == null) return null;

  (teacher as Map).addAll((teacher['teachers'] as List).firstOrNull);
  return teacher as Map<String, dynamic>?;
}

Future<Map<String, dynamic>?> _getAdminFromDatabase(
    {required DatabaseUser user,
    required SqlInterface sqlInterface,
    required String email}) async {
  final userFromDatabase = (await sqlInterface.performSelectQuery(
    user: DatabaseUser.empty().copyWith(accessLevel: AccessLevel.superAdmin),
    tableName: 'users',
    filters: {'email': email},
    subqueries: [
      sqlInterface.selectSubquery(
          dataTableName: 'admins',
          idNameToDataTable: 'id',
          fieldsToFetch: [
            'school_board_id',
            'school_id',
            'has_registered_account',
            'access_level'
          ]),
    ],
  ) as List)
      .firstOrNull as Map<String, dynamic>?;

  // If not an admin, return null
  if ((userFromDatabase?['admins'] as List?)?.isEmpty ?? true) return null;

  userFromDatabase?.addAll(
      (userFromDatabase['admins'] as List).first as Map<String, dynamic>);
  return userFromDatabase;
}

Future<void> _sendPasswordResetEmail(String email, String apiKey) async {
  final uri = Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$apiKey',
  );

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'requestType': 'PASSWORD_RESET',
      'email': email,
    }),
  );

  if (response.statusCode != 200) {
    throw ConnectionRefusedException('Failed to send password reset email');
  }
}
