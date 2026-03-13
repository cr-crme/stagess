import 'package:logging/logging.dart';
import 'package:stagess_backend/repositories/repository_abstract.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/utils.dart';

final _logger = Logger('StudentsRepository');

// AccessLevel in this repository is discarded as all operations are currently
// available to all users

abstract class StudentsRepository extends RepositoryAbstract {
  @override
  Future<RepositoryResponse> getAll({
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to get students');
    }

    final students = await _getAllStudents(user: user);

    // Filter students based on user access level (this should already be done, but just in case)
    students.removeWhere((key, value) =>
        user.accessLevel <= AccessLevel.admin &&
        value.schoolBoardId != user.schoolBoardId);

    return RepositoryResponse(
        data: students.map(
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
          'You do not have permission to get students');
    }

    final student = await _getStudentById(id: id, user: user);
    if (student == null) throw MissingDataException('Student not found');

    // Prevent from getting a student that the user does not have access to (this should already be done, but just in case)
    if (user.accessLevel <= AccessLevel.admin &&
        student.schoolBoardId != user.schoolBoardId) {
      throw MissingDataException('Student not found');
    }

    return RepositoryResponse(data: student.serializeWithFields(fields));
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
          'You do not have permission to put students');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock ||
          (await requestLock(user: user, id: id)).data?['locked'] != true) {
        throw InvalidRequestException(
            'You must acquire a lock before editing this student');
      }
      final response = await putById(
          id: id, data: data, user: user, tryRequestingLock: false);
      await releaseLock(user: user, id: id);
      return response;
    }

    // Update if exists, insert if not
    final previous = await _getStudentById(id: id, user: user);
    final newStudent = previous?.copyWithData(data) ??
        Student.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    // Teachers are only allowed to change the internships
    final differences = newStudent.getDifference(previous);
    if (user.accessLevel != AccessLevel.superAdmin &&
        (newStudent.schoolBoardId != user.schoolBoardId ||
            (user.accessLevel == AccessLevel.teacher &&
                (differences.length > 1 ||
                    !differences.contains('all_visa'))))) {
      throw InvalidRequestException(
          'You do not have permission to put this student');
    }

    await _putStudent(student: newStudent, previous: previous, user: user);
    return RepositoryResponse(updatedData: {
      RequestFields.student: {
        newStudent.id: Student.fetchableFields
            .extractFrom(newStudent.getDifference(previous))
      }
    });
  }

  @override
  Future<RepositoryResponse> deleteById({
    required String id,
    required DatabaseUser user,
    bool tryRequestingLock = true,
  }) async {
    if (user.isNotVerified || user.accessLevel < AccessLevel.admin) {
      throw InvalidRequestException(
          'You do not have permission to delete students');
    }

    if (user.accessLevel <= AccessLevel.admin &&
        (await _getStudentById(id: id, user: user))?.schoolBoardId !=
            user.schoolBoardId) {
      throw InvalidRequestException(
          'You do not have permission to delete this student');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock ||
          (await requestLock(user: user, id: id)).data?['locked'] != true) {
        throw InvalidRequestException(
            'You must acquire a lock before deleting this student');
      }
      final response =
          await deleteById(id: id, user: user, tryRequestingLock: false);
      await releaseLock(user: user, id: id);
      return response;
    }

    final removedId = await _deleteStudent(id: id, user: user);
    if (removedId == null) {
      throw DatabaseFailureException('Failed to delete student with id $id');
    }
    return RepositoryResponse(deletedData: {
      RequestFields.student: {removedId: FetchableFields.all}
    });
  }

  Future<Map<String, Student>> _getAllStudents({
    required DatabaseUser user,
  });

  Future<Student?> _getStudentById({
    required String id,
    required DatabaseUser user,
  });

  Future<void> _putStudent(
      {required Student student,
      required Student? previous,
      required DatabaseUser user});

  Future<String?> _deleteStudent({
    required String id,
    required DatabaseUser user,
  });
}

class MySqlStudentsRepository extends StudentsRepository {
  // coverage:ignore-start
  final SqlInterface sqlInterface;
  MySqlStudentsRepository({required this.sqlInterface});

