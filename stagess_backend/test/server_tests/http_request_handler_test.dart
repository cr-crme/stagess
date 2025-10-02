import 'package:stagess_backend/repositories/admins_repository.dart';
import 'package:stagess_backend/repositories/enterprises_repository.dart';
import 'package:stagess_backend/repositories/internships_repository.dart';
import 'package:stagess_backend/repositories/school_boards_repository.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/repositories/students_repository.dart';
import 'package:stagess_backend/repositories/teachers_repository.dart';
import 'package:stagess_backend/server/connexions.dart';
import 'package:stagess_backend/server/database_manager.dart';
import 'package:stagess_backend/server/http_request_handler.dart';
import 'package:test/test.dart';

import '../mockers/http_request_mock.dart';
import '../mockers/sql_connection_mock.dart';

Future<Connexions> get _mockedConnexions async => Connexions(
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
        devConnexions: await _mockedConnexions,
        productionConnexions: await _mockedConnexions);
    await requestHandler.answer(request);

    final response = request.response as HttpResponseMock;
    final responseHeaders = response.headers as HttpHeadersMock;
    expect(responseHeaders.current.length, 3);
    expect(responseHeaders.current['Access-Control-Allow-Origin'], '*');
    expect(responseHeaders.current['Access-Control-Allow-Methods'],
        'GET, OPTIONS');
    expect(responseHeaders.current['Access-Control-Allow-Headers'],
        'Content-Type, Authorization');
  });

  test('Send a POST request', () async {
    final request = HttpRequestMock(method: 'POST', uri: Uri.parse('/'));
    final requestHandler = HttpRequestHandler(
        devConnexions: await _mockedConnexions,
        productionConnexions: await _mockedConnexions);
    await requestHandler.answer(request);

    final response = request.response as HttpResponseMock;
    expect(response.response, 'Unauthorized');
  });

  test('Send a GET resquest to an invalid endpoit', () async {
    final request = HttpRequestMock(method: 'GET', uri: Uri.parse('/'));
    final requestHandler = HttpRequestHandler(
        devConnexions: await _mockedConnexions,
        productionConnexions: await _mockedConnexions);
    await requestHandler.answer(request);

    final response = request.response as HttpResponseMock;
    expect(response.response, 'Unauthorized: Invalid endpoint');
  });

  test('Simulate internal error while connecting', () async {
    final request = HttpRequestMock(
        method: 'GET',
        uri: Uri.parse('/connect'),
        forceFailToUpgradeToWebSocket: true);
    final requestHandler = HttpRequestHandler(
        devConnexions: await _mockedConnexions,
        productionConnexions: await _mockedConnexions);
    await requestHandler.answer(request);

    final response = request.response as HttpResponseMock;
    expect(response.response, 'Unauthorized: WebSocket upgrade failed');
  });

  test('Send a GET request to the /connect endpoint', () async {
    final request = HttpRequestMock(method: 'GET', uri: Uri.parse('/connect'));
    final requestHandler = HttpRequestHandler(
        devConnexions: await _mockedConnexions,
        productionConnexions: await _mockedConnexions);
    await requestHandler.answer(request);

    // This test creates a true WebSocket connection (as opposed to a mock)
    // so we cannot check if the response is correct. But returning a null
    // response is a good indication that the connection was successful.
    final response = request.response as HttpResponseMock;
    expect(response.response, null);
  });
}
