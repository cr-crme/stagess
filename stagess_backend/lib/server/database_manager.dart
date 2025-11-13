import 'package:stagess_backend/repositories/admins_repository.dart';
import 'package:stagess_backend/repositories/enterprises_repository.dart';
import 'package:stagess_backend/repositories/internships_repository.dart';
import 'package:stagess_backend/repositories/repository_abstract.dart';
import 'package:stagess_backend/repositories/school_boards_repository.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/repositories/students_repository.dart';
import 'package:stagess_backend/repositories/teachers_repository.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';

String _getId(Map<String, dynamic>? data, {required String messageOnNull}) {
  final id = data?['id']?.toString();
  if (id == null || id.isEmpty) throw MissingFieldException(messageOnNull);
  return id;
}

class DatabaseManager {
  DatabaseManager({
    required SqlInterface sqlInterface,
    required this.schoolBoardsDatabase,
    required this.adminsDatabase,
    required this.teachersDatabase,
    required this.studentsDatabase,
    required this.enterprisesDatabase,
    required this.internshipsDatabase,
  }) : _sqlInterface = sqlInterface;

  final SqlInterface? _sqlInterface;
  SqlInterface get sqlInterface => _sqlInterface!;
  final SchoolBoardsRepository schoolBoardsDatabase;
  final AdminsRepository adminsDatabase;
  final TeachersRepository teachersDatabase;
  final StudentsRepository studentsDatabase;
  final EnterprisesRepository enterprisesDatabase;
  final InternshipsRepository internshipsDatabase;

