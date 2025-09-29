import 'package:logging/logging.dart';
import 'package:stagess_backend/repositories/repository_abstract.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/itineraries/itinerary.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/utils.dart';

final _logger = Logger('TeachersRepository');

// AccessLevel in this repository is discarded as all operations are currently
// available to all users

abstract class TeachersRepository implements RepositoryAbstract {
  @override
  Future<RepositoryResponse> getAll({
    List<String>? fields,
    required DatabaseUser user,
  }) async {
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to get teachers');
    }

    final teachers = await _getAllTeachers(user: user);

    // Filter teachers based on user access level (this should already be done, but just in case)
    teachers.removeWhere((key, value) =>
        user.accessLevel <= AccessLevel.admin &&
        value.schoolBoardId != user.schoolBoardId);

    return RepositoryResponse(
        data: teachers.map(
            (key, value) => MapEntry(key, value.serializeWithFields(fields))));
  }

  @override
  Future<RepositoryResponse> getById({
    required String id,
    List<String>? fields,
    required DatabaseUser user,
  }) async {
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to get teachers');
    }

    final teacher = await _getTeacherById(id: id, user: user);
    if (teacher == null) throw MissingDataException('Teacher not found');

    // Prevent from getting a teacher that the user does not have access to (this should already be done, but just in case)
    if (user.accessLevel <= AccessLevel.admin &&
        teacher.schoolBoardId != user.schoolBoardId) {
      throw MissingDataException('Teacher not found');
    }

    return RepositoryResponse(data: teacher.serializeWithFields(fields));
  }

  @override
  Future<RepositoryResponse> putById({
    required String id,
    required Map<String, dynamic> data,
    required DatabaseUser user,
  }) async {
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to put teachers');
    }

    // Update if exists, insert if not
    final previous = await _getTeacherById(id: id, user: user);
    final newTeacher = previous?.copyWithData(data) ??
        Teacher.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    // If the user is not at least an admin, they cannot insert new teachers
    if (user.accessLevel == AccessLevel.admin &&
        newTeacher.schoolBoardId != user.schoolBoardId) {
      throw InvalidRequestException(
          'You do not have permission to put this teacher');
    } else if (user.accessLevel < AccessLevel.admin) {
      if (previous == null) {
        throw InvalidRequestException(
            'You do not have permission to insert teachers');
      } else if (previous.id != user.userId) {
        throw InvalidRequestException(
            'You do not have permission to update teachers');
      }
    }

    await _putTeacher(teacher: newTeacher, previous: previous, user: user);
    return RepositoryResponse(updatedData: {
      RequestFields.teacher: {newTeacher.id: newTeacher.getDifference(previous)}
    });
  }

  @override
  Future<RepositoryResponse> deleteById({
    required String id,
    required DatabaseUser user,
  }) async {
    if (user.isNotVerified || user.accessLevel < AccessLevel.admin) {
      throw InvalidRequestException(
          'You do not have permission to delete teachers');
    }

    if (user.accessLevel <= AccessLevel.admin &&
        (await _getTeacherById(id: id, user: user))?.schoolBoardId !=
            user.schoolBoardId) {
      throw InvalidRequestException(
          'You do not have permission to delete this teacher');
    }

    final removedId = await _deleteTeacher(id: id);
    if (removedId == null) {
      throw DatabaseFailureException('Failed to delete teacher with id $id');
    }
    return RepositoryResponse(deletedData: {
      RequestFields.teacher: [removedId]
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
    final teachers = await sqlInterface.performSelectQuery(
        user: user,
        tableName: 'teachers',
        filters: (teacherId == null ? {} : {'id': teacherId})
          ..addAll(user.accessLevel == AccessLevel.superAdmin
              ? {}
              : {'school_board_id': user.schoolBoardId ?? ''}),
        subqueries: [
          sqlInterface.selectSubquery(
            dataTableName: 'persons',
            fieldsToFetch: ['first_name', 'middle_name', 'last_name', 'email'],
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
                'postal_code'
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
            fieldsToFetch: ['id', 'date'],
          ),
        ]);

    final map = <String, Teacher>{};
    for (final teacher in teachers) {
      final id = teacher['id'].toString();
      teacher
          .addAll((teacher['persons'] as List).first as Map<String, dynamic>);
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
                'latitude': waypoint['latitude'],
                'longitude': waypoint['longitude'],
                'address': {
                  'civic': waypoint['address_civic'],
                  'street': waypoint['address_street'],
                  'apartment': waypoint['address_apartment'],
                  'city': waypoint['address_city'],
                  'postal_code': waypoint['address_postal_code']
                },
                'priority': waypoint['visiting_priority'],
              }
          ]..sort((a, b) => a['id'].compareTo(b['id']));
        }
      }

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
    if (differences.contains('school_board_id')) {
      throw InvalidRequestException(
          'Cannot update school_board_id for the teachers');
    }
    if (differences.contains('school_id')) {
      if (user.accessLevel < AccessLevel.admin) {
        _logger.severe(
            'User ${user.userId} tried to change the school (${teacher.schoolId}) '
            'of teacher (${teacher.id}) but does not have permission, skipping');
      } else {
        toUpdate['school_id'] = teacher.schoolId;
      }
    }

    if (differences.contains('has_registered_account')) {
      toUpdate['has_registered_account'] = teacher.hasRegisteredAccount;
    }
    if (toUpdate.isNotEmpty) {
      // These modifications are only allowed to admins
      if (user.accessLevel < AccessLevel.admin) {
        throw InvalidRequestException(
            'You do not have permission to insert teachers');
      }

      await sqlInterface.performUpdateQuery(
          tableName: 'teachers', filters: {'id': teacher.id}, data: toUpdate);
    }

    // Update the persons table if needed
    await sqlInterface.performUpdatePerson(person: teacher, previous: previous);
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

    // These modifications are only allowed to admins
    if (user.accessLevel < AccessLevel.admin) {
      throw InvalidRequestException(
          'You do not have permission to insert teachers');
    }

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

  @override
  Future<void> _putTeacher({
    required Teacher teacher,
    required Teacher? previous,
    required DatabaseUser user,
  }) async {
    if (previous == null) {
      await _insertToTeachers(teacher);
    } else {
      await _updateToTeachers(teacher, previous, user);
    }

    final toWait = <Future>[];
    if (previous == null) {
      toWait.add(_insertToGroups(teacher));
      toWait.add(_insertToItineraries(teacher));
    } else {
      toWait.add(_updateToGroups(teacher, previous, user));
      toWait.add(_updateToItineraries(teacher, previous));
    }
    await Future.wait(toWait);
  }

  @override
  Future<String?> _deleteTeacher({required String id}) async {
    // Note, the deletion of the teacher will fail if they were involved in any
    // internships which therefore needs to be reassigned first

    // Delete the teacher from the database
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

Future<void> _sendItineraries(
    SqlInterface sqlInterface, Teacher teacher, Itinerary itinerary) async {
  final serialized = itinerary.serialize();
  await sqlInterface
      .performInsertQuery(tableName: 'teacher_itineraries', data: {
    'id': serialized['id'],
    'teacher_id': teacher.id,
    'date': serialized['date'],
  });

  for (int i = 0; i < serialized['waypoints'].length; i++) {
    final waypoint = serialized['waypoints'][i];
    await sqlInterface
        .performInsertQuery(tableName: 'teacher_itinerary_waypoints', data: {
      'step_index': i,
      'itinerary_id': serialized['id'],
      'title': waypoint['title'],
      'subtitle': waypoint['subtitle'],
      'latitude': waypoint['latitude'],
      'longitude': waypoint['longitude'],
      'address_civic': waypoint['address']['civic'],
      'address_street': waypoint['address']['street'],
      'address_apartment': waypoint['address']['apartment'],
      'address_city': waypoint['address']['city'],
      'address_postal_code': waypoint['address']['postal_code'],
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
        middleName: null,
        lastName: 'Doe',
        schoolBoardId: '10',
        schoolId: '10',
        hasRegisteredAccount: true,
        groups: ['100', '101'],
        phone: PhoneNumber.fromString('098-765-4321'),
        email: 'john.doe@email.com',
        dateBirth: null,
        address: Address.empty,
        itineraries: []),
    '1': Teacher(
        id: '1',
        firstName: 'Jane',
        middleName: null,
        lastName: 'Doe',
        schoolBoardId: '10',
        schoolId: '10',
        hasRegisteredAccount: true,
        groups: ['100', '101'],
        phone: PhoneNumber.fromString('123-456-7890'),
        email: 'john.doe@email.com',
        dateBirth: null,
        address: Address.empty,
        itineraries: []),
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
