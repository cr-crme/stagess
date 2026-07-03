import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:stagess_backend/repositories/repository_abstract.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/repositories/students_repository.dart';
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
import 'package:stagess_common/models/internships/internship_contract.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/time_utils.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/utils.dart';

// AccessLevel in this repository is discarded as all operations are currently
// available to all users

abstract class InternshipsRepository extends RepositoryAbstract {
  @override
  Future<RepositoryResponse> getAll({
    required FetchableFields fields,
    required DatabaseUser user,
    StudentsRepository? studentsRepository,
  }) async {
    if (studentsRepository == null) {
      throw ArgumentError(
          'studentsRepository is required to get internships with access control');
    }

    final students = (await studentsRepository.getAll(
                fields: FetchableFields({'id': FetchableFields.all}),
                user: user))
            .data
            ?.keys
            .toList() ??
        [];

    final internships =
        await _getAllInternships(user: user, students: students);

    await SecurityPolicies([
      UserIsVerified(user: user),
      // Access control were valided when fetching students
    ]).validate();

    return RepositoryResponse(
        data: internships.map(
            (key, value) => MapEntry(key, value.serializeWithFields(fields))));
  }

  @override
  Future<RepositoryResponse> getById({
    required String id,
    required FetchableFields fields,
    required DatabaseUser user,
    StudentsRepository? studentsRepository,
  }) async {
    if (studentsRepository == null) {
      throw ArgumentError(
          'studentsRepository is required to get internships with access control');
    }

    final internship = await _getInternshipById(id: id, user: user);
    await studentsRepository.getById(
        id: internship?.studentId ?? '-1',
        fields: FetchableFields({'id': FetchableFields.all}),
        user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: internship),
      // Access control were valided when fetching students
    ]).validate();

    return RepositoryResponse(data: internship!.serializeWithFields(fields));
  }

  @override
  Future<RepositoryResponse> putById({
    required String id,
    required Map<String, dynamic> data,
    required DatabaseUser user,
    StudentsRepository? studentsRepository,
    TeachersRepository? teachersRepository,
    bool tryRequestingLock = true,
  }) async {
    if (studentsRepository == null) {
      throw ArgumentError(
          'studentsRepository is required to put internships with access control');
    }
    if (teachersRepository == null) {
      throw ArgumentError(
          'teachersRepository is required to put internships with access control');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock) {
        throw InvalidRequestException(
            'You must acquire a lock before editing this internship');
      }
      return await requestLockAndPerformTask(
          id: id,
          user: user,
          task: () => putById(
              id: id,
              data: data,
              user: user,
              studentsRepository: studentsRepository,
              teachersRepository: teachersRepository,
              tryRequestingLock: false));
    }

    // Update if exists, insert if not
    final previous = await _getInternshipById(id: id, user: user);
    final newInternship = previous?.copyWithData(data) ??
        Internship.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: newInternship),
      // Access control were valided when fetching students
      ModificationsAreValid(
        user: user,
        item: newInternship,
        previous: previous,
        allowedToCreate: [
          AccessLevel.teacher,
          AccessLevel.schoolAdmin,
          AccessLevel.schoolBoardAdmin,
          AccessLevel.superAdmin,
        ],
        allowedToModify: [
          AccessLevel.teacher,
          AccessLevel.schoolAdmin,
          AccessLevel.schoolBoardAdmin,
          AccessLevel.superAdmin,
        ],
        whiteList: {},
        blackList: {
          AccessLevel.teacher: [
            'id',
            'enterprise_id',
            'signatory_teacher_id',
            'student_id',
          ],
          AccessLevel.schoolAdmin: [
            'id',
            'enterprise_id',
            'signatory_teacher_id',
            'student_id',
          ],
          AccessLevel.schoolBoardAdmin: [
            'id',
            'enterprise_id',
            'signatory_teacher_id',
            'student_id',
          ],
          AccessLevel.superAdmin: [
            'id',
            'enterprise_id',
            'signatory_teacher_id',
            'student_id',
          ],
        },
        itemValidator: (user, item, previousItem) async {
          if (item.enterpriseId.isEmpty) {
            throw InvalidRequestException(
                'An internship must be associated with an enterprise');
          }
          if (item.signatoryTeacherId.isEmpty) {
            throw InvalidRequestException(
                'An internship must have a signatory teacher');
          }
          if (item.studentId.isEmpty) {
            throw InvalidRequestException(
                'An internship must be associated with a student');
          }
          if (user.accessLevel < AccessLevel.schoolAdmin) {
            final student = await studentsRepository.getById(
                id: newInternship.studentId,
                fields: FetchableFields(
                    {'id': FetchableFields.all, 'group': FetchableFields.all}),
                user: user);
            final studentGroup = student.data!['group'];
            if (studentGroup == null ||
                studentGroup is! String ||
                studentGroup.isEmpty) {
              throw InvalidRequestException(
                  'The student associated with this internship must be in a group');
            }

            final teacher = await teachersRepository.getById(
                id: user.userId ?? '-1',
                fields: FetchableFields(
                    {'id': FetchableFields.all, 'groups': FetchableFields.all}),
                user: user);
            final teacherId = teacher.data?['id'];
            if (teacherId == null ||
                teacherId is! String ||
                teacherId.isEmpty) {
              throw InvalidRequestException(
                  'The teacher id could not be found');
            }
            final teacherGroups = teacher.data?['groups'];
            if (teacherGroups == null || teacherGroups is! List) {
              throw InvalidRequestException(
                  'The signatory teacher associated with this internship must be in a group');
            }

            if (!teacherGroups.contains(studentGroup)) {
              throw InvalidRequestException(
                  'The signatory teacher must be in the same group as the student for this internship');
            }
            if (item.signatoryTeacherId != teacherId) {
              final newExtraTeachers = [...item.extraSupervisingTeacherIds]
                ..remove(teacherId);
              final oldExtraTeachers = [
                ...?previousItem?.extraSupervisingTeacherIds
              ]..remove(teacherId);
              if (!areListsEqual(newExtraTeachers, oldExtraTeachers)) {
                throw InvalidRequestException(
                    'You cannot change the supervising status of another teacher');
              }
            }
            if (!item.supervisingTeacherIds.contains(teacherId) &&
                !(previousItem?.supervisingTeacherIds.contains(teacherId) ??
                    false)) {
              throw InvalidRequestException(
                  'The signatory teacher must be a supervising teacher for this internship');
            }

            if (!item.supervisingTeacherIds.contains(teacherId)) {
              // If the teacher removed themselves, this is the only modification they are allowed to do
              final differences = item.getDifference(previousItem,
                  ignoreKeys: ['id', 'extra_supervising_teacher_ids']);
              if (differences.isNotEmpty) {
                throw InvalidRequestException(
                    'You cannot modify this internship if you remove yourself from the supervising teachers');
              }
            }
          }

          // Make sure current contract is valid
          if (item.currentContract == null) {
            throw InvalidRequestException(
                'An internship must have a current contract');
          }
          if (item.currentContract!.jobId.isEmpty) {
            throw InvalidRequestException(
                'An internship contract must have a job');
          }
          if (item.currentContract!.specializationId.isEmpty) {
            throw InvalidRequestException(
                'An internship contract must have a specialization');
          }
          if (item.currentContract!.program == Program.undefined) {
            throw InvalidRequestException(
                'An internship contract must have a program');
          }

          final contractDifferences = (previousItem == null
                  ? null
                  : item.currentContract
                      ?.getDifference(previousItem.currentContract)) ??
              [];
          if (contractDifferences.contains('specialization_id') ||
              contractDifferences.contains('extra_specialization_ids') ||
              contractDifferences.contains('job_id') ||
              contractDifferences.contains('program')) {
            throw InvalidRequestException(
                'You cannot change the fundamentals of an internship contract');
          }

          // Previous contracts are not allowed to be modified
          if (previousItem != null) {
            if (item.contracts.length < previousItem.contracts.length) {
              throw InvalidRequestException(
                  'You cannot delete internship contracts');
            }
            for (int i = 0; i < previousItem.contracts.length; i++) {
              final contract = item.contracts[i];
              final previousContract = previousItem.contracts[i];
              if (contract.id != previousContract.id) {
                throw InvalidRequestException(
                    'You cannot reorder internship contracts');
              }
              final differences =
                  contract.getDifference(previousContract, ignoreKeys: ['id']);
              if (differences.isNotEmpty) {
                throw InvalidRequestException(
                    'You cannot change the fundamentals of an internship contract');
              }
            }
          }

          return Future.value();
        },
      ),
    ]).validate();

    await _putInternship(
        internship: newInternship, previous: previous, user: user);
    return RepositoryResponse(updatedData: {
      RequestFields.internship: {
        newInternship.id: Internship.fetchableFields
            .extractFrom(newInternship.getDifference(previous))
      }
    });
  }

  @override
  Future<RepositoryResponse> deleteById({
    required String id,
    required DatabaseUser user,
    StudentsRepository? studentsRepository,
    bool tryRequestingLock = true,
  }) async {
    if (studentsRepository == null) {
      throw ArgumentError(
          'studentsRepository is required to delete internships');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock) {
        throw InvalidRequestException(
            'You must acquire a lock before deleting this internship');
      }
      return await requestLockAndPerformTask(
          id: id,
          user: user,
          task: () => deleteById(
              id: id,
              user: user,
              studentsRepository: studentsRepository,
              tryRequestingLock: false));
    }

    final internship = await _getInternshipById(id: id, user: user);
    await studentsRepository.getById(
        id: internship?.studentId ?? '-1',
        fields: FetchableFields({'id': FetchableFields.all}),
        user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: internship),
      HasMinimumAccessLevel(user: user, minimumLevel: AccessLevel.schoolAdmin),
      // Access control were valided when fetching students
    ]).validate();

    final removedId = await _deleteInternship(id: id, user: user);
    if (removedId == null) {
      throw DatabaseFailureException('Failed to delete internship with id $id');
    }
    return RepositoryResponse(deletedData: {
      RequestFields.internship: {removedId: FetchableFields.all}
    });
  }

  Future<Map<String, Internship>> _getAllInternships({
    required DatabaseUser user,
    required List<String> students,
  });

  Future<Internship?> _getInternshipById({
    required String id,
    required DatabaseUser user,
  });

  Future<void> _putInternship({
    required Internship internship,
    required Internship? previous,
    required DatabaseUser user,
  });

  Future<String?> _deleteInternship({
    required String id,
    required DatabaseUser user,
  });
}

