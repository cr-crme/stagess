import 'package:stagess_common/exceptions.dart';
import 'package:uuid/uuid.dart';

enum RequestFields {
  schoolBoard,
  schoolBoards,
  admin,
  admins,
  teacher,
  teachers,
  student,
  students,
  enterprise,
  enterprises,
  internships,
  internship,
}

enum RequestType {
  handshake,
  get,
  post,
  delete,
  response,
  update,
  registerUser,
  unregisterUser,
  getLock,
  releaseLock,
}

enum Response {
  success,
  failure,
  connexionRefused,
}

const String _currentVersion = '1.0.0';

final _uuid = Uuid();

class CommunicationProtocol {
  final String id;
  final String version = _currentVersion;
  final RequestType requestType;
  final RequestFields? field;
  final Map<String, dynamic>? data;
  final Response? response;
  final int? socketId;

  CommunicationProtocol({
    String? id,
    required this.requestType,
    this.field,
    this.data,
    this.response,
    this.socketId,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> serialize() {
    return {
      'id': id,
      'version': version,
      'type': requestType.index,
      'field': field?.index,
      'data': data,
      'response': response?.index,
      'socket_id': socketId,
    };
  }

  static CommunicationProtocol deserialize(Map<String, dynamic> map) {
    if (map['version'] != _currentVersion) {
      throw WrongVersionException(map['version'], _currentVersion);
    }
    return CommunicationProtocol(
      id: map['id'] as String?,
      requestType: RequestType.values[map['type'] as int],
      field: map['field'] != null
          ? RequestFields.values[map['field'] as int]
          : null,
      data: map['data'] as Map<String, dynamic>?,
      response: map['response'] != null
          ? Response.values[map['response'] as int]
          : null,
      socketId: map['socket_id'] as int?,
    );
  }

  CommunicationProtocol copyWith({
    String? id,
    RequestType? requestType,
    RequestFields? field,
    Map<String, dynamic>? data,
    Response? response,
    int? socketId,
  }) {
    return CommunicationProtocol(
      id: id ?? this.id,
      requestType: requestType ?? this.requestType,
      field: field ?? this.field,
      data: data ?? this.data,
      response: response ?? this.response,
      socketId: socketId ?? this.socketId,
    );
  }

  @override
  String toString() {
    return 'CommunicationProtocol(version: $version, requestType: $requestType, field: $field, data: $data, response: $response)';
  }
}
