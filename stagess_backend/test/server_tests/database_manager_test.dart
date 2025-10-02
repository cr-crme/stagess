import 'package:stagess_backend/repositories/admins_repository.dart';
import 'package:stagess_backend/repositories/enterprises_repository.dart';
import 'package:stagess_backend/repositories/internships_repository.dart';
import 'package:stagess_backend/repositories/school_boards_repository.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/repositories/students_repository.dart';
import 'package:stagess_backend/repositories/teachers_repository.dart';
import 'package:stagess_backend/server/database_manager.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:test/test.dart';

import '../mockers/sql_connection_mock.dart';

SchoolBoardsRepository get _mockedDatabaseSchoolBoards =>
    SchoolBoardsRepositoryMock();
AdminsRepository get _mockedAdminsDatabase => AdminsRepositoryMock();
TeachersRepository get _mockedDatabaseTeachers => TeachersRepositoryMock();
StudentsRepository get _mockedDatabaseStudents => StudentsRepositoryMock();
EnterprisesRepository get _mockedDatabaseEnterprises =>
    EnterprisesRepositoryMock();
InternshipsRepository get _mockedDatabaseInternships =>
    InternshipsRepositoryMock();

void main() {
  test('Get teachers from DatabaseManagers', () async {
    final database = DatabaseManager(
      sqlInterface: await MySqlInterface.connect(
          connectToDatabase: () async => DummyMySqlConnection()),
      schoolBoardsDatabase: _mockedDatabaseSchoolBoards,
      adminsDatabase: _mockedAdminsDatabase,
      teachersDatabase: _mockedDatabaseTeachers,
      studentsDatabase: _mockedDatabaseStudents,
      enterprisesDatabase: _mockedDatabaseEnterprises,
      internshipsDatabase: _mockedDatabaseInternships,
    );
    final teachers = await database.get(
      RequestFields.teachers,
      data: null,
      user: DatabaseUser.empty(),
    );
    expect(teachers.data, isA<Map<String, dynamic>>());
    expect(teachers.data!.length, 2);
    expect(teachers.data!['0'], isA<Map<String, dynamic>>());
    expect(teachers.data!['0']['first_name'], 'John');
    expect(teachers.data!['0']['last_name'], 'Doe');
    expect(teachers.data!['1'], isA<Map<String, dynamic>>());
    expect(teachers.data!['1']['first_name'], 'Jane');
    expect(teachers.data!['1']['last_name'], 'Doe');
  });

  test('Get teacher from DatabaseManagers', () async {
    final database = DatabaseManager(
      sqlInterface: await MySqlInterface.connect(
          connectToDatabase: () async => DummyMySqlConnection()),
      schoolBoardsDatabase: _mockedDatabaseSchoolBoards,
      adminsDatabase: _mockedAdminsDatabase,
      teachersDatabase: _mockedDatabaseTeachers,
      studentsDatabase: _mockedDatabaseStudents,
      enterprisesDatabase: _mockedDatabaseEnterprises,
      internshipsDatabase: _mockedDatabaseInternships,
    );
    final teacher = await database.get(
      RequestFields.teacher,
      data: {'id': '0'},
      user: DatabaseUser.empty(),
    );
    expect(teacher, isA<Map<String, dynamic>>());
    expect(teacher.data!['first_name'], 'John');
    expect(teacher.data!['last_name'], 'Doe');
  });

  test('Get teacher from DatabaseManagers with invalid id', () async {
    final database = DatabaseManager(
      sqlInterface: await MySqlInterface.connect(
          connectToDatabase: () async => DummyMySqlConnection()),
      schoolBoardsDatabase: _mockedDatabaseSchoolBoards,
      adminsDatabase: _mockedAdminsDatabase,
      teachersDatabase: _mockedDatabaseTeachers,
      studentsDatabase: _mockedDatabaseStudents,
      enterprisesDatabase: _mockedDatabaseEnterprises,
      internshipsDatabase: _mockedDatabaseInternships,
    );
    expect(
      () async => await database.get(
        RequestFields.teacher,
        data: {'id': '2'},
        user: DatabaseUser.empty(),
      ),
      throwsA(predicate((e) =>
          e is MissingDataException && e.toString() == 'Teacher not found')),
    );
  });

  test('Get teacher from DatabaseManagers without id', () async {
    final database = DatabaseManager(
      sqlInterface: await MySqlInterface.connect(
          connectToDatabase: () async => DummyMySqlConnection()),
      schoolBoardsDatabase: _mockedDatabaseSchoolBoards,
      adminsDatabase: _mockedAdminsDatabase,
      teachersDatabase: _mockedDatabaseTeachers,
      studentsDatabase: _mockedDatabaseStudents,
      enterprisesDatabase: _mockedDatabaseEnterprises,
      internshipsDatabase: _mockedDatabaseInternships,
    );
    expect(
      () async => await database.get(
        RequestFields.teacher,
        data: null,
        user: DatabaseUser.empty(),
      ),
      throwsA(predicate((e) =>
          e is MissingFieldException &&
          e.toString() == 'An "id" is required to get a teacher')),
    );
  });

  test('Put without data in DatabaseManagers', () async {
    final database = DatabaseManager(
      sqlInterface: await MySqlInterface.connect(
          connectToDatabase: () async => DummyMySqlConnection()),
      schoolBoardsDatabase: _mockedDatabaseSchoolBoards,
      adminsDatabase: _mockedAdminsDatabase,
      teachersDatabase: _mockedDatabaseTeachers,
      studentsDatabase: _mockedDatabaseStudents,
      enterprisesDatabase: _mockedDatabaseEnterprises,
      internshipsDatabase: _mockedDatabaseInternships,
    );
    expect(
      () async => await database.put(
        RequestFields.teachers,
        data: null,
        user: DatabaseUser.empty(),
      ),
      throwsA(predicate((e) =>
          e is MissingDataException &&
          e.toString() == 'Data is required to put something')),
    );
  });

  test('Set all teachers to DatabaseManagers', () async {
    final database = DatabaseManager(
      sqlInterface: await MySqlInterface.connect(
          connectToDatabase: () async => DummyMySqlConnection()),
      schoolBoardsDatabase: _mockedDatabaseSchoolBoards,
      adminsDatabase: _mockedAdminsDatabase,
      teachersDatabase: _mockedDatabaseTeachers,
      studentsDatabase: _mockedDatabaseStudents,
      enterprisesDatabase: _mockedDatabaseEnterprises,
      internshipsDatabase: _mockedDatabaseInternships,
    );
    expect(
      () async => await database.put(
        RequestFields.teachers,
        data: {'0': 'John Doe'},
        user: DatabaseUser.empty(),
      ),
      throwsA(predicate((e) =>
          e is InvalidRequestException &&
          e.toString() == 'Teachers must be created individually')),
    );
  });

  test('Set teacher to DatabaseManagers', () async {
    final database = DatabaseManager(
      sqlInterface: await MySqlInterface.connect(
          connectToDatabase: () async => DummyMySqlConnection()),
      schoolBoardsDatabase: _mockedDatabaseSchoolBoards,
      adminsDatabase: _mockedAdminsDatabase,
      teachersDatabase: _mockedDatabaseTeachers,
      studentsDatabase: _mockedDatabaseStudents,
      enterprisesDatabase: _mockedDatabaseEnterprises,
      internshipsDatabase: _mockedDatabaseInternships,
    );
    await database.put(
      RequestFields.teacher,
      data: {'id': '0', 'first_name': 'John', 'last_name': 'Smith'},
      user: DatabaseUser.empty(),
    );
    final updatedTeacher = await database.get(
      RequestFields.teacher,
      data: {'id': '0'},
      user: DatabaseUser.empty(),
    );
    expect(updatedTeacher.data!['first_name'], 'John');
    expect(updatedTeacher.data!['last_name'], 'Smith');
  });

  test('Set new teacher to DatabaseManagers', () async {
    final database = DatabaseManager(
      sqlInterface: await MySqlInterface.connect(
          connectToDatabase: () async => DummyMySqlConnection()),
      schoolBoardsDatabase: _mockedDatabaseSchoolBoards,
      adminsDatabase: _mockedAdminsDatabase,
      teachersDatabase: _mockedDatabaseTeachers,
      studentsDatabase: _mockedDatabaseStudents,
      enterprisesDatabase: _mockedDatabaseEnterprises,
      internshipsDatabase: _mockedDatabaseInternships,
    );
    await database.put(
      RequestFields.teacher,
      data: {'id': '2', 'first_name': 'Agent', 'last_name': 'Smith'},
      user: DatabaseUser.empty(),
    );
    final newTeacher = await database.get(
      RequestFields.teacher,
      data: {'id': '2'},
      user: DatabaseUser.empty(),
    );
    expect(newTeacher.data!['first_name'], 'Agent');
    expect(newTeacher.data!['last_name'], 'Smith');
  });

  test('Set teacher to DatabaseManagers without id', () async {
    final database = DatabaseManager(
      sqlInterface: await MySqlInterface.connect(
          connectToDatabase: () async => DummyMySqlConnection()),
      schoolBoardsDatabase: _mockedDatabaseSchoolBoards,
      adminsDatabase: _mockedAdminsDatabase,
      teachersDatabase: _mockedDatabaseTeachers,
      studentsDatabase: _mockedDatabaseStudents,
      enterprisesDatabase: _mockedDatabaseEnterprises,
      internshipsDatabase: _mockedDatabaseInternships,
    );
    expect(
      () async => await database.put(
        RequestFields.teacher,
        data: {'name': 'John Smith', 'age': 45},
        user: DatabaseUser.empty(),
      ),
      throwsA(predicate((e) =>
          e is MissingFieldException &&
          e.toString() == 'An "id" is required to put a teacher')),
    );
  });
}