class MySqlInternshipsRepository extends InternshipsRepository {
  // coverage:ignore-start
  final SqlInterface sqlInterface;
  MySqlInternshipsRepository({required this.sqlInterface});

  @override
  Future<Map<String, Internship>> _getAllInternships({
    String? internshipId,
    required DatabaseUser user,
    required List<String> students,
  }) async {
    final studentFilters = ({
      'student_id':
          user.accessLevel < AccessLevel.superAdmin && internshipId == null
              ? students
              : null,
    }..removeWhere((key, value) => value == null))
        .cast<String, List<String>>();

    final internships = await sqlInterface.performSelectQuery(
        user: user,
        tableName: 'internships',
        filters: (internshipId == null ? {} : {'id': internshipId})
          ..addAll(studentFilters),
        subqueries: [
          sqlInterface.selectSubquery(
            dataTableName: 'internship_supervising_teachers',
            asName: 'supervising_teachers',
            fieldsToFetch: ['teacher_id', 'is_signatory_teacher'],
            idNameToDataTable: 'internship_id',
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'internship_contracts',
            asName: 'contracts',
            fieldsToFetch: [
              'id',
              'date',
              'job_id',
              'specialization_id',
              'program',
              'supervisor_first_name',
              'supervisor_last_name',
              'supervisor_phone_number',
              'supervisor_email',
              'starting_date',
              'ending_date',
              'visit_frequencies',
              'expected_duration',
            ],
            idNameToDataTable: 'internship_id',
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'internship_skill_evaluations',
            asName: 'skill_evaluations',
            fieldsToFetch: [
              'id',
              'date',
              'skill_granularity',
              'comments',
              'form_version'
            ],
            idNameToDataTable: 'internship_id',
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'internship_attitude_evaluations',
            asName: 'attitude_evaluations',
            fieldsToFetch: [
              'id',
              'date',
              'ponctuality',
              'inattendance',
              'quality_of_work',
              'productivity',
              'team_communication',
              'respect_of_authority',
              'communication_about_sst',
              'self_control',
              'take_initiative',
              'adaptability',
              'form_version'
            ],
            idNameToDataTable: 'internship_id',
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'post_internship_enterprise_evaluations',
            asName: 'enterprise_evaluations',
            fieldsToFetch: [
              'id',
              'date',
              'internship_id',
              'program',
              'task_variety',
              'training_plan_respect',
              'autonomy_expected',
              'efficiency_expected',
              'special_needs_accommodation',
              'supervision_style',
              'ease_of_communication',
              'absence_acceptance',
              'sst_supervision',
            ],
            idNameToDataTable: 'internship_id',
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'internship_sst_evaluations',
            asName: 'sst_evaluations',
            idNameToDataTable: 'internship_id',
            fieldsToFetch: ['id', 'internship_id', 'date'],
          ),
        ]);

    final map = <String, Internship>{};
    for (final internship in internships) {
      final id = internship['id'].toString();
      internship['signatory_teacher_id'] =
          (internship['supervising_teachers'] as List?)?.firstWhereOrNull(
              (e) => e['is_signatory_teacher'] as int == 1)?['teacher_id'];
      if (internship['signatory_teacher_id'] == null) {
        throw MissingDataException('Internship $id has no signatory teacher');
      }
      internship['extra_supervising_teacher_ids'] =
          (internship['supervising_teachers'] as List?)
                  ?.map((e) => e['teacher_id'].toString())
                  .toList() ??
              [];

      final contracts = [];
      for (final contract in (internship['contracts'] as List? ?? [])) {
        final extraSpecializationIds = await sqlInterface.performSelectQuery(
            user: user,
            tableName: 'internship_extra_specializations',
            filters: {'contract_id': contract['id']});
        final schedules = await sqlInterface.performSelectQuery(
            user: user,
            tableName: 'internship_weekly_schedules',
            filters: {
              'contract_id': contract['id']
            },
            subqueries: [
              sqlInterface.selectSubquery(
                dataTableName: 'internship_daily_schedules',
                asName: 'daily_schedules',
                fieldsToFetch: [
                  'id',
                  'starting_hour',
                  'starting_minute',
                  'ending_hour',
                  'ending_minute',
                  'day',
                  'block_index',
                ],
                idNameToDataTable: 'weekly_schedule_id',
              ),
            ]);

        for (final schedule in schedules) {
          schedule['start'] = schedule['starting_date'];
          schedule['end'] = schedule['ending_date'];
          schedule['days'] = {};
          for (final map in (schedule['daily_schedules'] as List? ?? [])) {
            final dayKey = map['day'].toString();
            if (schedule['days'][dayKey] == null) {
              schedule['days'][dayKey] = {'id': map['id'], 'blocks': []};
            }
            (schedule['days'][dayKey]['blocks'] as List).add({
              'sort_index': map['block_index'],
              'start': [map['starting_hour'], map['starting_minute']],
              'end': [map['ending_hour'], map['ending_minute']],
            });
          }

          for (final day in (schedule['days'] as Map).keys) {
            (schedule['days'][day]['blocks'] as List).sort(
              (a, b) =>
                  (a['sort_index'] as int).compareTo(b['sort_index'] as int),
            );
          }
        }

        final transportations = await sqlInterface.performSelectQuery(
            user: user,
            tableName: 'internship_transportations',
            filters: {'contract_id': contract['id']});
        contract['transportations'] = (transportations as List? ?? [])
            .map((e) => e['transportation'])
            .toList();

        contract['extra_specialization_ids'] =
            (extraSpecializationIds as List? ?? [])
                .map((e) => e['specialization_id'].toString())
                .toList();
        contract['schedules'] = schedules;
        contracts.add(contract);
      }
      internship['contracts'] = contracts;

      final skillEvaluations = [];
      for (final Map<String, dynamic> evaluation
          in (internship['skill_evaluations'] as List? ?? [])) {
        final evaluationSubquery = (await sqlInterface.performSelectQuery(
                user: user,
                tableName: 'internship_skill_evaluations',
                filters: {
              'id': evaluation['id']
            },
                subqueries: [
              sqlInterface.selectSubquery(
                dataTableName: 'internship_skill_evaluation_persons',
                asName: 'present',
                fieldsToFetch: ['person_name'],
                idNameToDataTable: 'evaluation_id',
              ),
              sqlInterface.selectSubquery(
                dataTableName: 'internship_skill_evaluation_items',
                asName: 'skills',
                fieldsToFetch: [
                  'id',
                  'specialization_id',
                  'skill_id',
                  'appreciation',
                  'comments'
                ],
                idNameToDataTable: 'evaluation_id',
              ),
            ]))
            .first;

        evaluation['skills'] = [];
        for (final skill in (evaluationSubquery['skills'] as List? ?? [])) {
          final tasks = await sqlInterface.performSelectQuery(
            user: user,
            tableName: 'internship_skill_evaluation_item_tasks',
            filters: {'evaluation_item_id': skill['id']},
          );
          evaluation['skills'].add({
            'id': skill['id'],
            'specialization_id': skill['specialization_id'],
            'skill_id': skill['skill_id'],
            'appreciation': skill['appreciation'],
            'comments': skill['comments'],
            'tasks': [
              for (final task in (tasks as List? ?? []))
                {
                  'id': task['id'],
                  'title': task['title'],
                  'level': task['level']
                }
            ],
          });
        }

        evaluation['present'] = [
          for (final person in (evaluationSubquery['present'] as List? ?? []))
            person['person_name']
        ];
        skillEvaluations.add(evaluation);
      }
      internship['skill_evaluations'] = skillEvaluations;

      final attitudeEvaluations = [];
      for (final Map<String, dynamic> evaluation
          in (internship['attitude_evaluations'] as List? ?? [])) {
        final evaluationSubquery = (await sqlInterface.performSelectQuery(
                user: user,
                tableName: 'internship_attitude_evaluations',
                filters: {
              'id': evaluation['id'],
            },
                subqueries: [
              sqlInterface.selectSubquery(
                dataTableName: 'internship_attitude_evaluation_persons',
                asName: 'present',
                fieldsToFetch: ['person_name'],
                idNameToDataTable: 'evaluation_id',
              )
            ]))
            .first;

        evaluation['attitude'] = {
          'ponctuality': evaluation['ponctuality'],
          'inattendance': evaluation['inattendance'],
          'quality_of_work': evaluation['quality_of_work'],
          'productivity': evaluation['productivity'],
          'team_communication': evaluation['team_communication'],
          'respect_of_authority': evaluation['respect_of_authority'],
          'communication_about_sst': evaluation['communication_about_sst'],
          'self_control': evaluation['self_control'],
          'take_initiative': evaluation['take_initiative'],
          'adaptability': evaluation['adaptability'],
        };
        evaluation['present'] = [
          for (final person in (evaluationSubquery['present'] as List? ?? []))
            person['person_name']
        ];
        attitudeEvaluations.add(evaluation);
      }
      internship['attitude_evaluations'] = attitudeEvaluations;

      final sstEvaluations = [];
      for (final Map<String, dynamic> evaluation
          in (internship['sst_evaluations'] as List? ?? [])) {
        final evaluationSubquery = (await sqlInterface.performSelectQuery(
          user: user,
          tableName: 'internship_sst_evaluations',
          filters: {'id': evaluation['id']},
          subqueries: [
            sqlInterface.selectSubquery(
              dataTableName: 'internship_sst_evaluation_persons',
              asName: 'present',
              fieldsToFetch: ['person_name'],
              idNameToDataTable: 'evaluation_id',
            ),
            sqlInterface.selectSubquery(
              dataTableName: 'internship_sst_evaluation_questions',
              asName: 'questions',
              fieldsToFetch: ['question', 'answers'],
              idNameToDataTable: 'evaluation_id',
            ),
          ],
        ))
            .first;

        evaluation['present_at_evaluation'] = [
          for (final person in (evaluationSubquery['present'] as List? ?? []))
            person['person_name']
        ];
        evaluation['questions'] = jsonEncode({
          for (final Map question
              in (evaluationSubquery['questions'] as List?) ?? [])
            question['question']:
                (question['answers'] as String?)?.split('\n') ?? []
        });

        sstEvaluations.add(evaluation);
      }
      internship['sst_evaluations'] = sstEvaluations;

      final enterpriseEvaluations = [];
      for (final evaluation
          in (internship['enterprise_evaluations'] as List?) ?? []) {
        final skills = await sqlInterface.performSelectQuery(
            user: user,
            tableName: 'post_internship_enterprise_evaluation_skills',
            filters: {'post_evaluation_id': evaluation['id']});
        evaluation['skills_required'] = [
          for (final skill in (skills as List? ?? [])) skill['skill_name']
        ];
        enterpriseEvaluations.add(evaluation);
      }
      internship['enterprise_evaluations'] = enterpriseEvaluations;

      map[id] = Internship.fromSerialized(internship);
    }
    return map;
  }