  @override
  Future<Map<String, Student>> _getAllStudents({
    String? studentId,
    required DatabaseUser user,
  }) async {
    final students = await sqlInterface.performSelectQuery(
      user: user,
      tableName: 'students',
      filters: (studentId == null ? {} : {'id': studentId})
        ..addAll(user.accessLevel == AccessLevel.superAdmin
            ? {}
            : {'school_board_id': user.schoolBoardId ?? ''}),
      subqueries: [
        sqlInterface.selectSubquery(
          dataTableName: 'persons',
          fieldsToFetch: [
            'first_name',
            'middle_name',
            'last_name',
            'date_birthday',
            'email'
          ],
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
        sqlInterface.joinSubquery(
            dataTableName: 'persons',
            asName: 'contact',
            idNameToDataTable: 'contact_id',
            idNameToMainTable: 'student_id',
            relationTableName: 'student_contacts',
            fieldsToFetch: ['id']),
        sqlInterface.selectSubquery(
          dataTableName: 'student_visa',
          asName: 'all_visa',
          fieldsToFetch: ['id', 'form_version'],
          idNameToDataTable: 'student_id',
        ),
      ],
    );

    final map = <String, Student>{};
    for (final student in students) {
      final id = student['id'].toString();
      student['group'] = student['group_name'];

      final contactId =
          (student['contact'] as List?)?.map((e) => e['id']).firstOrNull;
      final contacts = contactId == null
          ? null
          : await sqlInterface
              .performSelectQuery(user: user, tableName: 'persons', filters: {
              'id': contactId
            }, subqueries: [
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
                  dataTableName: 'phone_numbers',
                  idNameToDataTable: 'entity_id',
                  fieldsToFetch: ['id', 'phone_number']),
            ]);
      student['contact'] = contacts?.firstOrNull ?? {};
      if (student['contact']['phone_numbers'] != null) {
        student['contact']['phone'] =
            (student['contact']['phone_numbers'] as List).first as Map;
      }
      if (student['contact']['addresses'] != null) {
        student['contact']['address'] =
            (student['contact']['addresses'] as List).firstOrNull as Map?;
      }

      student
          .addAll((student['persons'] as List).first as Map<String, dynamic>);
      student['date_birth'] = student['date_birthday'] == null
          ? null
          : DateTime.parse(student['date_birthday']).millisecondsSinceEpoch;

      student['phone'] =
          (student['phone_numbers'] as List?)?.firstOrNull as Map? ?? {};
      student['address'] =
          (student['addresses'] as List?)?.firstOrNull as Map? ?? {};

      final allVisa = [];
      for (final Map<String, dynamic> visa
          in (student['all_visa'] as List? ?? [])) {
        final evaluationSubquery = (await sqlInterface.performSelectQuery(
                user: user,
                tableName: 'student_visa',
                filters: {
              'id': visa['id']
            },
                subqueries: [
              sqlInterface.selectSubquery(
                dataTableName: 'student_visa_items',
                asName: 'visa',
                fieldsToFetch: [
                  'id',
                  'visa_id',
                ],
                idNameToDataTable: 'visa_id',
              ),
            ]))
            .first;

        final form = (evaluationSubquery['visa'] as List).firstOrNull ?? {};

// TODO RENDU ICI
        final formSubquery = (await sqlInterface.performSelectQuery(
            user: user,
            tableName: 'student_visa',
            fieldsToFetch: [
              'id',
              'visa_id',
              'is_gateway_to_fms_available',
              'reference',
              'success_conditions',
            ],
            filters: {
              'visa_id': form['visa_id']
            },
            subqueries: [
              sqlInterface.selectSubquery(
                dataTableName: 'student_visa_experiences_and_aptitude_items',
                asName: 'visa',
                fieldsToFetch: [
                  'id',
                  'visa_id',
                  'is_gateway_to_fms_available',
                  'reference',
                  'success_conditions',
                ],
                idNameToDataTable: 'visa_items_id',
              ),
            ]));

        allVisa.add(visa);
      }
      student['all_visa'] = allVisa;

      map[id] = Student.fromSerialized(student);
    }
    return map;
  }

  @override
  Future<Student?> _getStudentById({
    required String id,
    required DatabaseUser user,
  }) async =>
      (await _getAllStudents(studentId: id, user: user))[id];

  Future<void> _insertToStudents(Student student) async {
    await sqlInterface.performInsertPerson(person: student);
    await sqlInterface.performInsertQuery(tableName: 'students', data: {
      'id': student.id.serialize(),
      'school_board_id': student.schoolBoardId.serialize(),
      'school_id': student.schoolId.serialize(),
      'version': Student.currentVersion.serialize(),
      'photo': student.photo.serialize(),
      'program': student.programSerialized,
      'group_name': student.group.serialize(),
      'contact_link': student.contactLink.serialize(),
    });
  }

