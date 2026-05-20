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
import 'package:stagess_common/models/itineraries/itinerary.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/utils.dart';

abstract class TeachersRepository extends RepositoryAbstract {
  @override
  Future<RepositoryResponse> getAll({
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    final teachers = await _getAllTeachers(user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      ...teachers.values
          .map((e) => UserIsFromSameSchoolBoard(user: user, item: e)),
      ...teachers.values.map((e) => UserIsFromSameSchool(user: user, item: e)),
    ]).validate();

    return RepositoryResponse(
        data: teachers.map(
            (key, value) => MapEntry(key, value.serializeWithFields(fields))));
  }

  @override
  Future<RepositoryResponse> getById({
    required String id,
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    final teacher = await _getTeacherById(id: id, user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: teacher),
      UserIsFromSameSchoolBoard(user: user, item: teacher),
      UserIsFromSameSchool(user: user, item: teacher),
    ]).validate();

    return RepositoryResponse(data: teacher!.serializeWithFields(fields));
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
            'You must acquire a lock before editing this teacher');
      }
      return await requestLockAndPerformTask(
          id: id,
          user: user,
          task: () => putById(
              id: id, data: data, user: user, tryRequestingLock: false));
    }

    // Update if exists, insert if not
    final previous = await _getTeacherById(id: id, user: user);
    final newTeacher = previous?.copyWithData(data) ??
        Teacher.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    // TODO Test these policies
    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: newTeacher),
      UserIsFromSameSchoolBoard(user: user, item: newTeacher),
      UserIsFromSameSchool(user: user, item: newTeacher),
      ModificationsAreValid(
        user: user,
        item: newTeacher,
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
            'itineraries',
            'visiting_priorities',
          ],
        },
        blackList: {
          AccessLevel.schoolAdmin: ['id', 'school_board_id', 'school_id'],
          AccessLevel.schoolBoardAdmin: ['id', 'school_board_id'],
          AccessLevel.superAdmin: ['id', 'school_board_id'],
        },
        itemValidator: (user, item, previousItem) {
          // No specific validation
          return Future.value();
        },
      ),
    ]).validate();

    await _putTeacher(teacher: newTeacher, previous: previous, user: user);
    return RepositoryResponse(updatedData: {
      RequestFields.teacher: {
        newTeacher.id: Teacher.fetchableFields
            .extractFrom(newTeacher.getDifference(previous))
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
            'You must acquire a lock before deleting this teacher');
      }
      return await requestLockAndPerformTask(
          id: id,
          user: user,
          task: () => deleteById(id: id, user: user, tryRequestingLock: false));
    }

    final teacher = await _getTeacherById(id: id, user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: teacher),
      HasMinimumAccessLevel(user: user, minimumLevel: AccessLevel.schoolAdmin),
      UserIsFromSameSchoolBoard(user: user, item: teacher),
      UserIsFromSameSchool(user: user, item: teacher),
    ]).validate();

    final removedId = await _deleteTeacher(id: teacher!.id);
    if (removedId == null) {
      throw DatabaseFailureException(
          'Failed to delete teacher with id ${teacher.id}');
    }
    return RepositoryResponse(deletedData: {
      RequestFields.teacher: {removedId: FetchableFields.all}
    });
  }

  Future<Map<String, Teacher>> _getAllTeachers({
    required DatabaseUser user,
  });

  Future<Teacher?> _getTeacherById({
    required String id,
    required DatabaseUser user,
  });

  Future<void> _putTeacher(
      {required Teacher teacher,
      required Teacher? previous,
      required DatabaseUser user});

  Future<String?> _deleteTeacher({required String id});
}

class MySqlTeachersRepository extends TeachersRepository {
  // coverage:ignore-start
  final SqlInterface sqlInterface;
  MySqlTeachersRepository({required this.sqlInterface});