  @override
  Future<Internship?> _getInternshipById({
    required String id,
    required DatabaseUser user,
  }) async {
    return (await _getAllInternships(
        internshipId: id, user: user, students: []))[id];
  }

  Future<void> _insertToInternships(Internship internship) async {
    // Insert the internship
    await sqlInterface.performInsertQuery(
        tableName: 'entities', data: {'shared_id': internship.id});
    await sqlInterface.performInsertQuery(tableName: 'internships', data: {
      'id': internship.id,
      'student_id': internship.studentId.serialize(),
      'enterprise_id': internship.enterpriseId.serialize(),
      'achieved_duration': internship.achievedDuration.serialize(),
      'teacher_notes': internship.teacherNotes.serialize(),
      'end_date': internship.endDate.serialize(),
    });
  }

  Future<void> _updateToInternships(
      Internship internship, Internship previous) async {
    // Update the internship
    final differences = internship.getDifference(previous);

    final toUpdate = <String, dynamic>{};
    if (differences.contains('achieved_duration')) {
      toUpdate['achieved_duration'] = internship.achievedDuration.serialize();
    }
    if (differences.contains('teacher_notes')) {
      toUpdate['teacher_notes'] = internship.teacherNotes.serialize();
    }
    if (differences.contains('end_date')) {
      toUpdate['end_date'] = internship.endDate.serialize();
    }
    if (toUpdate.isNotEmpty) {
      await sqlInterface.performUpdateQuery(
          tableName: 'internships',
          filters: {'id': internship.id},
          data: toUpdate);
    }
  }

