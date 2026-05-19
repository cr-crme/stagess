import 'package:stagess_backend/repositories/repository_abstract.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
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
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to get administrators');
    }

    if (user.accessLevel < AccessLevel.schoolAdmin) {
      throw InvalidRequestException(
          'You do not have permission to get administrators');
    }

    final admins = await _getAllAdmins(user: user);

    // Filter administrators based on user access level (this should already be done, but just in case)
    if (user.accessLevel < AccessLevel.superAdmin) {
      admins.removeWhere(
          (key, value) => value.schoolBoardId != user.schoolBoardId);
    }
    if (user.accessLevel < AccessLevel.schoolBoardAdmin) {
      admins.removeWhere((key, value) => value.schoolId != user.schoolId);
    }

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
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to get administrators');
    }

    if (user.accessLevel < AccessLevel.schoolAdmin) {
      throw InvalidRequestException(
          'You do not have permission to get administrators');
    }

    final admin = await _getAdminById(id: id, user: user);
    if (admin == null) throw MissingDataException('Administrator not found');

    // Prevent from getting an administrator that the user does not have access to (this should already be done, but just in case)
    if (user.accessLevel < AccessLevel.superAdmin &&
        admin.schoolBoardId != user.schoolBoardId) {
      throw MissingDataException('Administrator not found');
    }
    if (user.accessLevel < AccessLevel.schoolBoardAdmin &&
        admin.schoolId != user.schoolId) {
      throw MissingDataException('Administrator not found');
    }

    return RepositoryResponse(data: admin.serializeWithFields(fields));
  }

  @override
  Future<RepositoryResponse> putById({
    required String id,
    required Map<String, dynamic> data,
    required DatabaseUser user,
    bool tryRequestingLock = true,
  }) async {
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to get administrators');
    }

    if (user.accessLevel < AccessLevel.schoolAdmin) {
      throw InvalidRequestException(
          'You do not have permission to put administrators');
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

    if (user.accessLevel < AccessLevel.superAdmin &&
        user.schoolBoardId != newAdmin.schoolBoardId) {
      // School board admins can only edit administrators of their school board
      throw InvalidRequestException(
          'You do not have permission to put administrators');
    }
    if (user.accessLevel < AccessLevel.schoolBoardAdmin &&
        user.userId != newAdmin.id) {
      // School admins can only edit themselves
      throw InvalidRequestException(
          'You do not have permission to put administrators');
    }

    await _putAdmin(admin: newAdmin, previous: previous);
    return RepositoryResponse(updatedData: {
      RequestFields.admin: {
        newAdmin.id:
            Admin.fetchableFields.extractFrom(newAdmin.getDifference(previous))
      }
    });
  }

  @override
  Future<RepositoryResponse> deleteById({
    required String id,
    required DatabaseUser user,
    bool tryRequestingLock = true,
  }) async {
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to get administrators');
    }

    if (user.accessLevel < AccessLevel.schoolAdmin) {
      throw InvalidRequestException(
          'You do not have permission to delete administrators');
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
    if (user.accessLevel < AccessLevel.superAdmin &&
        user.schoolBoardId != admin.schoolBoardId) {
      throw InvalidRequestException(
          'You do not have permission to delete that administrator');
    }
    if (user.accessLevel < AccessLevel.schoolBoardAdmin &&
        user.schoolId != admin.schoolId) {
      throw InvalidRequestException(
          'You do not have permission to delete that administrator');
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
    final admins = await sqlInterface.performSelectQuery(
      user: user,
      tableName: 'admins',
      filters: (adminId == null ? {} : {'id': adminId}),
      subqueries: [
        sqlInterface.selectSubquery(
          dataTableName: 'users',
          fieldsToFetch: ['email'],
        ),
        sqlInterface.selectSubquery(
          dataTableName: 'persons',
          fieldsToFetch: ['first_name', 'last_name'],
        ),
        sqlInterface.selectSubquery(
            dataTableName: 'phone_numbers',
            idNameToDataTable: 'entity_id',
            fieldsToFetch: ['id', 'phone_number']),
        sqlInterface.selectSubquery(
            dataTableName: 'addresses',
            idNameToDataTable: 'entity_id',
            fieldsToFetch: [
              'id',
              'civic',
              'street',
              'apartment',
              'city',
              'postal_code',
              'latitude',
              'longitude',
            ]),
      ],
    );

    final map = <String, Admin>{};
    for (final admin in admins) {
      final id = admin['id'].toString();

      admin.addAll(
          (admin['users'] as List?)?.firstOrNull as Map<String, dynamic>? ??
              {});
      admin.addAll(
          (admin['persons'] as List?)?.firstOrNull as Map<String, dynamic>? ??
              {});

      admin['phone'] =
          (admin['phone_numbers'] as List?)?.firstOrNull as Map? ?? {};
      admin['address'] =
          (admin['addresses'] as List?)?.firstOrNull as Map? ?? {};

      map[id] = Admin.fromSerialized(admin);
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
    final entity = (await sqlInterface.performSelectQuery(
            tableName: 'entities',
            filters: {'shared_id': admin.id},
            user: DatabaseUser.empty()
                .copyWith(accessLevel: AccessLevel.superAdmin)) as List)
        .firstOrNull;

    if (admin.accessLevel < AccessLevel.superAdmin &&
        admin.schoolBoardId.isEmpty) {
      throw InvalidRequestException(
          'Only super administrators can be created without a school board');
    }
    if (admin.accessLevel < AccessLevel.schoolBoardAdmin &&
        admin.schoolId.isEmpty) {
      throw InvalidRequestException(
          'Only school board administrators can be created without a school');
    }

    await sqlInterface.performInsertPerson(
        person: admin, skipAddingEntity: entity != null);
    await sqlInterface.performInsertUser(id: admin.id, email: admin.email);
    await sqlInterface.performInsertQuery(tableName: 'admins', data: {
      'id': admin.id.serialize(),
      'school_board_id': admin.schoolBoardId.serialize(),
      'school_id': admin.schoolId.serialize(),
      'has_registered_account': admin.hasRegisteredAccount,
      'access_level': admin.accessLevel.serialize(),
    });
  }

  Future<void> _updateToAdmins(Admin admin, Admin previous) async {
    final differences = admin.getDifference(previous);
    if (differences.contains('authentication_id')) {
      throw InvalidRequestException(
          'You cannot change the authentication ID of an administrator');
    }

    if (admin.accessLevel < AccessLevel.superAdmin &&
        admin.schoolBoardId.isEmpty) {
      throw InvalidRequestException(
          'Only super administrators can be created without a school board');
    }
    if (admin.accessLevel < AccessLevel.schoolBoardAdmin &&
        admin.schoolId.isEmpty) {
      throw InvalidRequestException(
          'Only school board administrators can be created without a school');
    }

    final toUpdate = <String, dynamic>{};
    if (differences.contains('school_board_id')) {
      toUpdate['school_board_id'] = admin.schoolBoardId.serialize();
    }
    if (differences.contains('school_id')) {
      toUpdate['school_id'] = admin.schoolId.serialize();
    }
    if (differences.contains('has_registered_account')) {
      toUpdate['has_registered_account'] = admin.hasRegisteredAccount;
    }
    if (differences.contains('access_level')) {
      toUpdate['access_level'] = admin.accessLevel.serialize();
    }

    if (toUpdate.isNotEmpty) {
      await sqlInterface.performUpdateQuery(
          tableName: 'admins', filters: {'id': admin.id}, data: toUpdate);
    }

    // Update the persons table if needed
    await sqlInterface.performUpdatePerson(person: admin, previous: previous);
  }

  @override
  Future<void> _putAdmin(
      {required Admin admin, required Admin? previous}) async {
    try {
      await sqlInterface.beginTransaction();

      if (previous == null) {
        await _insertToAdmins(admin);
      } else {
        await _updateToAdmins(admin, previous);
      }

      await sqlInterface.commitTransaction();
    } catch (e) {
      await sqlInterface.rollbackTransaction();
      rethrow;
    }
  }

  @override
  Future<String?> _deleteAdmin({required String id}) async {
    // Delete the administrator from the database
    try {
      await sqlInterface.beginTransaction();

      await sqlInterface.performDeleteQuery(
        tableName: 'entities',
        filters: {'shared_id': id},
      );

      await sqlInterface.commitTransaction();
      return id;
    } catch (e) {
      await sqlInterface.rollbackTransaction();
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
      lastName: 'Doe',
      schoolBoardId: '100',
      schoolId: '',
      hasRegisteredAccount: true,
      email: 'john.doe@email.com',
      phone: PhoneNumber.empty,
      address: Address.empty,
      accessLevel: AccessLevel.schoolBoardAdmin,
    ),
    '1': Admin(
      id: '1',
      firstName: 'Jane',
      lastName: 'Doe',
      schoolBoardId: '100',
      schoolId: '200',
      hasRegisteredAccount: true,
      email: 'jane.doe@email.com',
      phone: PhoneNumber.empty,
      address: Address.empty,
      accessLevel: AccessLevel.schoolAdmin,
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