  @override
  Future<Map<String, Teacher>> _getAllTeachers({
    String? teacherId,
    required DatabaseUser user,
  }) async {
    final schoolFilters = ({
      'school_board_id': user.accessLevel < AccessLevel.superAdmin
          ? user.schoolBoardId!
          : null,
      'school_id': user.accessLevel < AccessLevel.schoolBoardAdmin
          ? user.schoolId!
          : null,
    }..removeWhere((key, value) => value == null))
        .cast<String, String>();

    final teachers = await sqlInterface.performSelectQuery(
        user: user,
        tableName: 'teachers',
        filters: (teacherId == null ? {} : {'id': teacherId})
          ..addAll(schoolFilters),
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
          sqlInterface.selectSubquery(
            dataTableName: 'teaching_groups',
            idNameToDataTable: 'teacher_id',
            fieldsToFetch: ['group_name'],
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'teacher_itineraries',
            asName: 'itineraries',
            idNameToDataTable: 'teacher_id',
            fieldsToFetch: ['id', 'name'],
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'teachers_visiting_priorities',
            idNameToDataTable: 'teacher_id',
            fieldsToFetch: ['internship_id', 'visiting_priority'],
          ),
        ]);

    final map = <String, Teacher>{};
    for (final teacher in teachers) {
      final id = teacher['id'].toString();
      teacher.addAll(
          (teacher['users'] as List?)?.firstOrNull as Map<String, dynamic>? ??
              {});
      teacher.addAll(
          (teacher['persons'] as List?)?.firstOrNull as Map<String, dynamic>? ??
              {});
      final teachingGroups = teacher['teaching_groups'] as List?;
      teacher['groups'] =
          teachingGroups?.map((map) => map['group_name'] as String).toList();

      teacher['phone'] =
          (teacher['phone_numbers'] as List?)?.firstOrNull as Map? ?? {};
      teacher['address'] =
          (teacher['addresses'] as List?)?.firstOrNull as Map? ?? {};

      if (teacher['itineraries'] != null) {
        final itineraries = teacher['itineraries'] as List;
        for (final itinerary in itineraries) {
          final waypoints = await sqlInterface.performSelectQuery(
            user: user,
            tableName: 'teacher_itinerary_waypoints',
            filters: {'itinerary_id': itinerary['id']},
          );
          itinerary['waypoints'] = [
            for (final waypoint in waypoints)
              {
                'id': waypoint['step_index']?.toString(),
                'title': waypoint['title'],
                'subtitle': waypoint['subtitle'],
                'address': {
                  'civic': waypoint['address_civic'],
                  'street': waypoint['address_street'],
                  'apartment': waypoint['address_apartment'],
                  'city': waypoint['address_city'],
                  'postal_code': waypoint['address_postal_code'],
                  'latitude': waypoint['address_latitude'],
                  'longitude': waypoint['address_longitude'],
                },
                'priority': waypoint['visiting_priority'],
              }
          ]..sort((a, b) => a['id'].compareTo(b['id']));
        }
      }

      final visitingPriorities = {};
      for (final priority in teacher['teachers_visiting_priorities'] as List) {
        final internshipId = priority['internship_id'] as String;
        visitingPriorities[internshipId] = priority['visiting_priority'];
      }
      teacher['visiting_priorities'] = visitingPriorities;

      map[id] = Teacher.fromSerialized(teacher);
    }
    return map;
  }

  @override
  Future<Teacher?> _getTeacherById({
    required String id,
    required DatabaseUser user,
  }) async =>
      (await _getAllTeachers(teacherId: id, user: user))[id];

  Future<void> _insertToTeachers(Teacher teacher) async {
    final entity = (await sqlInterface.performSelectQuery(
            tableName: 'entities',
            filters: {'shared_id': teacher.id},
            user: DatabaseUser.empty()
                .copyWith(accessLevel: AccessLevel.superAdmin)) as List)
        .firstOrNull;

    await sqlInterface.performInsertPerson(
        person: teacher, skipAddingEntity: entity != null);
    await sqlInterface.performInsertUser(id: teacher.id, email: teacher.email);
    await sqlInterface.performInsertQuery(tableName: 'teachers', data: {
      'id': teacher.id,
      'school_board_id': teacher.schoolBoardId,
      'school_id': teacher.schoolId,
      'has_registered_account': teacher.hasRegisteredAccount,
    });
  }

  Future<void> _updateToTeachers(
      Teacher teacher, Teacher previous, DatabaseUser user) async {
    final differences = teacher.getDifference(previous);

    final toUpdate = <String, dynamic>{};
    if (differences.contains('school_id')) {
      toUpdate['school_id'] = teacher.schoolId;
    }

    if (differences.contains('has_registered_account')) {
      toUpdate['has_registered_account'] = teacher.hasRegisteredAccount;
    }
    if (toUpdate.isNotEmpty) {
      await sqlInterface.performUpdateQuery(
          tableName: 'teachers', filters: {'id': teacher.id}, data: toUpdate);
    }

    // Update the persons table if needed
    await sqlInterface.performUpdatePerson(
        person: teacher, previous: previous, canChangeEmail: false);
  }

  Future<void> _insertToGroups(Teacher teacher) async {
    final toWait = <Future>[];
    for (final group in teacher.groups) {
      toWait.add(sqlInterface.performInsertQuery(
          tableName: 'teaching_groups',
          data: {'teacher_id': teacher.id, 'group_name': group}));
    }
    await Future.wait(toWait);
  }

  Future<void> _updateToGroups(
      Teacher teacher, Teacher previous, DatabaseUser user) async {
    final differences = teacher.getDifference(previous);
    if (!differences.contains('groups')) return;

    // This is a bit tricky to update the groups, so we delete the old ones
    // and reinsert the new ones
    await sqlInterface.performDeleteQuery(
      tableName: 'teaching_groups',
      filters: {'teacher_id': teacher.id},
    );
    await _insertToGroups(teacher);
  }

  Future<void> _insertToItineraries(Teacher teacher) async {
    for (final itinerary in teacher.itineraries) {
      await _sendItineraries(sqlInterface, teacher, itinerary);
    }
  }

  Future<void> _updateToItineraries(Teacher teacher, Teacher previous) async {
    final differences = teacher.getDifference(previous);
    if (!differences.contains('itineraries')) return;

    // Update itineraries
    final toWaitDeleted = <Future>[];
    final toWait = <Future>[];
    for (final itinerary in teacher.itineraries) {
      // Check if the itinerary already exists and/or has changed
      final previousItinerary =
          previous.itineraries.firstWhereOrNull((e) => e.id == itinerary.id);
      if (previousItinerary != null && itinerary == previousItinerary) continue;

      // This is a bit tricky to update the itineraries, so we delete the old
      // ones and reinsert the new ones
      if (previousItinerary != null) {
        toWaitDeleted.add(sqlInterface.performDeleteQuery(
          tableName: 'teacher_itineraries',
          filters: {'id': previousItinerary.id},
        ));
      }
      toWait.add(_sendItineraries(sqlInterface, teacher, itinerary));
    }

    await Future.wait(toWaitDeleted);
    await Future.wait(toWait);
  }

  Future<void> _insertToPriorities(Teacher teacher) async {
    final toWait = <Future>[];
    for (var internshipId in teacher.internshipsWithPriorities) {
      toWait.add(sqlInterface
          .performInsertQuery(tableName: 'teachers_visiting_priorities', data: {
        'teacher_id': teacher.id,
        'internship_id': internshipId,
        'visiting_priority': teacher.visitingPriority(internshipId).index,
      }));
    }
    await Future.wait(toWait);
  }

  Future<void> _updateToPriorities(
      DatabaseUser user, Teacher teacher, Teacher previous) async {
    final differences = teacher.getDifference(previous);
    if (!differences.contains('visiting_priorities')) return;

    final currentPriorities = await sqlInterface.performSelectQuery(
      user: user,
      tableName: 'teachers_visiting_priorities',
      filters: {'teacher_id': teacher.id},
      fieldsToFetch: ['internship_id'],
    );

    // Update priorities
    final toWait = <Future>[];
    for (var internshipId in teacher.internshipsWithPriorities) {
      if (!currentPriorities.any((e) => e['internship_id'] == internshipId)) {
        toWait.add(sqlInterface.performInsertQuery(
            tableName: 'teachers_visiting_priorities',
            data: {
              'teacher_id': teacher.id,
              'internship_id': internshipId,
              'visiting_priority': teacher.visitingPriority(internshipId).index,
            }));
      } else {
        toWait.add(sqlInterface.performUpdateQuery(
            tableName: 'teachers_visiting_priorities',
            filters: {
              'teacher_id': teacher.id,
              'internship_id': internshipId,
            },
            data: {
              'visiting_priority': teacher.visitingPriority(internshipId).index,
            }));
      }
    }
    await Future.wait(toWait);
  }

  @override
  Future<void> _putTeacher({
    required Teacher teacher,
    required Teacher? previous,
    required DatabaseUser user,
  }) async {
    try {
      await sqlInterface.beginTransaction();

      if (previous == null) {
        await _insertToTeachers(teacher);
      } else {
        await _updateToTeachers(teacher, previous, user);
      }

      final toWait = <Future>[];
      if (previous == null) {
        toWait.add(_insertToGroups(teacher));
        toWait.add(_insertToItineraries(teacher));
        toWait.add(_insertToPriorities(teacher));
      } else {
        toWait.add(_updateToGroups(teacher, previous, user));
        toWait.add(_updateToItineraries(teacher, previous));
        toWait.add(_updateToPriorities(user, teacher, previous));
      }

      await Future.wait(toWait);
      await sqlInterface.commitTransaction();
    } catch (e) {
      await sqlInterface.rollbackTransaction();
      rethrow;
    }
  }

  @override
  Future<String?> _deleteTeacher({required String id}) async {
    // Note, the deletion of the teacher will fail if they were involved in any
    // internships which therefore needs to be reassigned first

    // Delete the teacher from the database
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

Future<void> _sendItineraries(
    SqlInterface sqlInterface, Teacher teacher, Itinerary itinerary) async {
  final serialized = itinerary.serialize();
  await sqlInterface
      .performInsertQuery(tableName: 'teacher_itineraries', data: {
    'id': serialized['id'],
    'teacher_id': teacher.id,
    'name': serialized['name'],
  });

  for (int i = 0; i < serialized['waypoints'].length; i++) {
    final waypoint = serialized['waypoints'][i];
    await sqlInterface
        .performInsertQuery(tableName: 'teacher_itinerary_waypoints', data: {
      'step_index': i,
      'itinerary_id': serialized['id'],
      'title': waypoint['title'],
      'subtitle': waypoint['subtitle'],
      'address_civic': waypoint['address']['civic'],
      'address_street': waypoint['address']['street'],
      'address_apartment': waypoint['address']['apartment'],
      'address_city': waypoint['address']['city'],
      'address_postal_code': waypoint['address']['postal_code'],
      'address_latitude': waypoint['address']['latitude'],
      'address_longitude': waypoint['address']['longitude'],
      'visiting_priority': waypoint['priority'],
    });
  }

  // coverage:ignore-end
}

class TeachersRepositoryMock extends TeachersRepository {
  // Simulate a database with a map
  final _dummyDatabase = {
    '0': Teacher(
      id: '0',
      firstName: 'John',
      lastName: 'Doe',
      schoolBoardId: '100',
      schoolId: '10',
      hasRegisteredAccount: true,
      groups: ['100', '101'],
      phone: PhoneNumber.fromString('098-765-4321'),
      email: 'john.doe@email.com',
      dateBirth: null,
      address: Address.empty,
      itineraries: [],
      visitingPriorities: {},
    ),
    '1': Teacher(
      id: '1',
      firstName: 'Jane',
      lastName: 'Doe',
      schoolBoardId: '100',
      schoolId: '10',
      hasRegisteredAccount: true,
      groups: ['100', '101'],
      phone: PhoneNumber.fromString('123-456-7890'),
      email: 'john.doe@email.com',
      dateBirth: null,
      address: Address.empty,
      itineraries: [],
      visitingPriorities: {},
    ),
    '3': Teacher(
      id: '3',
      firstName: 'Jim',
      lastName: 'Dungeon',
      schoolBoardId: '200',
      schoolId: '20',
      hasRegisteredAccount: true,
      groups: ['200', '201'],
      phone: PhoneNumber.fromString('123-456-7890'),
      email: 'jim.dungeon@email.com',
      dateBirth: null,
      address: Address.empty,
      itineraries: [],
      visitingPriorities: {},
    )
  };

  @override
  Future<Map<String, Teacher>> _getAllTeachers({
    required DatabaseUser user,
  }) async =>
      _dummyDatabase;

  @override
  Future<Teacher?> _getTeacherById({
    required String id,
    required DatabaseUser user,
  }) async =>
      _dummyDatabase[id];

  @override
  Future<void> _putTeacher({
    required Teacher teacher,
    required Teacher? previous,
    required DatabaseUser user,
  }) async =>
      _dummyDatabase[teacher.id] = teacher;

  @override
  Future<String?> _deleteTeacher({required String id}) async {
    if (_dummyDatabase.containsKey(id)) {
      _dummyDatabase.remove(id);
      return id;
    }
    return null;
  }
}