  Future<void> _insertToSupervisingTeachers(Internship internship) async {
    final toWait = <Future>[];
    for (final teacherId in internship.supervisingTeacherIds) {
      toWait.add(sqlInterface.performInsertQuery(
          tableName: 'internship_supervising_teachers',
          data: {
            'internship_id': internship.id,
            'teacher_id': teacherId,
            'is_signatory_teacher': teacherId == internship.signatoryTeacherId
          }));
    }
    await Future.wait(toWait);
  }

  Future<void> _updateToSupervisingTeachers(
      Internship internship, Internship previous) async {
    final toUpdate = internship.getDifference(previous);
    if (toUpdate.contains('signatory_teacher_id') ||
        toUpdate.contains('extra_supervising_teacher_ids')) {
      // This is a bit tricky to simply update, so we delete and reinsert
      await sqlInterface.performDeleteQuery(
          tableName: 'internship_supervising_teachers',
          filters: {'internship_id': internship.id});

      await _insertToSupervisingTeachers(internship);
    }
  }

  Future<void> _insertToContracts(Internship internship,
      {Internship? previous, required DatabaseUser user}) async {
    final previousContracts = previous?.contracts ?? [];
    for (final contract in internship.contracts) {
      if (previousContracts.any((prev) => prev.id == contract.id)) {
        // Skip if the contract already exists
        continue;
      }
      await sqlInterface
          .performInsertQuery(tableName: 'internship_contracts', data: {
        'id': contract.id,
        'internship_id': internship.id,
        'date': contract.date.serialize(),
        'job_id': contract.jobId.serialize(),
        'specialization_id': contract.specializationId.serialize(),
        'program':
            contract.program.serialize(InternshipContract.currentVersion),
        'supervisor_first_name': contract.supervisor.firstName.serialize(),
        'supervisor_last_name': contract.supervisor.lastName.serialize(),
        'supervisor_phone_number':
            contract.supervisor.phone.serialize()['phone_number'],
        'supervisor_email': contract.supervisor.email.serialize(),
        'starting_date': contract.dates.start.serialize(),
        'ending_date': contract.dates.end.serialize(),
        'visit_frequencies': contract.visitFrequencies.serialize(),
        'expected_duration': contract.expectedDuration.serialize(),
      });

      final toWait = <Future>[];
      for (final specializationId in contract.extraSpecializationIds) {
        toWait.add(sqlInterface.performInsertQuery(
            tableName: 'internship_extra_specializations',
            data: {
              'contract_id': contract.id,
              'specialization_id': specializationId
            }));
      }

      // Insert the weekly schedules
      for (final weeklySchedule in contract.weeklySchedules) {
        toWait.add(sqlInterface.performInsertQuery(
            tableName: 'internship_weekly_schedules',
            data: {
              'id': weeklySchedule.id,
              'contract_id': contract.id,
              'starting_date': weeklySchedule.period.start.serialize(),
              'ending_date': weeklySchedule.period.end.serialize(),
              'cycle': weeklySchedule.dayCycle.serialize(),
            }));

        // Insert the daily schedules
        for (final key in weeklySchedule.schedule.keys) {
          final day = key;
          final schedule = weeklySchedule.schedule[key]!;
          for (int blockIndex = 0;
              blockIndex < schedule.blocks.length;
              blockIndex++) {
            toWait.add(sqlInterface.performInsertQuery(
                tableName: 'internship_daily_schedules',
                data: {
                  'id': schedule.id,
                  'weekly_schedule_id': weeklySchedule.id,
                  'day': day,
                  'block_index': blockIndex,
                  'starting_hour': schedule.blocks[blockIndex].start.hour,
                  'starting_minute': schedule.blocks[blockIndex].start.minute,
                  'ending_hour': schedule.blocks[blockIndex].end.hour,
                  'ending_minute': schedule.blocks[blockIndex].end.minute,
                }));
          }
        }
      }

      // Insert the transportations
      for (final transportation in contract.transportations) {
        toWait.add(sqlInterface
            .performInsertQuery(tableName: 'internship_transportations', data: {
          'contract_id': contract.id,
          'transportation': transportation.serialize(),
        }));
      }

      await Future.wait(toWait);
    }
  }

