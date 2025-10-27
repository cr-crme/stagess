import 'dart:typed_data';

import 'package:mysql1/mysql1.dart';
import 'package:stagess_backend/repositories/repository_abstract.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common/services/image_helpers.dart';
import 'package:stagess_common/utils.dart';

abstract class SchoolBoardsRepository extends RepositoryAbstract {
  @override
  Future<RepositoryResponse> getAll({
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to get school boards');
    }

    final schoolBoards = await _getAllSchoolBoards(user: user);
    return RepositoryResponse(
        data: schoolBoards.map(
            (key, value) => MapEntry(key, value.serializeWithFields(fields))));
  }

  @override
  Future<RepositoryResponse> getById({
    required String id,
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to get school boards');
    }

    final schoolBoard = await _getSchoolBoardById(id: id, user: user);
    if (schoolBoard == null) {
      throw MissingDataException('School board not found');
    }

    return RepositoryResponse(data: schoolBoard.serializeWithFields(fields));
  }

  @override
  Future<RepositoryResponse> putById({
    required String id,
    required Map<String, dynamic> data,
    required DatabaseUser user,
    bool tryRequestingLock = true,
  }) async {
    if (user.isNotVerified || user.accessLevel < AccessLevel.admin) {
      throw InvalidRequestException(
          'You do not have permission to put school boards');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock ||
          (await requestLock(user: user, id: id)).data?['locked'] != true) {
        throw InvalidRequestException(
            'You must acquire a lock before editing this school board');
      }
      final response = await putById(
          id: id, data: data, user: user, tryRequestingLock: false);
      await releaseLock(user: user, id: id);
      return response;
    }

    // Update if exists, insert if not
    final previous = await _getSchoolBoardById(id: id, user: user);

    final newSchoolBoard = previous?.copyWithData(data) ??
        SchoolBoard.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    await _putSchoolBoard(
        schoolBoard: newSchoolBoard, previous: previous, user: user);
    return RepositoryResponse(updatedData: {
      RequestFields.schoolBoard: {
        newSchoolBoard.id: SchoolBoard.fetchableFields
            .extractFrom(newSchoolBoard.getDifference(previous))
      }
    });
  }

  @override
  Future<RepositoryResponse> deleteById({
    required String id,
    required DatabaseUser user,
    bool tryRequestingLock = true,
  }) async {
    if (user.isNotVerified || user.accessLevel < AccessLevel.superAdmin) {
      throw InvalidRequestException(
          'You do not have permission to delete school boards');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock ||
          (await requestLock(user: user, id: id)).data?['locked'] != true) {
        throw InvalidRequestException(
            'You must acquire a lock before deleting this school board');
      }
      final response =
          await deleteById(id: id, user: user, tryRequestingLock: false);
      await releaseLock(user: user, id: id);
      return response;
    }

    final removedId = await _deleteSchoolBoard(id: id, user: user);
    if (removedId == null) {
      throw DatabaseFailureException(
          'Failed to delete school board with id: $id');
    }
    return RepositoryResponse(deletedData: {
      RequestFields.schoolBoard: {removedId: FetchableFields.all}
    });
  }

  Future<Map<String, SchoolBoard>> _getAllSchoolBoards({
    required DatabaseUser user,
  });

  Future<SchoolBoard?> _getSchoolBoardById({
    required String id,
    required DatabaseUser user,
  });

  Future<void> _putSchoolBoard({
    required SchoolBoard schoolBoard,
    required SchoolBoard? previous,
    required DatabaseUser user,
  });

  Future<String?> _deleteSchoolBoard({
    required String id,
    required DatabaseUser user,
  });
}

class MySqlSchoolBoardsRepository extends SchoolBoardsRepository {
  // coverage:ignore-start
  final SqlInterface sqlInterface;
  MySqlSchoolBoardsRepository({required this.sqlInterface});