  Future<RepositoryResponse> get(
    RequestFields field, {
    required Map<String, dynamic>? data,
    required DatabaseUser user,
  }) async {
    final fields = FetchableFields.fromSerialized(
        data?['fields'] as Map<String, dynamic>?);
    if (fields.isEmpty) {
      throw MissingFieldException('Fields are required to get data');
    }

    final response = switch (field) {
      RequestFields.schoolBoards =>
        await schoolBoardsDatabase.getAll(fields: fields, user: user),
      RequestFields.schoolBoard => await schoolBoardsDatabase.getById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get a school board'),
          fields: fields,
          user: user),
      RequestFields.admins =>
        await adminsDatabase.getAll(fields: fields, user: user),
      RequestFields.admin => await adminsDatabase.getById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get an admin'),
          fields: fields,
          user: user),
      RequestFields.teachers =>
        await teachersDatabase.getAll(fields: fields, user: user),
      RequestFields.teacher => await teachersDatabase.getById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get a teacher'),
          fields: fields,
          user: user),
      RequestFields.students =>
        await studentsDatabase.getAll(fields: fields, user: user),
      RequestFields.student => await studentsDatabase.getById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get a student'),
          fields: fields,
          user: user),
      RequestFields.enterprises =>
        await enterprisesDatabase.getAll(fields: fields, user: user),
      RequestFields.enterprise => await enterprisesDatabase.getById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get an enterprise'),
          fields: fields,
          user: user),
      RequestFields.internships =>
        await internshipsDatabase.getAll(fields: fields, user: user),
      RequestFields.internship => await internshipsDatabase.getById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get an internship'),
          fields: fields,
          user: user),
    };

    if (response.data == null) {
      throw MissingDataException('No data found for the requested field');
    }
    if (response.updatedData != null) {
      throw InvalidRequestException(
          'You cannot update data with a GET request');
    }
    if (response.deletedData != null) {
      throw InvalidRequestException(
          'You cannot delete data with a GET request');
    }
    return response;
  }

  Future<RepositoryResponse> put(
    RequestFields field, {
    required Map<String, dynamic>? data,
    required DatabaseUser user,
  }) async {
    if (data == null) {
      throw MissingDataException('Data is required to put something');
    }

    final response = switch (field) {
      RequestFields.schoolBoards => throw InvalidRequestException(
          'School boards must be created individually'),
      RequestFields.schoolBoard => await schoolBoardsDatabase.putById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to put a school board'),
          data: data,
          user: user,
        ),
      RequestFields.admins => throw InvalidRequestException(
          'Administrators must be created individually'),
      RequestFields.admin => await adminsDatabase.putById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to put an admin'),
          data: data,
          user: user,
        ),
      RequestFields.teachers =>
        throw InvalidRequestException('Teachers must be created individually'),
      RequestFields.teacher => await teachersDatabase.putById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to put a teacher'),
          data: data,
          user: user,
        ),
      RequestFields.students =>
        throw InvalidRequestException('Students must be created individually'),
      RequestFields.student => await studentsDatabase.putById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to put a student'),
          data: data,
          user: user,
        ),
      RequestFields.enterprises => throw InvalidRequestException(
          'Enterprises must be created individually'),
      RequestFields.enterprise => await enterprisesDatabase.putById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to put an enterprise'),
          data: data,
          user: user,
          internshipsRepository: internshipsDatabase,
        ),
      RequestFields.internships => throw InvalidRequestException(
          'Internships must be created individually'),
      RequestFields.internship => await internshipsDatabase.putById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to put an internship'),
          data: data,
          user: user,
        ),
    };

    if (response.updatedData == null || response.updatedData!.isEmpty) {
      throw InvalidRequestException('No data was updated with the PUT request');
    }
    if (response.data != null) {
      throw InvalidRequestException('You cannot get data with a PUT request');
    }
    return response;
  }

  Future<RepositoryResponse> delete(
    RequestFields field, {
    required Map<String, dynamic>? data,
    required DatabaseUser user,
  }) async {
    final response = switch (field) {
      RequestFields.schoolBoards => throw InvalidRequestException(
          'School boards must be deleted individually'),
      RequestFields.schoolBoard => await schoolBoardsDatabase.deleteById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to delete a school board'),
          user: user,
        ),
      RequestFields.admins => throw InvalidRequestException(
          'Adminisntrators must be deleted individually'),
      RequestFields.admin => await adminsDatabase.deleteById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to delete an admin'),
          user: user,
        ),
      RequestFields.teachers =>
        throw InvalidRequestException('Teachers must be deleted individually'),
      RequestFields.teacher => await teachersDatabase.deleteById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to delete a teacher'),
          user: user,
        ),
      RequestFields.students =>
        throw InvalidRequestException('Students must be deleted individually'),
      RequestFields.student => await studentsDatabase.deleteById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to delete a student'),
          user: user,
        ),
      RequestFields.enterprises => throw InvalidRequestException(
          'Enterprises must be deleted individually'),
      RequestFields.enterprise => await enterprisesDatabase.deleteById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to delete an enterprise'),
          user: user,
          internshipsRepository: internshipsDatabase,
        ),
      RequestFields.internships => throw InvalidRequestException(
          'Internships must be deleted individually'),
      RequestFields.internship => await internshipsDatabase.deleteById(
          id: _getId(data,
              messageOnNull: 'An "id" is required to delete an internship'),
          user: user,
        ),
    };

    if (response.deletedData == null || response.deletedData!.isEmpty) {
      throw InvalidRequestException(
          'No data was deleted with the DELETE request');
    }
    if (response.data != null) {
      throw InvalidRequestException(
          'You cannot get data with a DELETE request');
    }
    return response;
  }

  Future<RepositoryResponse> getLock(
    RequestFields field, {
    required Map<String, dynamic>? data,
    required DatabaseUser user,
  }) async {
    final response = switch (field) {
      RequestFields.schoolBoards => throw InvalidRequestException(
          'School boards must be locked individually'),
      RequestFields.schoolBoard => await schoolBoardsDatabase.requestLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get a school board'),
          user: user),
      RequestFields.admins => throw InvalidRequestException(
          'Administrators must be locked individually'),
      RequestFields.admin => await adminsDatabase.requestLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get an admin'),
          user: user),
      RequestFields.teachers =>
        throw InvalidRequestException('Teachers must be locked individually'),
      RequestFields.teacher => await teachersDatabase.requestLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get a teacher'),
          user: user),
      RequestFields.students =>
        throw InvalidRequestException('Students must be locked individually'),
      RequestFields.student => await studentsDatabase.requestLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get a student'),
          user: user),
      RequestFields.enterprises => throw InvalidRequestException(
          'Enterprises must be locked individually'),
      RequestFields.enterprise => await enterprisesDatabase.requestLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get an enterprise'),
          user: user),
      RequestFields.internships => throw InvalidRequestException(
          'Internships must be locked individually'),
      RequestFields.internship => await internshipsDatabase.requestLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get an internship'),
          user: user),
    };

    return response;
  }

  Future<RepositoryResponse> releaseLock(
    RequestFields field, {
    required Map<String, dynamic>? data,
    required DatabaseUser user,
  }) async {
    final response = switch (field) {
      RequestFields.schoolBoards => throw InvalidRequestException(
          'School boards must be locked individually'),
      RequestFields.schoolBoard => await schoolBoardsDatabase.releaseLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get a school board'),
          user: user),
      RequestFields.admins => throw InvalidRequestException(
          'Administrators must be locked individually'),
      RequestFields.admin => await adminsDatabase.releaseLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get an admin'),
          user: user),
      RequestFields.teachers =>
        throw InvalidRequestException('Teachers must be locked individually'),
      RequestFields.teacher => await teachersDatabase.releaseLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get a teacher'),
          user: user),
      RequestFields.students =>
        throw InvalidRequestException('Students must be locked individually'),
      RequestFields.student => await studentsDatabase.releaseLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get a student'),
          user: user),
      RequestFields.enterprises => throw InvalidRequestException(
          'Enterprises must be locked individually'),
      RequestFields.enterprise => await enterprisesDatabase.releaseLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get an enterprise'),
          user: user),
      RequestFields.internships => throw InvalidRequestException(
          'Internships must be locked individually'),
      RequestFields.internship => await internshipsDatabase.releaseLock(
          id: _getId(data,
              messageOnNull: 'An "id" is required to get an internship'),
          user: user),
    };

    if (response.data?['released'] != true) {
      throw InvalidRequestException('Could not release lock');
    }
    return response;
  }
}
