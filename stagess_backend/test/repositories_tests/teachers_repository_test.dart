import 'package:stagess_backend/repositories/teachers_repository.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:test/test.dart';

import '../mockers/sql_connection_mock.dart';

TeachersRepository get _mockedDatabaseTeachers => TeachersRepositoryMock();

void main() {
  test('Get teachers with insufficient permissions', () async {
    await expectLater(
      _mockedDatabaseTeachers.getAll(
          user: DatabaseUserMock(isVerified: false),
          fields: FetchableFields.all),
      throwsA(isA<InvalidRequestException>()),
    );

    final teachersFromTeacherNoSchoolBoard =
        await _mockedDatabaseTeachers.getAll(
            user: DatabaseUserMock(
                accessLevel: AccessLevel.teacher, schoolBoardId: ''),
            fields: FetchableFields.all);
    expect(teachersFromTeacherNoSchoolBoard.data, isA<Map<String, dynamic>>());
    expect(teachersFromTeacherNoSchoolBoard.data!.length, 0);

    final teachersFromTeacherWithSchoolBoard =
        await _mockedDatabaseTeachers.getAll(
            user: DatabaseUserMock(accessLevel: AccessLevel.teacher),
            fields: FetchableFields.all);
    expect(
        teachersFromTeacherWithSchoolBoard.data, isA<Map<String, dynamic>>());
    expect(teachersFromTeacherWithSchoolBoard.data!.length, 2);

    final teachersFromSchoolAdminNoSchool =
        await _mockedDatabaseTeachers.getAll(
            user: DatabaseUserMock(
                accessLevel: AccessLevel.schoolAdmin, schoolId: ''),
            fields: FetchableFields.all);
    expect(teachersFromSchoolAdminNoSchool.data, isA<Map<String, dynamic>>());
    expect(teachersFromSchoolAdminNoSchool.data!.length, 0);

    final teachersFromSchoolAdminNoSchoolBoard =
        await _mockedDatabaseTeachers.getAll(
            user: DatabaseUserMock(
                accessLevel: AccessLevel.schoolAdmin, schoolBoardId: ''),
            fields: FetchableFields.all);
    expect(
        teachersFromSchoolAdminNoSchoolBoard.data, isA<Map<String, dynamic>>());
    expect(teachersFromSchoolAdminNoSchoolBoard.data!.length, 0);

    final teachersFromSchoolBoardAdminNoSchoolBoard =
        await _mockedDatabaseTeachers.getAll(
            user: DatabaseUserMock(
                accessLevel: AccessLevel.schoolBoardAdmin, schoolBoardId: ''),
            fields: FetchableFields.all);
    expect(teachersFromSchoolBoardAdminNoSchoolBoard.data,
        isA<Map<String, dynamic>>());
    expect(teachersFromSchoolBoardAdminNoSchoolBoard.data!.length, 0);

    final teachersFromSchoolBoardAdminWithSchoolBoard =
        await _mockedDatabaseTeachers.getAll(
            user: DatabaseUserMock(accessLevel: AccessLevel.schoolBoardAdmin),
            fields: FetchableFields.all);
    expect(teachersFromSchoolBoardAdminWithSchoolBoard.data,
        isA<Map<String, dynamic>>());
    expect(teachersFromSchoolBoardAdminWithSchoolBoard.data!.length, 2);

    final teachersFromSuperAdmin = await _mockedDatabaseTeachers.getAll(
        user: DatabaseUserMock(accessLevel: AccessLevel.superAdmin),
        fields: FetchableFields.all);
    expect(teachersFromSuperAdmin.data, isA<Map<String, dynamic>>());
    expect(teachersFromSuperAdmin.data!.length, 3);
  });

  test('Get teachers from DatabaseTeachers', () async {
    final teachers = await _mockedDatabaseTeachers.getAll(
        user: DatabaseUserMock(), fields: FetchableFields.all);

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
        id: '0', user: DatabaseUserMock(), fields: FetchableFields.all);
    expect(teacher.data, isA<Map<String, dynamic>>());
    expect(teacher.data!['first_name'], 'John');
    expect(teacher.data!['last_name'], 'Doe');

    expect(teacher.updatedData, isNull);
    expect(teacher.deletedData, isNull);
  });

  test('Get teacher from DatabaseTeachers with invalid id', () async {
    expect(
      () async => await _mockedDatabaseTeachers.getById(
          id: '2', user: DatabaseUserMock(), fields: FetchableFields.all),
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

    // With wrong school
    await expectLater(
        () async => _mockedDatabaseTeachers.putById(
              id: '0',
              data: {'first_name': 'John', 'last_name': 'Smith'},
              user: DatabaseUserMock(
                  accessLevel: AccessLevel.schoolAdmin, schoolId: '300'),
            ),
        throwsA(isA<InvalidRequestException>()));

    // With wrong school board
    await expectLater(
        () async => _mockedDatabaseTeachers.putById(
              id: '0',
              data: {'first_name': 'John', 'last_name': 'Smith'},
              user: DatabaseUserMock(
                  accessLevel: AccessLevel.schoolBoardAdmin,
                  schoolBoardId: '200'),
            ),
        throwsA(isA<InvalidRequestException>()));

    final mockedDatabase = _mockedDatabaseTeachers;
    await mockedDatabase.putById(
      id: '0',
      data: {'first_name': 'John', 'last_name': 'Smith'},
      user: DatabaseUserMock(accessLevel: AccessLevel.schoolAdmin),
    );
    final updatedTeacher1 = await mockedDatabase.getById(
        id: '0',
        user: DatabaseUserMock(accessLevel: AccessLevel.schoolAdmin),
        fields: FetchableFields.all);
    expect(updatedTeacher1.data!['first_name'], 'John');
    expect(updatedTeacher1.data!['last_name'], 'Smith');

    await mockedDatabase.putById(
      id: '0',
      data: {'first_name': 'Jonathan', 'last_name': 'Smithy'},
      user: DatabaseUserMock(accessLevel: AccessLevel.schoolAdmin),
    );
    final updatedTeacher2 = await mockedDatabase.getById(
        id: '0',
        user: DatabaseUserMock(accessLevel: AccessLevel.schoolAdmin),
        fields: FetchableFields.all);
    expect(updatedTeacher2.data!['first_name'], 'Jonathan');
    expect(updatedTeacher2.data!['last_name'], 'Smithy');
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

    // With wrong school
    await expectLater(
        () async => _mockedDatabaseTeachers.putById(
              id: '2',
              data: {'first_name': 'Agent', 'last_name': 'Smith'},
              user: DatabaseUserMock(
                  accessLevel: AccessLevel.schoolAdmin, schoolId: '300'),
            ),
        throwsA(isA<InvalidRequestException>()));

    // With wrong school board
    await expectLater(
        () async => _mockedDatabaseTeachers.putById(
              id: '2',
              data: {'first_name': 'Agent', 'last_name': 'Smith'},
              user: DatabaseUserMock(
                  accessLevel: AccessLevel.schoolBoardAdmin,
                  schoolBoardId: '200'),
            ),
        throwsA(isA<InvalidRequestException>()));

    final mockedDatabase = _mockedDatabaseTeachers;
    await mockedDatabase.putById(
        id: '2',
        data: {
          'first_name': 'Agent',
          'last_name': 'Smith',
          'school_board_id': '100',
          'school_id': '200'
        },
        user: DatabaseUserMock(accessLevel: AccessLevel.schoolAdmin));
    final newTeacher1 = await mockedDatabase.getById(
        id: '2',
        user: DatabaseUserMock(accessLevel: AccessLevel.schoolAdmin),
        fields: FetchableFields.all);
    expect(newTeacher1.data!['first_name'], 'Agent');
    expect(newTeacher1.data!['last_name'], 'Smith');

    await mockedDatabase.putById(
        id: '3',
        data: {
          'first_name': 'Agente',
          'last_name': 'Smithy',
          'school_board_id': '100',
          'school_id': '200'
        },
        user: DatabaseUserMock(accessLevel: AccessLevel.schoolBoardAdmin));
    final newTeacher2 = await mockedDatabase.getById(
        id: '3',
        user: DatabaseUserMock(accessLevel: AccessLevel.schoolBoardAdmin),
        fields: FetchableFields.all);
    expect(newTeacher2.data!['first_name'], 'Agente');
    expect(newTeacher2.data!['last_name'], 'Smithy');
  });
}