  @override
  Future<Map<String, SchoolBoard>> _getAllSchoolBoards({
    String? schoolBoardId,
    required DatabaseUser user,
  }) async {
    if (user.accessLevel < AccessLevel.superAdmin) {
      // Only super admins can access all school boards
      schoolBoardId ??= user.schoolBoardId;
      if (schoolBoardId != user.schoolBoardId) {
        throw InvalidRequestException(
            'You must be a super admin to access the requested school board');
      }
    }

    final schoolBoards = await sqlInterface.performSelectQuery(
      user: user,
      tableName: 'school_boards',
      filters: schoolBoardId == null ? null : {'id': schoolBoardId},
    );

    final map = <String, SchoolBoard>{};
    for (final schoolBoard in schoolBoards) {
      final id = schoolBoard['id'].toString();

      schoolBoard['logo'] =
          Uint8List.fromList((schoolBoard['logo'] as Blob).toBytes());

      final schools = await sqlInterface.performSelectQuery(
        user: user,
        tableName: 'schools',
        filters: {'school_board_id': id},
      );

      for (final school in schools) {
        final schoolId = school['id'].toString();
        final address = await sqlInterface.performSelectQuery(
          user: user,
          tableName: 'addresses',
          filters: {'entity_id': schoolId},
        );
        school['address'] = address.first;
        final phone = await sqlInterface.performSelectQuery(
          user: user,
          tableName: 'phone_numbers',
          filters: {'entity_id': schoolId},
        );
        school['phone'] = phone.first;
      }
      schoolBoard['schools'] = schools;

      map[id] = SchoolBoard.fromSerialized(schoolBoard);
    }
    return map;
  }

  @override
  Future<SchoolBoard?> _getSchoolBoardById({
    required String id,
    required DatabaseUser user,
  }) async =>
      (await _getAllSchoolBoards(schoolBoardId: id, user: user))[id];

  Future<void> _insertToSchoolBoards(SchoolBoard schoolBoard,
      {required DatabaseUser user}) async {
    if (user.accessLevel < AccessLevel.superAdmin) {
      throw InvalidRequestException(
          'You must be a super admin to create a school board');
    }

    // Insert the school board
    await sqlInterface.performInsertQuery(
        tableName: 'entities', data: {'shared_id': schoolBoard.id});
    await sqlInterface.performInsertQuery(tableName: 'school_boards', data: {
      'id': schoolBoard.id,
      'name': schoolBoard.name,
      'logo': schoolBoard.logo.isEmpty
          ? schoolBoard.logo
          : ImageHelpers.resizeImage(schoolBoard.logo,
              width: null, height: ImageHelpers.logoHeight),
      'cnesst_number': schoolBoard.cnesstNumber
    });
  }

  Future<void> _updateToSchoolBoards(
    SchoolBoard schoolBoard,
    SchoolBoard previous, {
    required DatabaseUser user,
  }) async {
    final differences = schoolBoard.getDifference(previous);
    final isOkay = differences.isEmpty ||
        user.accessLevel >= AccessLevel.superAdmin ||
        (user.accessLevel == AccessLevel.admin &&
            schoolBoard.id == user.schoolBoardId);
    if (!isOkay) {
      throw InvalidRequestException(
          'You must be an admin to update a school board');
    }

    final toUpdate = <String, dynamic>{};
    if (differences.contains('name')) {
      toUpdate['name'] = schoolBoard.name.serialize();
    }
    if (differences.contains('cnesst_number')) {
      toUpdate['cnesst_number'] = schoolBoard.cnesstNumber.serialize();
    }
    if (differences.contains('logo')) {
      toUpdate['logo'] = schoolBoard.logo.isEmpty
          ? schoolBoard.logo
          : ImageHelpers.resizeImage(schoolBoard.logo,
              width: null, height: ImageHelpers.logoHeight);
    }

    if (toUpdate.isNotEmpty) {
      await sqlInterface.performUpdateQuery(
        tableName: 'school_boards',
        filters: {'id': schoolBoard.id},
        data: toUpdate,
      );
    }
  }

  Future<void> _insertToSchools(School school, SchoolBoard schoolBoard,
      {required DatabaseUser user}) async {
    final isOkay = user.accessLevel >= AccessLevel.superAdmin ||
        (user.accessLevel == AccessLevel.admin &&
            schoolBoard.id == user.schoolBoardId);
    if (!isOkay) {
      throw InvalidRequestException('You must be a admin to create a school');
    }

    await sqlInterface.performInsertQuery(
        tableName: 'entities', data: {'shared_id': school.id});
    await sqlInterface.performInsertQuery(tableName: 'schools', data: {
      'id': school.id.serialize(),
      'school_board_id': schoolBoard.id.serialize(),
      'name': school.name.serialize(),
    });

    await sqlInterface.performInsertAddress(
        address: school.address, entityId: school.id);

    await sqlInterface.performInsertPhoneNumber(
        phoneNumber: school.phone, entityId: school.id);
  }

