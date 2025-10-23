import 'package:stagess_backend/repositories/repository_abstract.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common/utils.dart';

// AccessLevel in this repository is discarded as all operations are currently
// available to all users

abstract class AdminsRepository extends RepositoryAbstract {
  @override
  Future<RepositoryResponse> getAll({
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    if (user.accessLevel < AccessLevel.superAdmin) {
      throw InvalidRequestException(
          'You do not have permission to get all administrators');
    }

    final admins = await _getAllAdmins(user: user);
    return RepositoryResponse(
        data: admins.map(
            (key, value) => MapEntry(key, value.serializeWithFields(fields))));
  }

  @override
  Future<RepositoryResponse> getById({
    required String id,
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    if (user.accessLevel < AccessLevel.superAdmin) {
      throw InvalidRequestException(
          'You do not have permission to get all administrators');
    }

    final admin = await _getAdminById(id: id, user: user);
    if (admin == null) throw MissingDataException('Administrator not found');

    return RepositoryResponse(data: admin.serializeWithFields(fields));
  }

  @override
  Future<RepositoryResponse> putById({
    required String id,
    required Map<String, dynamic> data,
    required DatabaseUser user,
    bool tryRequestingLock = true,
  }) async {
    if (user.accessLevel < AccessLevel.superAdmin) {
      throw InvalidRequestException(
          'You do not have permission to get put administrators');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock ||
          (await requestLock(user: user, id: id)).data?['locked'] != true) {
        throw InvalidRequestException(
            'You must acquire a lock before editing this administrator');
      }
      final response = await putById(
          id: id, data: data, user: user, tryRequestingLock: false);
      await releaseLock(user: user, id: id);
      return response;
    }

    // Update if exists, insert if not
    final previous = await _getAdminById(id: id, user: user);

    final newAdmin = previous?.copyWithData(data) ??
        Admin.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    await _putAdmin(admin: newAdmin, previous: previous);
    return RepositoryResponse(updatedData: {
      RequestFields.admin: {
        newAdmin.id:
            FetchableFields.fromFieldNames(newAdmin.getDifference(previous))
      }
    });
  }

  @override
  Future<RepositoryResponse> deleteById({
    required String id,
    required DatabaseUser user,
    bool tryRequestingLock = true,
  }) async {
    if (user.accessLevel < AccessLevel.superAdmin) {
      throw InvalidRequestException(
          'You do not have permission to get delete administrators');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock ||
          (await requestLock(user: user, id: id)).data?['locked'] != true) {
        throw InvalidRequestException(
            'You must acquire a lock before deleting this administrator');
      }
      final response =
          await deleteById(id: id, user: user, tryRequestingLock: false);
      await releaseLock(user: user, id: id);
      return response;
    }

    final admin = await _getAdminById(id: id, user: user);
    if (admin == null) {
      throw MissingDataException('Administrator not found');
    }
    if (admin.accessLevel >= AccessLevel.superAdmin) {
      throw InvalidRequestException('You cannot delete a super administrator');
    }

    final removedId = await _deleteAdmin(id: id);
    if (removedId == null) {
      throw DatabaseFailureException(
          'Failed to delete administrator with id $id');
    }
    return RepositoryResponse(deletedData: {
      RequestFields.admin: {removedId: FetchableFields.all}
    });
  }

  Future<Map<String, Admin>> _getAllAdmins({
    required DatabaseUser user,
  });

  Future<Admin?> _getAdminById({
    required String id,
    required DatabaseUser user,
  });

  Future<void> _putAdmin({required Admin admin, required Admin? previous});

  Future<String?> _deleteAdmin({required String id});
}

class MySqlAdminsRepository extends AdminsRepository {
  // coverage:ignore-start
  final MySqlInterface sqlInterface;

  MySqlAdminsRepository({required this.sqlInterface});

