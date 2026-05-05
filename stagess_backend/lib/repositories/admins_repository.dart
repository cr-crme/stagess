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
    final admins = await sqlInterface.performSelectQuery(
      user: user,
      tableName: 'admins',
      filters: (adminId == null ? {} : {'id': adminId}),
      subqueries: [
        sqlInterface.selectSubquery(
          dataTableName: 'persons',
          fieldsToFetch: ['first_name', 'last_name', 'email'],
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

      admin.addAll((admin['persons'] as List).first as Map<String, dynamic>);

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

    await sqlInterface.performInsertPerson(
        person: admin, skipAddingEntity: entity != null);
    await sqlInterface.performInsertQuery(tableName: 'admins', data: {
      'id': admin.id.serialize(),
      'school_board_id': admin.schoolBoardId.serialize(),
      'has_registered_account': admin.hasRegisteredAccount,
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
      lastName: 'Doe',
      schoolBoardId: '100',
      hasRegisteredAccount: true,
      email: 'john.doe@email.com',
      phone: PhoneNumber.empty,
      address: Address.empty,
      accessLevel: AccessLevel.admin,
    ),
    '1': Admin(
      id: '1',
      firstName: 'Jane',
      lastName: 'Doe',
      schoolBoardId: '100',
      hasRegisteredAccount: true,
      email: 'jane.doe@email.com',
      phone: PhoneNumber.empty,
      address: Address.empty,
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