  Future<void> _updateToContracts(
      Internship internship, Internship previous, DatabaseUser user) async {
    // We don't update the contracts data, but stack them
    await _insertToContracts(internship, previous: previous, user: user);
  }

  Future<void> _insertToSkillEvaluations(Internship internship,
      [Internship? previous]) async {
    for (final evaluation in internship.skillEvaluations.serialize()) {
      if (previous?.skillEvaluations.any((e) => e.id == evaluation['id']) ??
          false) {
        // Skip if the evaluation already exists
        continue;
      }

      await sqlInterface
          .performInsertQuery(tableName: 'internship_skill_evaluations', data: {
        'id': evaluation['id'],
        'internship_id': internship.id,
        'date': evaluation['date'],
        'skill_granularity': evaluation['skill_granularity'],
        'comments': evaluation['comments'],
        'form_version': evaluation['form_version'],
      });

      // Insert the persons present at the evaluation
      for (final name in evaluation['present'] as List) {
        await sqlInterface.performInsertQuery(
            tableName: 'internship_skill_evaluation_persons',
            data: {
              'evaluation_id': evaluation['id'],
              'person_name': name,
            });
      }

      // Insert the skills
      for (final skill in evaluation['skills'] as List) {
        await sqlInterface.performInsertQuery(
            tableName: 'internship_skill_evaluation_items',
            data: {
              'id': skill['id'],
              'evaluation_id': evaluation['id'],
              'specialization_id': skill['specialization_id'],
              'skill_id': skill['skill_id'],
              'appreciation': skill['appreciation'],
              'comments': skill['comments'],
            });

        // Insert the tasks
        for (final task in skill['tasks'] as List) {
          await sqlInterface.performInsertQuery(
              tableName: 'internship_skill_evaluation_item_tasks',
              data: {
                'id': task['id'],
                'evaluation_item_id': skill['id'],
                'title': task['title'],
                'level': task['level'],
              });
        }
      }
    }
  }