  Future<void> _updateToStudents(
      Student student, Student previous, DatabaseUser user) async {
    final differences = student.getDifference(previous);
    if (user.accessLevel < AccessLevel.admin) return;

    if (differences.contains('school_board_id')) {
      throw InvalidRequestException(
          'Cannot update school_board_id for the students');
    }
    if (differences.contains('school_id')) {
      if (user.accessLevel < AccessLevel.admin) {
        _logger.warning(
            'User ${user.userId} tried to change the school (${student.schoolId}) of '
            'student (${student.id}) but does not have permission, skipping');
      } else {
        await sqlInterface.performUpdateQuery(
            tableName: 'students',
            filters: {'id': student.id},
            data: {'school_id': student.schoolId});
      }
    }

    // Update the persons table if needed
    await sqlInterface.performUpdatePerson(person: student, previous: previous);

    final toUpdate = <String, dynamic>{};
    if (student.photo != previous.photo) {
      toUpdate['photo'] = student.photo.serialize();
    }
    if (student.program != previous.program) {
      toUpdate['program'] = student.programSerialized;
    }
    if (student.group != previous.group) {
      toUpdate['group_name'] = student.group.serialize();
    }
    if (student.contactLink != previous.contactLink) {
      toUpdate['contact_link'] = student.contactLink.serialize();
    }
    if (toUpdate.isNotEmpty) {
      await sqlInterface.performUpdateQuery(
          tableName: 'students', filters: {'id': student.id}, data: toUpdate);
    }
  }

  Future<void> _insertToContacts(Student student) async {
    await sqlInterface.performInsertPerson(person: student.contact);
    await sqlInterface.performInsertQuery(
        tableName: 'student_contacts',
        data: {'student_id': student.id, 'contact_id': student.contact.id});
  }

  Future<void> _updateToContacts({
    required Student student,
    required Student previous,
    required DatabaseUser user,
  }) async {
    if (user.accessLevel < AccessLevel.admin) return;

    final differences = student.getDifference(previous);
    if (differences.contains('contact')) {
      await sqlInterface.performUpdatePerson(
          person: student.contact, previous: previous.contact);
    }
  }

