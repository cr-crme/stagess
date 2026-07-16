import 'package:stagess_backend/repositories/internships_repository.dart';
import 'package:stagess_backend/repositories/repository_abstract.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/repositories/teachers_repository.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_backend/utils/security_policies.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/utils.dart';

abstract class StudentsRepository extends RepositoryAbstract {
  @override
  Future<RepositoryResponse> getAll({
    required FetchableFields fields,
    required DatabaseUser user,
    TeachersRepository? teachersRepository,
  }) async {
    final teacher =
        await _fetchTeacher(user: user, teachersRepository: teachersRepository);
    final students = await _getAllStudents(user: user, teacher: teacher);
    // TODO: Add a "enseignant responsable" to the student model and allow them to update their students
    // TODO: Add "enseignants supplémentaires" to the student model and allow them to show them in their list

    await SecurityPolicies([
      UserIsVerified(user: user),
      ...students.values
          .map((e) => UserIsFromSameSchoolBoard(user: user, item: e)),
    ]).validate();

    final filteredStudents = students.map((key, value) => MapEntry(
        key,
        _filterDataByAccessibility(
            user: user, teacher: teacher, student: value)));
    return RepositoryResponse(
        data: filteredStudents.map(
            (key, value) => MapEntry(key, value.serializeWithFields(fields))));
  }