  @override
  Future<Map<String, Admin>> _getAllAdmins({
    String? adminId,
    required DatabaseUser user,
  }) async {
    final users = await sqlInterface.performSelectQuery(
      user: user,
      tableName: 'admins',
      filters: (adminId == null ? {} : {'id': adminId}),
    );

    final map = <String, Admin>{};
    for (final user in users) {
      final id = user['id'].toString();
      map[id] = Admin.fromSerialized(user);
    }
    return map;
  }

  @override
  Future<Admin?> _getAdminById({
    required String id,
    required DatabaseUser user,
  }) async =>
      (await _getAllAdmins(adminId: id, user: user))[id];

  Future<void> _insertToAdmins(Admin admin) async {
    await sqlInterface.performInsertQuery(
        tableName: 'entities', data: {'shared_id': admin.id});
    await sqlInterface.performInsertQuery(tableName: 'admins', data: {
      'id': admin.id.serialize(),
      'school_board_id': admin.schoolBoardId.serialize(),
      'has_registered_account': admin.hasRegisteredAccount,
      'first_name': admin.firstName.serialize(),
      'middle_name': admin.middleName?.serialize(),
      'last_name': admin.lastName.serialize(),
      'email': admin.email?.serialize(),
      'access_level': AccessLevel.admin.serialize(),
    });
  }

  Future<void> _updateToAdmins(Admin admin, Admin previous) async {
    final differences = admin.getDifference(previous);
    if (differences.contains('authentication_id')) {
      throw InvalidRequestException(
          'You cannot change the authentication ID of an administrator');
    }

    final toUpdate = <String, dynamic>{};
    if (differences.contains('school_board_id')) {
      toUpdate['school_board_id'] = admin.schoolBoardId;
    }
    if (differences.contains('has_registered_account')) {
      toUpdate['has_registered_account'] = admin.hasRegisteredAccount;
    }
    if (differences.contains('first_name')) {
      toUpdate['first_name'] = admin.firstName;
    }
    if (differences.contains('middle_name')) {
      toUpdate['middle_name'] = admin.middleName;
    }
    if (differences.contains('last_name')) {
      toUpdate['last_name'] = admin.lastName;
    }
    if (differences.contains('email')) {
      toUpdate['email'] = admin.email;
    }

    if (toUpdate.isNotEmpty) {
      await sqlInterface.performUpdateQuery(
          tableName: 'admins', filters: {'id': admin.id}, data: toUpdate);
    }
  }

  @override
  Future<void> _putAdmin(
      {required Admin admin, required Admin? previous}) async {
    if (previous == null) {
      await _insertToAdmins(admin);
    } else {
      await _updateToAdmins(admin, previous);
    }
  }

  @override
  Future<String?> _deleteAdmin({required String id}) async {
    // Delete the administrator from the database
    try {
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

class AdminsRepositoryMock extends AdminsRepository {
  // Simulate a database with a map
  final _dummyDatabase = {
    '0': Admin(
      id: '0',
      firstName: 'John',
      middleName: null,
      lastName: 'Doe',
      schoolBoardId: '100',
      hasRegisteredAccount: true,
      email: 'john.doe@email.com',
      accessLevel: AccessLevel.admin,
    ),
    '1': Admin(
      id: '1',
      firstName: 'Jane',
      middleName: null,
      lastName: 'Doe',
      schoolBoardId: '100',
      hasRegisteredAccount: true,
      email: 'jane.doe@email.com',
      accessLevel: AccessLevel.admin,
    ),
  };

  @override
  Future<Map<String, Admin>> _getAllAdmins({
    required DatabaseUser user,
  }) async =>
      _dummyDatabase;

  @override
  Future<Admin?> _getAdminById({
    required String id,
    required DatabaseUser user,
  }) async =>
      _dummyDatabase[id];

  @override
  Future<void> _putAdmin(
          {required Admin admin, required Admin? previous}) async =>
      _dummyDatabase[admin.id] = admin;

  @override
  Future<String?> _deleteAdmin({required String id}) async {
    if (_dummyDatabase.containsKey(id)) {
      _dummyDatabase.remove(id);
      return id;
    }
    return null;
  }
}