  Future<void> _updateToSchools(School school, School previous,
      {required SchoolBoard schoolBoard, required DatabaseUser user}) async {
    final toUpdate = school.getDifference(previous);
    final isOkay = toUpdate.isEmpty ||
        user.accessLevel >= AccessLevel.superAdmin ||
        (user.accessLevel == AccessLevel.admin &&
            schoolBoard.id == user.schoolBoardId);
    if (!isOkay) {
      throw InvalidRequestException(
          'You must be a valid admin to update a school');
    }

    if (toUpdate.contains('name')) {
      await sqlInterface.performUpdateQuery(
        tableName: 'schools',
        filters: {'id': school.id.serialize()},
        data: {'name': school.name.serialize()},
      );
    }
    if (toUpdate.contains('address')) {
      await sqlInterface.performUpdateAddress(
        address: school.address,
        previous: previous.address,
      );
    }
    if (toUpdate.contains('phone')) {
      await sqlInterface.performUpdatePhoneNumber(
        phoneNumber: school.phone,
        previous: previous.phone,
      );
    }
  }

  @override
  Future<void> _putSchoolBoard({
    required SchoolBoard schoolBoard,
    required SchoolBoard? previous,
    required DatabaseUser user,
  }) async {
    if (previous == null) {
      await _insertToSchoolBoards(schoolBoard, user: user);
    } else {
      await _updateToSchoolBoards(schoolBoard, previous, user: user);
    }

    // Insert the schools
    final toWait = <Future>[];
    for (final school in schoolBoard.schools) {
      final previousSchool =
          previous?.schools.firstWhereOrNull((e) => e.id == school.id);
      if (previousSchool == null) {
        toWait.add(_insertToSchools(school, schoolBoard, user: user));
      } else {
        toWait.add(_updateToSchools(school, previousSchool,
            schoolBoard: schoolBoard, user: user));
      }
    }

    // Remove the schools that are not in the new list
    for (final school in previous?.schools ?? <School>[]) {
      if (!schoolBoard.schools.any((e) => e.id == school.id)) {
        toWait.add(_deleteFromSchools(school.id, user: user));
      }
    }

    await Future.wait(toWait);
  }

  Future<void> _deleteFromSchools(String schoolId,
      {required DatabaseUser user}) async {
    if (user.accessLevel < AccessLevel.superAdmin) {
      throw InvalidRequestException(
          'You must be a super admin to delete a school');
    }

    await sqlInterface.performDeleteQuery(
      tableName: 'entities',
      filters: {'shared_id': schoolId},
    );
  }

  @override
  Future<String?> _deleteSchoolBoard({
    required String id,
    required DatabaseUser user,
  }) async {
    if (user.accessLevel < AccessLevel.superAdmin) {
      throw InvalidRequestException(
          'You must be a super admin to delete a school board');
    }

    try {
      final schools = await sqlInterface.performSelectQuery(
        user: user,
        tableName: 'schools',
        filters: {'school_board_id': id},
      );
      for (final school in schools) {
        await _deleteFromSchools(school['id'].toString(), user: user);
      }

      await sqlInterface.performDeleteQuery(
        tableName: 'entities',
        filters: {'shared_id': id},
      );

      return id;
    } catch (e) {
      return null;
    }
  }
}

class SchoolBoardsRepositoryMock extends SchoolBoardsRepository {
  // Simulate a database with a map
  final _dummyDatabase = {
    '0': SchoolBoard(
        id: '0',
        name: 'This one',
        logo: null,
        schools: [],
        cnesstNumber: '1234567890'),
    '1': SchoolBoard(
        id: '1',
        name: 'This second',
        logo: null,
        schools: [],
        cnesstNumber: '0987654321'),
  };

  @override
  Future<Map<String, SchoolBoard>> _getAllSchoolBoards({
    required DatabaseUser user,
  }) async =>
      _dummyDatabase;

  @override
  Future<SchoolBoard?> _getSchoolBoardById({
    required String id,
    required DatabaseUser user,
  }) async =>
      _dummyDatabase[id];

  @override
  Future<void> _putSchoolBoard({
    required SchoolBoard schoolBoard,
    required SchoolBoard? previous,
    required DatabaseUser user,
  }) async =>
      _dummyDatabase[schoolBoard.id] = schoolBoard;

  @override
  Future<String?> _deleteSchoolBoard({
    required String id,
    required DatabaseUser user,
  }) async {
    if (_dummyDatabase.containsKey(id)) {
      _dummyDatabase.remove(id);
      return id;
    }
    return null;
  }
}