  @override
  Future<RepositoryResponse> getById({
    required String id,
    required FetchableFields fields,
    required DatabaseUser user,
    TeachersRepository? teachersRepository,
  }) async {
    final teacher =
        await _fetchTeacher(user: user, teachersRepository: teachersRepository);
    final student = await _getStudentById(id: id, user: user, teacher: teacher);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: student),
      UserIsFromSameSchoolBoard(user: user, item: student),
      UserIsFromSameSchool(user: user, item: student),
    ]).validate();

    final filteredStudent = _filterDataByAccessibility(
        user: user, teacher: teacher, student: student!);
    return RepositoryResponse(
        data: filteredStudent.serializeWithFields(fields));
  }

  @override
  Future<RepositoryResponse> putById({
    required String id,
    required Map<String, dynamic> data,
    required DatabaseUser user,
    TeachersRepository? teachersRepository,
    bool tryRequestingLock = true,
  }) async {
    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock) {
        throw InvalidRequestException(
            'You must acquire a lock before editing this student');
      }
      return await requestLockAndPerformTask(
          id: id,
          user: user,
          task: () => putById(
              id: id,
              data: data,
              user: user,
              teachersRepository: teachersRepository,
              tryRequestingLock: false));
    }

    // Update if exists, insert if not
    final previous = await _getStudentById(id: id, user: user, teacher: null);
    final newStudent = previous?.copyWithData(data) ??
        Student.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    Teacher? teacher;
    try {
      final teacherData = await teachersRepository!
          .getById(id: user.userId!, fields: FetchableFields.all, user: user);
      teacher = Teacher.fromSerialized(teacherData.data);
    } catch (e) {
      // User is not a teacher (e.g., an admin)
    }

    final teacherIsInCharge = teacher != null &&
        (previous?.teacherInChargeId == teacher.id ||
            (previous?.supplementaryTeacherInChargeIds.contains(teacher.id) ??
                false));

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: newStudent),
      UserIsFromSameSchoolBoard(user: user, item: newStudent),
      UserIsFromSameSchool(user: user, item: newStudent),
      UserIsFromSameGroupAsStudent(
          user: user, previousItem: previous, teacher: teacher),
      ModificationsAreValid(
        user: user,
        item: newStudent,
        previous: previous,
        allowedToCreate: [
          AccessLevel.schoolAdmin,
          AccessLevel.schoolBoardAdmin,
          AccessLevel.superAdmin,
        ],
        allowedToModify: [
          if (teacherIsInCharge) AccessLevel.teacher,
          AccessLevel.teacherAdmin,
          AccessLevel.schoolAdmin,
          AccessLevel.schoolBoardAdmin,
          AccessLevel.superAdmin,
        ],
        whiteList: {},
        blackList: {
          AccessLevel.teacher: ['id', 'school_board_id', 'school_id'],
          AccessLevel.teacherAdmin: ['id', 'school_board_id', 'school_id'],
          AccessLevel.schoolAdmin: [
            'id',
            'school_board_id',
            'school_id',
            'all_visa'
          ],
          AccessLevel.schoolBoardAdmin: ['id', 'school_board_id', 'all_visa'],
          AccessLevel.superAdmin: ['id', 'school_board_id'],
        },
        itemValidator: (user, item, previousItem) {
          return Future.value();
        },
      ),
    ]).validate();

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
    InternshipsRepository? internshipsRepository,
    bool tryRequestingLock = true,
  }) async {
    if (internshipsRepository == null) {
      throw InvalidRequestException(
          'Internships repository is required for this operation');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock) {
        throw InvalidRequestException(
            'You must acquire a lock before deleting this student');
      }
      return await requestLockAndPerformTask(
          id: id,
          user: user,
          task: () => deleteById(
              id: id,
              user: user,
              internshipsRepository: internshipsRepository,
              tryRequestingLock: false));
    }

    final student = await _getStudentById(id: id, user: user, teacher: null);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: student),
      HasMinimumAccessLevel(user: user, minimumLevel: AccessLevel.schoolAdmin),
      UserIsFromSameSchoolBoard(user: user, item: student),
      UserIsFromSameSchool(user: user, item: student),
      GenericPolicy(validationFunction: () async {
        // Prevent from deleting a student that has at least one internship
        if (user.accessLevel < AccessLevel.superAdmin) {
          final internships = (await internshipsRepository.getAll(
                user: user,
                fields:
                    FetchableFields({'student_id': FetchableFields.mandatory}),
              ))
                  .data ??
              {};
          if (internships.values
              .any((internship) => internship['student_id'] == id)) {
            throw InvalidRequestException(
                'You cannot delete this student because they have active internships');
          }
        }
      }),
    ]).validate();

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
    required Teacher? teacher,
  });

  Future<Student?> _getStudentById({
    required String id,
    required DatabaseUser user,
    required Teacher? teacher,
  });

  Future<void> _putStudent(
      {required Student student,
      required Student? previous,
      required DatabaseUser user});

  Future<String?> _deleteStudent({
    required String id,
    required DatabaseUser user,
  });

  Future<Teacher?> _fetchTeacher({
    required DatabaseUser user,
    required TeachersRepository? teachersRepository,
  }) async {
    if (teachersRepository == null) return null;
    if (user.accessLevel >= AccessLevel.schoolAdmin) return null;

    try {
      final teacherData = await teachersRepository.getById(
          id: user.userId!, fields: FetchableFields.all, user: user);
      return Teacher.fromSerialized(teacherData.data);
    } catch (e) {
      return null;
    }
  }

  Student _filterDataByAccessibility({
    required DatabaseUser user,
    required Teacher? teacher,
    required Student student,
  }) {
    // If the user has access, simply return
    if (user.accessLevel >= AccessLevel.schoolAdmin) return student;
    if (teacher == null) {
      throw InvalidRequestException(
          'Teacher information is required for this operation');
    }
    if (teacher.groups.contains(student.group) ||
        student.teacherInChargeId == teacher.id ||
        student.supplementaryTeacherInChargeIds.contains(teacher.id)) {
      return student;
    }

    // Otherwise, remove data from students for the teachers if they are not in the same group
    // This is for privacy reasons, so that teachers cannot see students from other groups than their own
    return Student.empty.copyWith(
        schoolBoardId: student.schoolBoardId,
        schoolId: student.schoolId,
        id: student.id,
        program: student.program,
        group: student.group);
  }
}

class MySqlStudentsRepository extends StudentsRepository {
  // coverage:ignore-start
  final SqlInterface sqlInterface;
  MySqlStudentsRepository({required this.sqlInterface});

