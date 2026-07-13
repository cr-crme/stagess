import 'package:stagess_backend/repositories/repository_abstract.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_backend/utils/security_policies.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common/utils.dart';

abstract class AdminsRepository extends RepositoryAbstract {
  @override
  Future<RepositoryResponse> getAll({
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    final admins = await _getAllAdmins(user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasMinimumAccessLevel(user: user, minimumLevel: AccessLevel.teacher),
      ...admins.values
          .map((e) => UserIsFromSameSchoolBoard(user: user, item: e)),
    ]).validate();

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
    final admin = await _getAdminById(id: id, user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasMinimumAccessLevel(user: user, minimumLevel: AccessLevel.teacher),
      HasData(item: admin),
      UserIsFromSameSchoolBoard(user: user, item: admin),
    ]).validate();

    return RepositoryResponse(data: admin!.serializeWithFields(fields));
  }

  @override
  Future<RepositoryResponse> putById({
    required String id,
    required Map<String, dynamic> data,
    required DatabaseUser user,
    bool tryRequestingLock = true,
  }) async {
    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock) {
        throw InvalidRequestException(
            'You must acquire a lock before editing this administrator');
      }
      return await requestLockAndPerformTask(
          id: id,
          user: user,
          task: () {
            return putById(
                id: id, data: data, user: user, tryRequestingLock: false);
          });
    }

    // Update if exists, insert if not
    final previous = await _getAdminById(id: id, user: user);
    final newAdmin = previous?.copyWithData(data) ??
        Admin.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: newAdmin),
      UserIsFromSameSchoolBoard(user: user, item: newAdmin),
      UserIsFromSameSchool(user: user, item: newAdmin),
      OrPolicy([
        ItemIsOwnedByUser(user: user, item: newAdmin),
        AndPolicy([
          HasMinimumAccessLevel(
              user: user, minimumLevel: newAdmin.accessLevel.nextHigher),
          if (previous != null)
            HasMinimumAccessLevel(
                user: user, minimumLevel: previous.accessLevel.nextHigher),
        ]),
      ]),
      ModificationsAreValid(
          user: user,
          item: newAdmin,
          previous: previous,
          allowedToCreate: [
            AccessLevel.schoolAdmin,
            AccessLevel.schoolBoardAdmin,
            AccessLevel.superAdmin,
          ],
          allowedToModify: [
            AccessLevel.self,
            AccessLevel.schoolAdmin,
            AccessLevel.schoolBoardAdmin,
            AccessLevel.superAdmin,
          ],
          whiteList: {
            AccessLevel.self: [
              'first_name',
              'last_name',
              'date_birth',
              'phone',
              'address',
            ],
          },
          blackList: {
            AccessLevel.schoolAdmin: ['id', 'school_board_id', 'school_id'],
            AccessLevel.schoolBoardAdmin: ['id', 'school_board_id'],
            AccessLevel.superAdmin: ['id', 'school_board_id'],
          },
          itemValidator: (user, item, previousItem) {
            if (item.accessLevel < AccessLevel.superAdmin &&
                item.schoolBoardId.isEmpty) {
              throw SecurityPolicyException(
                  'Only super administrators can be created without a school board');
            }
            if (item.accessLevel < AccessLevel.schoolBoardAdmin &&
                item.schoolId.isEmpty) {
              throw SecurityPolicyException(
                  'Only school board administrators can be created without a school');
            }
            if (item.accessLevel < AccessLevel.schoolAdmin) {
              throw SecurityPolicyException(
                  'Only school administrators and above can be created');
            }
            return Future.value();
          }),
    ]).validate();

    await _putAdmin(admin: newAdmin, previous: previous, user: user);
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
    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock) {
        throw InvalidRequestException(
            'You must acquire a lock before deleting this administrator');
      }
      return await requestLockAndPerformTask(
          id: id,
          user: user,
          task: () => deleteById(id: id, user: user, tryRequestingLock: false));
    }

    final admin = await _getAdminById(id: id, user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: admin),
      HasMinimumAccessLevel(
          user: user, minimumLevel: admin!.accessLevel.nextHigher),
      UserIsFromSameSchoolBoard(user: user, item: admin),
      UserIsFromSameSchool(user: user, item: admin),
      GenericPolicy(validationFunction: () {
        if (admin.accessLevel == AccessLevel.superAdmin) {
          throw SecurityPolicyException(
              'Super administrators cannot be deleted');
        }
        return Future.value();
      })
    ]).validate();

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

  Future<void> _putAdmin({
    required Admin admin,
    required Admin? previous,
    required DatabaseUser user,
  });

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
    final schoolFilters = ({
      'school_board_id': user.accessLevel < AccessLevel.superAdmin
          ? [user.schoolBoardId!]
          : null,
    }..removeWhere((key, value) => value == null))
        .cast<String, List<String>>();

    final admins = await sqlInterface.performSelectQuery(
      user: user,
      tableName: 'admins',
      filters: (adminId == null ? {} : {'id': adminId})..addAll(schoolFilters),
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

  Future<void> _insertToAdmins(Admin admin, DatabaseUser user) async {
    final entity = (await sqlInterface.performSelectQuery(
            tableName: 'entities',
            filters: {'shared_id': admin.id},
            user: DatabaseUser.empty()
                .copyWith(accessLevel: AccessLevel.superAdmin)) as List)
        .firstOrNull;

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

  Future<void> _updateToAdmins(
      Admin admin, Admin previous, DatabaseUser user) async {
    final differences = admin.getDifference(previous);

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
  Future<void> _putAdmin({
    required Admin admin,
    required Admin? previous,
    required DatabaseUser user,
  }) async {
    try {
      await sqlInterface.beginTransaction();

      if (previous == null) {
        await _insertToAdmins(admin, user);
      } else {
        await _updateToAdmins(admin, previous, user);
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
          {required Admin admin,
          required Admin? previous,
          required DatabaseUser user}) async =>
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