  Future<void> _updateToSkillEvaluations(
      Internship internship, Internship previous) async {
    // Skill evaluations are not updated, but stacked
    await _insertToSkillEvaluations(internship, previous);
  }

  Future<void> _insertToAttitudeEvaluations(Internship internship,
      [Internship? previous]) async {
    for (final evaluation in internship.attitudeEvaluations.serialize()) {
      if (previous?.attitudeEvaluations.any((e) => e.id == evaluation['id']) ??
          false) {
        // Skip if the evaluation already exists
        continue;
      }

      await sqlInterface.performInsertQuery(
          tableName: 'internship_attitude_evaluations',
          data: {
            'id': evaluation['id'],
            'internship_id': internship.id,
            'date': evaluation['date'],
            'ponctuality': evaluation['attitude']['ponctuality'],
            'inattendance': evaluation['attitude']['inattendance'],
            'quality_of_work': evaluation['attitude']['quality_of_work'],
            'productivity': evaluation['attitude']['productivity'],
            'team_communication': evaluation['attitude']['team_communication'],
            'respect_of_authority': evaluation['attitude']
                ['respect_of_authority'],
            'communication_about_sst': evaluation['attitude']
                ['communication_about_sst'],
            'self_control': evaluation['attitude']['self_control'],
            'take_initiative': evaluation['attitude']['take_initiative'],
            'adaptability': evaluation['attitude']['adaptability'],
            'form_version': evaluation['form_version'],
          });

      // Insert the persons present at the evaluation
      for (final name in evaluation['present'] as List) {
        await sqlInterface.performInsertQuery(
            tableName: 'internship_attitude_evaluation_persons',
            data: {
              'evaluation_id': evaluation['id'],
              'person_name': name,
            });
      }
    }
  }

  Future<void> _updateToAttitudeEvaluations(
      Internship internship, Internship previous) async {
    // Attitude evaluations are not updated, but stacked
    await _insertToAttitudeEvaluations(internship, previous);
  }

