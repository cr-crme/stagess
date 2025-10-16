import 'package:stagess_backend/repositories/teachers_repository.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:test/test.dart';

import '../mockers/sql_connection_mock.dart';

TeachersRepository get _mockedDatabaseTeachers => TeachersRepositoryMock();

void main() {
  test('Get teachers with insufficient permissions', () async {
    await expectLater(
      _mockedDatabaseTeachers.getAll(user: DatabaseUserMock(isVerified: false)),
      throwsA(isA<InvalidRequestException>()),
    );

    final teachersFromTeacherNoSchoolBoard =
        await _mockedDatabaseTeachers.getAll(
            user: DatabaseUserMock(
                accessLevel: AccessLevel.teacher, schoolBoardId: ''));
    expect(teachersFromTeacherNoSchoolBoard.data, isA<Map<String, dynamic>>());
    expect(teachersFromTeacherNoSchoolBoard.data!.length, 0);

    final teachersFromTeacherWithSchoolBoard = await _mockedDatabaseTeachers
        .getAll(user: DatabaseUserMock(accessLevel: AccessLevel.teacher));
    expect(
        teachersFromTeacherWithSchoolBoard.data, isA<Map<String, dynamic>>());
    expect(teachersFromTeacherWithSchoolBoard.data!.length, 2);

    final teachersFromAdminNoSchoolBoard = await _mockedDatabaseTeachers.getAll(
        user: DatabaseUserMock(
            accessLevel: AccessLevel.admin, schoolBoardId: ''));
    expect(teachersFromAdminNoSchoolBoard.data, isA<Map<String, dynamic>>());
    expect(teachersFromAdminNoSchoolBoard.data!.length, 0);

    final teachersFromAdminWithSchoolBoard = await _mockedDatabaseTeachers
        .getAll(user: DatabaseUserMock(accessLevel: AccessLevel.admin));
    expect(teachersFromAdminWithSchoolBoard.data, isA<Map<String, dynamic>>());
    expect(teachersFromAdminWithSchoolBoard.data!.length, 2);

    final teachersFromSuperAdmin = await _mockedDatabaseTeachers.getAll(
        user: DatabaseUserMock(accessLevel: AccessLevel.superAdmin));
    expect(teachersFromSuperAdmin.data, isA<Map<String, dynamic>>());
    expect(teachersFromSuperAdmin.data!.length, 3);
  });

  test('Get teachers from DatabaseTeachers', () async {
    final teachers =
        await _mockedDatabaseTeachers.getAll(user: DatabaseUserMock());

    expect(teachers.data, isA<Map<String, dynamic>>());
    expect(teachers.data!.length, 2);
    expect(teachers.data!['0'], isA<Map<String, dynamic>>());
    expect(teachers.data!['0']['first_name'], 'John');
    expect(teachers.data!['0']['last_name'], 'Doe');
    expect(teachers.data!['1'], isA<Map<String, dynamic>>());
    expect(teachers.data!['1']['first_name'], 'Jane');
    expect(teachers.data!['1']['last_name'], 'Doe');

    expect(teachers.updatedData, isNull);
    expect(teachers.deletedData, isNull);
  });

  test('Get teacher from DatabaseTeachers', () async {
    final teacher = await _mockedDatabaseTeachers.getById(
      id: '0',
      user: DatabaseUserMock(),
    );
    expect(teacher.data, isA<Map<String, dynamic>>());
    expect(teacher.data!['first_name'], 'John');
    expect(teacher.data!['last_name'], 'Doe');

    expect(teacher.updatedData, isNull);
    expect(teacher.deletedData, isNull);
  });

  test('Get teacher from DatabaseTeachers with invalid id', () async {
    expect(
      () async => await _mockedDatabaseTeachers.getById(
        id: '2',
        user: DatabaseUserMock(),
      ),
      throwsA(predicate((e) =>
          e is MissingDataException && e.toString() == 'Teacher not found')),
    );
  });

  test('Set teacher to DatabaseTeachers with invalid data field', () async {
    expect(
      () async => await _mockedDatabaseTeachers.putById(
        id: '0',
        data: {'name': 'John Doe', 'age': 60, 'invalid_field': 'invalid'},
        user: DatabaseUserMock(),
      ),
      throwsA(predicate((e) =>
          e is InvalidFieldException &&
          e.toString() == 'Invalid field data detected')),
    );
  });

  test('Set teacher to DatabaseTeachers', () async {
    // With insufficient permissions
    await expectLater(
        () async => _mockedDatabaseTeachers.putById(
              id: '0',
              data: {'first_name': 'John', 'last_name': 'Smith'},
              user: DatabaseUserMock(accessLevel: AccessLevel.teacher),
            ),
        throwsA(isA<InvalidRequestException>()));

    // With wrong school board
    await expectLater(
        () async => _mockedDatabaseTeachers.putById(
              id: '0',
              data: {'first_name': 'John', 'last_name': 'Smith'},
              user: DatabaseUserMock(
                  accessLevel: AccessLevel.admin, schoolBoardId: '200'),
            ),
        throwsA(isA<InvalidRequestException>()));

    final mockedDatabase = _mockedDatabaseTeachers;
    await mockedDatabase.putById(
      id: '0',
      data: {'first_name': 'John', 'last_name': 'Smith'},
      user: DatabaseUserMock(accessLevel: AccessLevel.admin),
    );
    final updatedTeacher = await mockedDatabase.getById(
      id: '0',
      user: DatabaseUserMock(accessLevel: AccessLevel.admin),
    );
    expect(updatedTeacher.data!['first_name'], 'John');
    expect(updatedTeacher.data!['last_name'], 'Smith');
  });

  test('Set new teacher to DatabaseTeachers', () async {
    // With insufficient permissions
    await expectLater(
        () async => _mockedDatabaseTeachers.putById(
              id: '2',
              data: {'first_name': 'Agent', 'last_name': 'Smith'},
              user: DatabaseUserMock(accessLevel: AccessLevel.teacher),
            ),
        throwsA(isA<InvalidRequestException>()));
    // With wrong school board
    await expectLater(
        () async => _mockedDatabaseTeachers.putById(
              id: '2',
              data: {'first_name': 'Agent', 'last_name': 'Smith'},
              user: DatabaseUserMock(
                  accessLevel: AccessLevel.admin, schoolBoardId: '200'),
            ),
        throwsA(isA<InvalidRequestException>()));

    final mockedDatabase = _mockedDatabaseTeachers;
    await mockedDatabase.putById(
        id: '2',
        data: {
          'first_name': 'Agent',
          'last_name': 'Smith',
          'school_board_id': '100'
        },
        user: DatabaseUserMock(accessLevel: AccessLevel.admin));
    final newTeacher = await mockedDatabase.getById(
        id: '2', user: DatabaseUserMock(accessLevel: AccessLevel.admin));
    expect(newTeacher.data!['first_name'], 'Agent');
    expect(newTeacher.data!['last_name'], 'Smith');
  });
}