  Future<void> _insertToVisa(Student student, [Student? previous]) async {
    for (final evaluation in student.allVisa.serialize()) {
      if (previous?.allVisa.any((e) => e.id == evaluation['id']) ?? false) {
        // Skip if the evaluation already exists
        continue;
      }

      await sqlInterface.performInsertQuery(tableName: 'student_visa', data: {
        'id': evaluation['id'],
        'student_id': student.id,
        'form_version': evaluation['form_version'],
      });

      // Insert the form
      await sqlInterface
          .performInsertQuery(tableName: 'student_visa_items', data: {
        'id': evaluation['form']['id'],
        'visa_id': evaluation['id'],
        'is_gateway_to_fms_available': evaluation['form']
            ['is_gateway_to_fms_available'],
        'reference': evaluation['form']['reference'],
        'success_conditions': evaluation['form']['success_conditions'],
      });

      final toWait = <Future>[];
      for (final element
          in (evaluation['form']['experiences_and_aptitudes'] as List?) ?? []) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_experiences_and_aptitude_items',
            data: {
              'id': element['id'],
              'visa_items_id': evaluation['form']['id'],
              'text': element['text'],
              'is_selected': element['is_selected'],
            },
          ),
        );
      }
      for (final element
          in (evaluation['form']['attestation_and_mentions'] as List?) ?? []) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_attestations_and_mentions_items',
            data: {
              'id': element['id'],
              'visa_items_id': evaluation['form']['id'],
              'text': element['text'],
              'is_selected': element['is_selected'],
            },
          ),
        );
      }
      for (final element
          in (evaluation['form']['sst_trainings'] as List?) ?? []) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_sst_training_items',
            data: {
              'id': element['id'],
              'visa_items_id': evaluation['form']['id'],
              'text': element['text'],
              'is_selected': element['is_selected'],
            },
          ),
        );
      }
      for (final element
          in (evaluation['form']['certificates'] as List?) ?? []) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_certificate_items',
            data: {
              'id': element['id'],
              'visa_items_id': evaluation['form']['id'],
              'text': element['text'],
              'year': element['year'],
              'specialization_id': element['specialization_id'],
              'is_selected': element['is_selected'],
            },
          ),
        );
      }
      for (final element in (evaluation['form']['skills'] as List?) ?? []) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_skill_items',
            data: {
              'id': element['id'],
              'visa_items_id': evaluation['form']['id'],
              'text': element['text'],
              'is_selected': element['is_selected'],
            },
          ),
        );
      }
      for (final element in (evaluation['form']['forces'] as List?) ?? []) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_forces_items',
            data: {
              'id': element['id'],
              'visa_items_id': evaluation['form']['id'],
              'text': element['text'],
              'is_selected': element['is_selected'],
            },
          ),
        );
      }
      for (final element in (evaluation['form']['challenges'] as List?) ?? []) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_challenges_items',
            data: {
              'id': element['id'],
              'visa_items_id': evaluation['form']['id'],
              'text': element['text'],
              'is_selected': element['is_selected'],
            },
          ),
        );
      }

      await Future.wait(toWait);
    }
  }

  Future<void> _updateToVisa(Student student, Student previous) async {
    // Attitude evaluations are not updated, but stacked
    await _insertToVisa(student, previous);
  }

  @override
  Future<void> _putStudent({
    required Student student,
    required Student? previous,
    required DatabaseUser user,
  }) async {
    if (previous == null) {
      await _insertToStudents(student);
      await _insertToContacts(student);
      await _insertToVisa(student);
    } else {
      await _updateToStudents(student, previous, user);
      await _updateToContacts(student: student, previous: previous, user: user);
      await _updateToVisa(student, previous);
    }
  }

  @override
  Future<String?> _deleteStudent({
    required String id,
    required DatabaseUser user,
  }) async {
    // Note: This will fail if the student was involved in an internship. The
    // data from the internship needs to be deleted first.
    try {
      final contacts = (await sqlInterface.performSelectQuery(
        user: user,
        tableName: 'student_contacts',
        filters: {'student_id': id},
      ));

      await sqlInterface.performDeleteQuery(
        tableName: 'student_contacts',
        filters: {'student_id': id},
      );

      for (final contact in contacts) {
        await sqlInterface.performDeleteQuery(
          tableName: 'entities',
          filters: {'shared_id': contact['contact_id']},
        );
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
  // coverage:ignore-end
}

class StudentsRepositoryMock extends StudentsRepository {
  // Simulate a database with a map
  final _dummyDatabase = {
    '0': Student(
      id: '0',
      schoolBoardId: '0',
      schoolId: '0',
      firstName: 'John',
      middleName: null,
      lastName: 'Doe',
      phone: PhoneNumber.fromString('098-765-4321'),
      email: 'john.doe@email.com',
      dateBirth: null,
      address: Address.empty,
      program: Program.fms,
      group: 'A',
      contact: Person(
          id: '1',
          firstName: 'Jane',
          middleName: null,
          lastName: 'Doe',
          dateBirth: null,
          address: Address.empty,
          phone: PhoneNumber.fromString('123-456-7890'),
          email: 'jane.doe@quebec.qc'),
      contactLink: 'Mother',
      allVisa: [],
    ),
    '1': Student(
      id: '1',
      schoolBoardId: '0',
      schoolId: '0',
      firstName: 'Jane',
      middleName: null,
      lastName: 'Doe',
      phone: PhoneNumber.fromString('123-456-7890'),
      email: 'jane.doe@email.com',
      dateBirth: null,
      address: Address.empty,
      program: Program.fms,
      group: 'A',
      contact: Person(
          id: '0',
          firstName: 'John',
          middleName: null,
          lastName: 'Doe',
          dateBirth: null,
          address: Address.empty,
          phone: PhoneNumber.fromString('098-765-4321'),
          email: 'john.doe@quebec.qc'),
      contactLink: 'Father',
      allVisa: [],
    ),
  };

  @override
  Future<Map<String, Student>> _getAllStudents({
    required DatabaseUser user,
  }) async =>
      _dummyDatabase;

  @override
  Future<Student?> _getStudentById({
    required String id,
    required DatabaseUser user,
  }) async =>
      _dummyDatabase[id];

  @override
  Future<void> _putStudent({
    required Student student,
    required Student? previous,
    required DatabaseUser user,
  }) async =>
      _dummyDatabase[student.id] = student;

  @override
  Future<String?> _deleteStudent({
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