  Future<void> _insertJobSstEvaluation(Internship internship,
      [Internship? previous]) async {
    for (final evaluation in internship.sstEvaluations.serialize()) {
      if (previous?.sstEvaluations.any((e) => e.id == evaluation['id']) ??
          false) {
        // Skip if the evaluation already exists
        continue;
      }
      final toWait = <Future>[];

      await sqlInterface
          .performInsertQuery(tableName: 'internship_sst_evaluations', data: {
        'id': evaluation['id'],
        'internship_id': internship.id,
        'date': evaluation['date'],
      });

      for (final person
          in (evaluation['present_at_evaluation'] as List? ?? [])) {
        toWait.add(sqlInterface.performInsertQuery(
            tableName: 'internship_sst_evaluation_persons',
            data: {'evaluation_id': evaluation['id'], 'person_name': person}));
      }

      final questions = jsonDecode(evaluation['questions']) as Map?;
      for (final question in (questions?.keys.toList() ?? [])) {
        final answers = (questions![question] as List?)?.join('\n');
        if (answers == null) continue;
        toWait.add(sqlInterface.performInsertQuery(
            tableName: 'internship_sst_evaluation_questions',
            data: {
              'evaluation_id': evaluation['id'],
              'question': question,
              'answers': answers,
            }));
      }

      await Future.wait(toWait);
    }
  }

  Future<void> _updateJobSstEvaluation(
      Internship internship, Internship previous) async {
    // SST evaluations are not updated, but stacked
    await _insertJobSstEvaluation(internship, previous);
  }

  Future<void> _insertToEnterpriseEvaluation(Internship internship) async {
    final toWait = <Future>[];
    for (final evaluation in internship.enterpriseEvaluations) {
      final serialized = evaluation.serialize();
      await sqlInterface.performInsertQuery(
          tableName: 'post_internship_enterprise_evaluations',
          data: {
            'id': serialized['id'],
            'date': serialized['date'],
            'internship_id': internship.id,
            'program': serialized['program'],
            'task_variety': serialized['task_variety'],
            'training_plan_respect': serialized['training_plan_respect'],
            'autonomy_expected': serialized['autonomy_expected'],
            'efficiency_expected': serialized['efficiency_expected'],
            'special_needs_accommodation':
                serialized['special_needs_accommodation'],
            'supervision_style': serialized['supervision_style'],
            'ease_of_communication': serialized['ease_of_communication'],
            'absence_acceptance': serialized['absence_acceptance'],
            'sst_supervision': serialized['sst_supervision'],
          });

      for (final skill in (serialized['skills_required'] as List?) ?? []) {
        toWait.add(sqlInterface.performInsertQuery(
            tableName: 'post_internship_enterprise_evaluation_skills',
            data: {
              'post_evaluation_id': serialized['id'],
              'skill_name': skill
            }));
      }
    }

    await Future.wait(toWait);
  }

  Future<void> _updateToEnterpriseEvaluation(
      Internship internship, Internship previous) async {
    final toUpdate = internship.getDifference(previous);
    if (!toUpdate.contains('enterprise_evaluations')) return;

    // First remove the all the previous evaluations to start fresh
    final toWait = <Future>[];
    for (final evaluation in previous.enterpriseEvaluations) {
      toWait.add(sqlInterface.performDeleteQuery(
          tableName: 'post_internship_enterprise_evaluations',
          filters: {'id': evaluation.id}));
      toWait.add(sqlInterface.performDeleteQuery(
          tableName: 'post_internship_enterprise_evaluation_skills',
          filters: {'post_evaluation_id': evaluation.id}));
    }
    await Future.wait(toWait);

    await _insertToEnterpriseEvaluation(internship);
  }

  @override
  Future<void> _putInternship({
    required Internship internship,
    required Internship? previous,
    required DatabaseUser user,
  }) async {
    try {
      await sqlInterface.beginTransaction();

      if (previous == null) {
        await _insertToInternships(internship);
      } else {
        await _updateToInternships(internship, previous);
      }

      // Insert simultaneously elements
      final toWait = <Future>[];
      if (previous == null) {
        toWait.add(_insertToSupervisingTeachers(internship));
        toWait.add(_insertToContracts(internship, user: user));
        toWait.add(_insertToSkillEvaluations(internship));
        toWait.add(_insertToAttitudeEvaluations(internship));
        toWait.add(_insertToEnterpriseEvaluation(internship));
        toWait.add(_insertJobSstEvaluation(internship));
      } else {
        toWait.add(_updateToSupervisingTeachers(internship, previous));
        toWait.add(_updateToContracts(internship, previous, user));
        toWait.add(_updateToSkillEvaluations(internship, previous));
        toWait.add(_updateToAttitudeEvaluations(internship, previous));
        toWait.add(_updateToEnterpriseEvaluation(internship, previous));
        toWait.add(_updateJobSstEvaluation(internship, previous));
      }
      await Future.wait(toWait);

      await sqlInterface.commitTransaction();
    } catch (e) {
      await sqlInterface.rollbackTransaction();
      rethrow;
    }
  }