  @override
  Future<Map<String, Student>> _getAllStudents({
    String? studentId,
    required DatabaseUser user,
    required Teacher? teacher,
  }) async {
    final schoolFilters = ({
      'school_board_id': user.accessLevel < AccessLevel.superAdmin
          ? user.schoolBoardId!
          : null,
    }..removeWhere((key, value) => value == null))
        .cast<String, dynamic>();

    final students = await sqlInterface.performSelectQuery(
      user: user,
      tableName: 'students',
      filters: (studentId == null ? {} : {'id': studentId})
        ..addAll(schoolFilters),
      subqueries: [
        sqlInterface.selectSubquery(
          dataTableName: 'persons',
          fieldsToFetch: ['first_name', 'last_name', 'date_birthday', 'email'],
        ),
        sqlInterface.selectSubquery(
          dataTableName: 'student_supplementary_teachers_in_charge',
          fieldsToFetch: ['teacher_id'],
          idNameToDataTable: 'student_id',
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
          fieldsToFetch: ['id', 'date', 'form_version'],
          idNameToDataTable: 'student_id',
        ),
      ],
    );

    final map = <String, Student>{};
    for (final student in students) {
      final id = student['id'].toString();
      student['group'] = student['group_name'];
      student['supplementary_teacher_in_charge_ids'] =
          (student['student_supplementary_teachers_in_charge'] as List?)
                  ?.map((e) => e['teacher_id'])
                  .toList() ??
              [];

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
          : DateTime.parse(student['date_birthday']).serialize();

      student['phone'] =
          (student['phone_numbers'] as List?)?.firstOrNull as Map? ?? {};
      student['address'] =
          (student['addresses'] as List?)?.firstOrNull as Map? ?? {};

      final allVisa = (student['all_visa'] as List? ?? []);
      for (final visa in allVisa) {
        final visaForm = (await sqlInterface.performSelectQuery(
              user: user,
              tableName: 'student_visa_forms',
              filters: {'form_id': visa['id']},
              subqueries: [
                sqlInterface.selectSubquery(
                  dataTableName: 'student_visa_experiences_and_aptitude_items',
                  asName: 'experiences_and_aptitudes',
                  fieldsToFetch: ['id', 'idx', 'text', 'is_selected'],
                  idNameToDataTable: 'visa_form_id',
                ),
                sqlInterface.selectSubquery(
                  dataTableName: 'student_visa_attestations_and_mentions_items',
                  asName: 'attestations_and_mentions',
                  fieldsToFetch: ['id', 'idx', 'text', 'is_selected'],
                  idNameToDataTable: 'visa_form_id',
                ),
                sqlInterface.selectSubquery(
                  dataTableName: 'student_visa_sst_training_items',
                  asName: 'sst_trainings',
                  fieldsToFetch: [
                    'id',
                    'idx',
                    'is_selected',
                    'is_hidden',
                    'training_id',
                  ],
                  idNameToDataTable: 'visa_form_id',
                ),
                sqlInterface.selectSubquery(
                  dataTableName: 'student_visa_certificate_items',
                  asName: 'certificates',
                  fieldsToFetch: [
                    'id',
                    'idx',
                    'is_selected',
                    'certificate_type',
                    'year',
                    'specialization_id'
                  ],
                  idNameToDataTable: 'visa_form_id',
                ),
                sqlInterface.selectSubquery(
                  dataTableName: 'student_visa_skill_items',
                  asName: 'skills',
                  fieldsToFetch: [
                    'id',
                    'idx',
                    'is_selected',
                    'skill_id',
                  ],
                  idNameToDataTable: 'visa_form_id',
                ),
                sqlInterface.selectSubquery(
                  dataTableName: 'student_visa_references_items',
                  asName: 'student_references',
                  fieldsToFetch: [
                    'id',
                    'idx',
                    'visa_form_id',
                    'is_selected',
                    'referee',
                    'enterprise',
                    'phone_number',
                    'email',
                    'supplementary_info',
                  ],
                  idNameToDataTable: 'visa_form_id',
                ),
                sqlInterface.selectSubquery(
                  dataTableName: 'student_visa_forces_items',
                  asName: 'forces',
                  fieldsToFetch: [
                    'id',
                    'idx',
                    'is_selected',
                    'attitude_id',
                  ],
                  idNameToDataTable: 'visa_form_id',
                ),
                sqlInterface.selectSubquery(
                  dataTableName: 'student_visa_challenges_items',
                  asName: 'challenges',
                  fieldsToFetch: [
                    'id',
                    'idx',
                    'is_selected',
                    'attitude_id',
                  ],
                  idNameToDataTable: 'visa_form_id',
                ),
                sqlInterface.selectSubquery(
                  dataTableName: 'student_visa_success_conditions_items',
                  asName: 'success_conditions',
                  fieldsToFetch: [
                    'id',
                    'idx',
                    'is_selected',
                    'text',
                  ],
                  idNameToDataTable: 'visa_form_id',
                ),
              ],
            ))
                .firstOrNull ??
            {};

        for (final element in visaForm['experiences_and_aptitudes'] ?? []) {
          element['index'] = element['idx'];
        }
        for (final element in visaForm['attestations_and_mentions'] ?? []) {
          element['index'] = element['idx'];
        }
        for (final element in visaForm['sst_trainings'] ?? []) {
          element['index'] = element['idx'];
        }
        for (final element in visaForm['certificates'] ?? []) {
          element['index'] = element['idx'];
        }
        for (final element in visaForm['skills'] ?? []) {
          element['index'] = element['idx'];
        }
        visaForm['references'] = visaForm['student_references'];
        for (final element in visaForm['references'] ?? []) {
          element['index'] = element['idx'];
        }
        for (final element in visaForm['forces'] ?? []) {
          element['index'] = element['idx'];
        }
        for (final element in visaForm['challenges'] ?? []) {
          element['index'] = element['idx'];
        }
        for (final element in visaForm['success_conditions'] ?? []) {
          element['index'] = element['idx'];
        }

        visa['form'] = visaForm;
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
    required Teacher? teacher,
  }) async =>
      (await _getAllStudents(studentId: id, user: user, teacher: teacher))[id];

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
      'teacher_in_charge_id': student.teacherInChargeId.serialize(),
      'contact_link': student.contactLink.serialize(),
    });
  }

  Future<void> _insertToSupplementaryTeachersInCharge(Student student) async {
    final toWait = <Future>[];
    for (final teacherId in student.supplementaryTeacherInChargeIds) {
      toWait.add(sqlInterface.performInsertQuery(
          tableName: 'student_supplementary_teachers_in_charge',
          data: {
            'student_id': student.id.serialize(),
            'teacher_id': teacherId.serialize(),
          }));
    }
    await Future.wait(toWait);
  }

  Future<void> _updateToSupplementaryTeachersInCharge(
      Student student, Student previous) async {
    final toWait = <Future>[];
    final newIds = student.supplementaryTeacherInChargeIds.toSet();
    final oldIds = previous.supplementaryTeacherInChargeIds.toSet();
    final toAdd = newIds.difference(oldIds);
    final toRemove = oldIds.difference(newIds);

    for (final teacherId in toAdd) {
      toWait.add(sqlInterface.performInsertQuery(
          tableName: 'student_supplementary_teachers_in_charge',
          data: {
            'student_id': student.id.serialize(),
            'teacher_id': teacherId.serialize(),
          }));
    }

    for (final teacherId in toRemove) {
      toWait.add(sqlInterface.performDeleteQuery(
          tableName: 'student_supplementary_teachers_in_charge',
          filters: {
            'student_id': student.id.serialize(),
            'teacher_id': teacherId.serialize(),
          }));
    }

    await Future.wait(toWait);
  }

  Future<void> _updateToStudents(
      Student student, Student previous, DatabaseUser user) async {
    final differences = student.getDifference(previous);
    if (differences.contains('school_id')) {
      await sqlInterface.performUpdateQuery(
          tableName: 'students',
          filters: {'id': student.id},
          data: {'school_id': student.schoolId});
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
    if (student.teacherInChargeId != previous.teacherInChargeId) {
      toUpdate['teacher_in_charge_id'] = student.teacherInChargeId.serialize();
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
    final differences = student.getDifference(previous);
    if (differences.contains('contact')) {
      await sqlInterface.performUpdatePerson(
          person: student.contact, previous: previous.contact);
    }
  }

  Future<void> _insertToVisa(Student student, [Student? previous]) async {
    for (final visa in student.allVisa) {
      if (previous?.allVisa.any((e) => e.id == visa.id) ?? false) {
        // Skip if the evaluation already exists
        continue;
      }

      await sqlInterface.performInsertQuery(tableName: 'student_visa', data: {
        'id': visa.id.serialize(),
        'date': visa.date.serialize(),
        'student_id': student.id,
        'form_version': visa.formVersion.serialize(),
      });

      // Insert the form
      await sqlInterface
          .performInsertQuery(tableName: 'student_visa_forms', data: {
        'id': visa.form.id.serialize(),
        'form_id': visa.id.serialize(),
        'is_gateway_to_fms_available':
            visa.form.isGatewayToFmsAvailable.serialize(),
      });

      final toWait = <Future>[];
      for (final element in visa.form.experiencesAndAptitudes) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_experiences_and_aptitude_items',
            data: {
              'id': element.id.serialize(),
              'idx': element.index.serialize(),
              'visa_form_id': visa.form.id,
              'text': element.text.serialize(),
              'is_selected': element.isSelected.serialize(),
            },
          ),
        );
      }
      for (final element in visa.form.attestationsAndMentions) {
        toWait.add(
          sqlInterface.performInsertQuery(
              tableName: 'student_visa_attestations_and_mentions_items',
              data: {
                'id': element.id.serialize(),
                'idx': element.index.serialize(),
                'visa_form_id': visa.form.id,
                'text': element.text.serialize(),
                'is_selected': element.isSelected.serialize(),
              }),
        );
      }
      for (final element in visa.form.sstTrainings) {
        toWait.add(
          sqlInterface.performInsertQuery(
              tableName: 'student_visa_sst_training_items',
              data: {
                'id': element.id.serialize(),
                'idx': element.index.serialize(),
                'visa_form_id': visa.form.id,
                'is_selected': element.isSelected.serialize(),
                'training_id': element.trainingId.serialize(),
                'is_hidden': element.isHidden.serialize(),
              }),
        );
      }
      for (final element in visa.form.certificates) {
        toWait.add(
          sqlInterface.performInsertQuery(
              tableName: 'student_visa_certificate_items',
              data: {
                'id': element.id.serialize(),
                'idx': element.index.serialize(),
                'visa_form_id': visa.form.id,
                'is_selected': element.isSelected.serialize(),
                'certificate_type': element.certificateType.name.serialize(),
                'specialization_id': element.specializationId?.serialize(),
                'year': element.year?.serialize(),
              }),
        );
      }
      for (final element in visa.form.skills) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_skill_items',
            data: {
              'id': element.id.serialize(),
              'idx': element.index.serialize(),
              'visa_form_id': visa.form.id,
              'is_selected': element.isSelected.serialize(),
              'skill_id': element.skillId.serialize(),
            },
          ),
        );
      }
      for (final element in visa.form.references) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_references_items',
            data: {
              'id': element.id.serialize(),
              'idx': element.index.serialize(),
              'visa_form_id': visa.form.id,
              'is_selected': element.isSelected.serialize(),
              'referee': element.referee.serialize(),
              'enterprise': element.enterprise.serialize(),
              'phone_number': element.phoneNumber.toString(),
              'email': element.email.toString(),
              'supplementary_info': element.supplementaryInfo.serialize(),
            },
          ),
        );
      }
      for (final element in visa.form.forces) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_forces_items',
            data: {
              'id': element.id.serialize(),
              'idx': element.index.serialize(),
              'visa_form_id': visa.form.id,
              'is_selected': element.isSelected.serialize(),
              'attitude_id': element.attitudeId.serialize(),
            },
          ),
        );
      }
      for (final element in visa.form.challenges) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_challenges_items',
            data: {
              'id': element.id.serialize(),
              'idx': element.index.serialize(),
              'visa_form_id': visa.form.id,
              'is_selected': element.isSelected.serialize(),
              'attitude_id': element.attitudeId.serialize(),
            },
          ),
        );
      }
      for (final element in visa.form.successConditions) {
        toWait.add(
          sqlInterface.performInsertQuery(
            tableName: 'student_visa_success_conditions_items',
            data: {
              'id': element.id.serialize(),
              'idx': element.index.serialize(),
              'visa_form_id': visa.form.id,
              'is_selected': element.isSelected.serialize(),
              'text': element.text.serialize(),
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
    try {
      await sqlInterface.beginTransaction();

      if (previous == null) {
        await _insertToStudents(student);
        await _insertToSupplementaryTeachersInCharge(student);
        await _insertToContacts(student);
        await _insertToVisa(student);
      } else {
        await _updateToStudents(student, previous, user);
        await _updateToSupplementaryTeachersInCharge(student, previous);
        await _updateToContacts(
            student: student, previous: previous, user: user);
        await _updateToVisa(student, previous);
      }

      await sqlInterface.commitTransaction();
    } catch (e) {
      await sqlInterface.rollbackTransaction();
      rethrow;
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
      await sqlInterface.beginTransaction();

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

      await sqlInterface.commitTransaction();
      return id;
    } catch (e) {
      await sqlInterface.rollbackTransaction();
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
      lastName: 'Doe',
      phone: PhoneNumber.fromString('098-765-4321'),
      email: 'john.doe@email.com',
      dateBirth: null,
      address: Address.empty,
      program: Program.fms,
      group: 'A',
      teacherInChargeId: '',
      supplementaryTeacherInChargeIds: [],
      contact: Person(
          id: '1',
          firstName: 'Jane',
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
      lastName: 'Doe',
      phone: PhoneNumber.fromString('123-456-7890'),
      email: 'jane.doe@email.com',
      dateBirth: null,
      address: Address.empty,
      program: Program.fms,
      group: 'A',
      teacherInChargeId: '',
      supplementaryTeacherInChargeIds: [],
      contact: Person(
          id: '0',
          firstName: 'John',
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
    required Teacher? teacher,
  }) async =>
      _dummyDatabase;

  @override
  Future<Student?> _getStudentById({
    required String id,
    required DatabaseUser user,
    required Teacher? teacher,
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
