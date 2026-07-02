import 'package:stagess_backend/repositories/admins_repository.dart';
import 'package:stagess_backend/repositories/enterprises_repository.dart';
import 'package:stagess_backend/repositories/internships_repository.dart';
import 'package:stagess_backend/repositories/school_boards_repository.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/repositories/students_repository.dart';
import 'package:stagess_backend/repositories/teachers_repository.dart';
import 'package:stagess_backend/server/connections.dart';
import 'package:stagess_backend/server/database_manager.dart';
import 'package:stagess_backend/server/http_request_handler.dart';
import 'package:test/test.dart';

import '../mockers/http_request_mock.dart';
import '../mockers/sql_connection_mock.dart';

Future<Connections> get _mockedConnections async => Connections(
      database: DatabaseManager(
        sqlInterface: await MySqlInterface.connect(
            connectToDatabase: () async => DummyMySqlConnection()),
        schoolBoardsDatabase: SchoolBoardsRepositoryMock(),
        adminsDatabase: AdminsRepositoryMock(),
        teachersDatabase: TeachersRepositoryMock(),
        studentsDatabase: StudentsRepositoryMock(),
        enterprisesDatabase: EnterprisesRepositoryMock(),
        internshipsDatabase: InternshipsRepositoryMock(),
      ),
      firebaseApiKey: '',
      skipLog: true,
    );

void main() {
  test('Send an a preflight request', () async {
    final request = HttpRequestMock(method: 'OPTIONS', uri: Uri.parse('/'));
    final requestHandler = HttpRequestHandler(
        devConnections: await _mockedConnections,
        productionConnections: await _mockedConnections);
    await requestHandler.answer(request);

    final response = request.response as HttpResponseMock;
    final responseHeaders = response.headers as HttpHeadersMock;
    expect(responseHeaders.current.length, 0);
  });

  test('Send a POST request', () async {
    final request = HttpRequestMock(method: 'POST', uri: Uri.parse('/'));
    final requestHandler = HttpRequestHandler(
        devConnections: await _mockedConnections,
        productionConnections: await _mockedConnections);
    await requestHandler.answer(request);

    final response = request.response as HttpResponseMock;
    expect(response.response, 'Connection refused');
  });

  test('Send a GET resquest to an invalid endpoit', () async {
    final request = HttpRequestMock(method: 'GET', uri: Uri.parse('/'));
    final requestHandler = HttpRequestHandler(
        devConnections: await _mockedConnections,
        productionConnections: await _mockedConnections);
    await requestHandler.answer(request);

    final response = request.response as HttpResponseMock;
    expect(response.response, 'Connection refused');
  });

  test('Simulate internal error while connecting', () async {
    final request = HttpRequestMock(
        method: 'GET',
        uri: Uri.parse('/connect'),
        forceFailToUpgradeToWebSocket: true);
    final requestHandler = HttpRequestHandler(
        devConnections: await _mockedConnections,
        productionConnections: await _mockedConnections);
    await requestHandler.answer(request);

    final response = request.response as HttpResponseMock;
    expect(response.response, 'Connection refused');
  });

  test('Send a GET request to the /connect endpoint', () async {
    final request = HttpRequestMock(method: 'GET', uri: Uri.parse('/connect'));
    final requestHandler = HttpRequestHandler(
        devConnections: await _mockedConnections,
        productionConnections: await _mockedConnections);
    await requestHandler.answer(request);

    final response = request.response as HttpResponseMock;
    expect(response.response, 'Connection refused');
  });
}