  @override
  Future<String?> _deleteInternship({
    required String id,
    required DatabaseUser user,
  }) async {
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

class InternshipsRepositoryMock extends InternshipsRepository {
  // Simulate a database with a map
  final _dummyDatabase = {
    '0': Internship(
      id: '0',
      studentId: '12345',
      signatoryTeacherId: '67890',
      extraSupervisingTeacherIds: [],
      enterpriseId: '12345',
      achievedDuration: -1,
      endDate: DateTime(0),
      contracts: [
        InternshipContract(
          date: DateTime(2000, 1, 1),
          specializationId: '67890',
          jobId: 'abcdefghij',
          extraSpecializationIds: ['12345'],
          program: Program.fpt,
          dates: DateTimeRange(
              start: DateTime(2011, 1, 1), end: DateTime(2011, 1, 31)),
          supervisor: Person(
              firstName: 'Mine',
              lastName: 'Yours',
              dateBirth: null,
              address: Address.empty,
              phone: PhoneNumber.empty,
              email: ''),
          weeklySchedules: [
            WeeklySchedule(
                dayCycle: DayCycle.weekdaysCycle,
                schedule: {
                  0: DailySchedule(blocks: [
                    TimeBlock(
                        start: TimeOfDay(hour: 8, minute: 0),
                        end: TimeOfDay(hour: 12, minute: 0)),
                    TimeBlock(
                        start: TimeOfDay(hour: 13, minute: 0),
                        end: TimeOfDay(hour: 16, minute: 0))
                  ]),
                  2: DailySchedule(blocks: [
                    TimeBlock(
                        start: TimeOfDay(hour: 8, minute: 0),
                        end: TimeOfDay(hour: 12, minute: 0)),
                    TimeBlock(
                        start: TimeOfDay(hour: 13, minute: 0),
                        end: TimeOfDay(hour: 16, minute: 0))
                  ]),
                  4: DailySchedule(blocks: [
                    TimeBlock(
                        start: TimeOfDay(hour: 8, minute: 0),
                        end: TimeOfDay(hour: 12, minute: 0)),
                    TimeBlock(
                        start: TimeOfDay(hour: 13, minute: 0),
                        end: TimeOfDay(hour: 16, minute: 0))
                  ]),
                },
                period: DateTimeRange(
                    start: DateTime(2011, 1, 1), end: DateTime(2011, 1, 31)))
          ],
          transportations:
              [Transportation.walk].map((e) => e.toString()).toList(),
          visitFrequencies: 'Toutes les semaines',
          expectedDuration: 30,
          formVersion: InternshipContract.currentVersion,
        )
      ],
      skillEvaluations: [],
      attitudeEvaluations: [],
      sstEvaluations: [],
      enterpriseEvaluations: [],
      teacherNotes: 'Nope',
    ),
    '1': Internship(
      id: '1',
      studentId: '54321',
      signatoryTeacherId: '09876',
      extraSupervisingTeacherIds: ['54321'],
      enterpriseId: '54321',
      achievedDuration: -1,
      endDate: DateTime(0),
      contracts: [
        InternshipContract(
          date: DateTime(2000, 2, 1),
          jobId: 'jihgfedcba',
          specializationId: '09876',
          extraSpecializationIds: ['54321', '09876'],
          program: Program.fpt,
          dates: DateTimeRange(
              start: DateTime(2011, 2, 1), end: DateTime(2011, 2, 28)),
          supervisor: Person(
              firstName: 'Mine',
              lastName: 'Yours',
              dateBirth: null,
              address: Address.empty,
              phone: PhoneNumber.empty,
              email: ''),
          weeklySchedules: [
            WeeklySchedule(
                dayCycle: DayCycle.weekdaysCycle,
                schedule: {
                  1: DailySchedule(
                    blocks: [
                      TimeBlock(
                          start: TimeOfDay(hour: 9, minute: 0),
                          end: TimeOfDay(hour: 12, minute: 0)),
                      TimeBlock(
                          start: TimeOfDay(hour: 13, minute: 0),
                          end: TimeOfDay(hour: 17, minute: 0))
                    ],
                  ),
                  3: DailySchedule(blocks: [
                    TimeBlock(
                        start: TimeOfDay(hour: 9, minute: 0),
                        end: TimeOfDay(hour: 12, minute: 0)),
                    TimeBlock(
                        start: TimeOfDay(hour: 13, minute: 0),
                        end: TimeOfDay(hour: 17, minute: 0))
                  ]),
                },
                period: DateTimeRange(
                    start: DateTime(2011, 2, 1), end: DateTime(2011, 2, 28)))
          ],
          transportations: [Transportation.walk, Transportation.publicTransport]
              .map((e) => e.toString())
              .toList(),
          visitFrequencies: 'Toutes les deux semaines',
          expectedDuration: 20,
          formVersion: InternshipContract.currentVersion,
        ),
      ],
      skillEvaluations: [],
      attitudeEvaluations: [],
      sstEvaluations: [],
      enterpriseEvaluations: [],
      teacherNotes: 'Yes',
    ),
  };

  @override
  Future<Map<String, Internship>> _getAllInternships({
    required DatabaseUser user,
    List<String>? students,
  }) async =>
      _dummyDatabase;

  @override
  Future<Internship?> _getInternshipById({
    required String id,
    required DatabaseUser user,
  }) async =>
      _dummyDatabase[id];

  @override
  Future<void> _putInternship({
    required Internship internship,
    required Internship? previous,
    required DatabaseUser user,
  }) async =>
      _dummyDatabase[internship.id] = internship;

  @override
  Future<String?> _deleteInternship({
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
