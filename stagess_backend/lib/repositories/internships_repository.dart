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
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/time_utils.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/utils.dart';

// AccessLevel in this repository is discarded as all operations are currently
// available to all users

abstract class InternshipsRepository extends RepositoryAbstract {
  @override
  Future<RepositoryResponse> getAll({
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    if (user.isNotVerified) {
      throw InvalidRequestException(
          'You do not have permission to get internships');
    }

    final internships = await _getAllInternships(user: user);

    // Filter internships based on user access level (this should already be done, but just in case)
    internships.removeWhere((key, value) =>
        user.accessLevel <= AccessLevel.admin &&
        value.schoolBoardId != user.schoolBoardId);

    return RepositoryResponse(
        data: internships.map(
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
          'You do not have permission to get internships');
    }

    final internship = await _getInternshipById(id: id, user: user);
    if (internship == null) throw MissingDataException('Internship not found');

    // Prevent from getting an enterprise that the user does not have access to (this should already be done, but just in case)
    if (user.accessLevel <= AccessLevel.admin &&
        internship.schoolBoardId != user.schoolBoardId) {
      throw MissingDataException('Internship not found');
    }

    return RepositoryResponse(data: internship.serializeWithFields(fields));
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
          'You do not have permission to put internships');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock ||
          (await requestLock(user: user, id: id)).data?['locked'] != true) {
        throw InvalidRequestException(
            'You must acquire a lock before editing this internship');
      }
      final response = await putById(
          id: id, data: data, user: user, tryRequestingLock: false);
      await releaseLock(user: user, id: id);
      return response;
    }

    // Update if exists, insert if not
    final previous = await _getInternshipById(id: id, user: user);
    final newInternship = previous?.copyWithData(data) ??
        Internship.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    if (user.accessLevel <= AccessLevel.admin &&
        newInternship.schoolBoardId != user.schoolBoardId) {
      throw InvalidRequestException(
          'You do not have permission to put this internship');
    }

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
    bool tryRequestingLock = true,
  }) async {
    if (user.isNotVerified || user.accessLevel < AccessLevel.admin) {
      throw InvalidRequestException(
          'You do not have permission to delete internships');
    }

    if (user.accessLevel <= AccessLevel.admin &&
        (await _getInternshipById(id: id, user: user))?.schoolBoardId !=
            user.schoolBoardId) {
      throw InvalidRequestException(
          'You do not have permission to delete this internship');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock ||
          (await requestLock(user: user, id: id)).data?['locked'] != true) {
        throw InvalidRequestException(
            'You must acquire a lock before deleting this internship');
      }
      final response =
          await deleteById(id: id, user: user, tryRequestingLock: false);
      await releaseLock(user: user, id: id);
      return response;
    }

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
  }) async {
    final internships = await sqlInterface.performSelectQuery(
        user: user,
        tableName: 'internships',
        filters: (internshipId == null ? {} : {'id': internshipId})
          ..addAll(user.accessLevel == AccessLevel.superAdmin
              ? {}
              : {'school_board_id': user.schoolBoardId ?? ''}),
        subqueries: [
          sqlInterface.selectSubquery(
            dataTableName: 'internship_supervising_teachers',
            asName: 'supervising_teachers',
            fieldsToFetch: ['teacher_id', 'is_signatory_teacher'],
            idNameToDataTable: 'internship_id',
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'internship_extra_specializations',
            asName: 'extra_specializations',
            fieldsToFetch: ['specialization_id'],
            idNameToDataTable: 'internship_id',
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'internship_mutable_data',
            asName: 'mutables',
            fieldsToFetch: [
              'id',
              'creation_date',
              'supervisor_id',
              'starting_date',
              'ending_date',
              'visit_frequencies',
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
            fieldsToFetch: ['id', 'date', 'comments', 'form_version'],
            idNameToDataTable: 'internship_id',
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'internship_visa_evaluations',
            asName: 'visa_evaluations',
            fieldsToFetch: ['id', 'date', 'form_version'],
            idNameToDataTable: 'internship_id',
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'post_internship_enterprise_evaluations',
            asName: 'enterprise_evaluation',
            fieldsToFetch: [
              'id',
              'date',
              'internship_id',
              'task_variety',
              'training_plan_respect',
              'autonomy_expected',
              'efficiency_expected',
              'supervision_style',
              'ease_of_communication',
              'absence_acceptance',
              'supervision_comments',
              'acceptance_tsa',
              'acceptance_language_disorder',
              'acceptance_intellectual_disability',
              'acceptance_physical_disability',
              'acceptance_mental_health_disorder',
              'acceptance_behavior_difficulties'
            ],
            idNameToDataTable: 'internship_id',
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'internship_sst_evaluation_info',
            asName: 'sst_evaluation_info',
            idNameToDataTable: 'internship_id',
            fieldsToFetch: ['internship_id', 'date'],
          ),
          sqlInterface.selectSubquery(
            dataTableName: 'internship_sst_evaluation_persons',
            asName: 'sst_evaluation_persons_present',
            idNameToDataTable: 'internship_id',
            fieldsToFetch: ['person_name'],
          ),
          sqlInterface.selectSubquery(
              dataTableName: 'internship_sst_evaluation_questions',
              asName: 'sst_evaluation_questions',
              idNameToDataTable: 'internship_id',
              fieldsToFetch: ['question', 'answers']),
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

      internship['extra_specialization_ids'] =
          (internship['extra_specializations'] as List?)
                  ?.map((e) => e['specialization_id'].toString())
                  .toList() ??
              [];

      for (final mutable in (internship['mutables'] as List? ?? [])) {
        mutable['supervisor'] = (await sqlInterface.performSelectQuery(
                    user: user,
                    tableName: 'persons',
                    filters: {
                  'id': mutable['supervisor_id']
                },
                    subqueries: [
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
                ]) as List?)
                ?.first ??
            {};
        mutable['supervisor']['phone'] =
            (mutable['supervisor']['phone_numbers'] as List?)?.firstOrNull;
        mutable['supervisor']['address'] =
            (mutable['supervisor']['addresses'] as List?)?.firstOrNull;

        final schedules = await sqlInterface.performSelectQuery(
            user: user,
            tableName: 'internship_weekly_schedules',
            filters: {
              'mutable_data_id': mutable['id']
            },
            subqueries: [
              sqlInterface.selectSubquery(
                dataTableName: 'internship_daily_schedules',
                asName: 'daily_schedules',
                fieldsToFetch: [
                  'id',
                  'day',
                  'block_index',
                  'starting_hour',
                  'starting_minute',
                  'ending_hour',
                  'ending_minute',
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
            filters: {'id': mutable['id']});
        mutable['transportations'] = (transportations as List? ?? [])
            .map((e) => e['transportation'])
            .toList();

        mutable['schedules'] = schedules;
      }

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
                  'job_id',
                  'skill_name',
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
            'job_id': skill['job_id'],
            'skill': skill['skill_name'],
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
              'id': evaluation['id']
            },
                subqueries: [
              sqlInterface.selectSubquery(
                dataTableName: 'internship_attitude_evaluation_persons',
                asName: 'present',
                fieldsToFetch: ['person_name'],
                idNameToDataTable: 'evaluation_id',
              ),
              sqlInterface.selectSubquery(
                dataTableName: 'internship_attitude_evaluation_items',
                asName: 'attitude',
                fieldsToFetch: [
                  'id',
                  'evaluation_id',
                  'inattendance',
                  'ponctuality',
                  'sociability',
                  'politeness',
                  'motivation',
                  'dressCode',
                  'quality_of_work',
                  'productivity',
                  'autonomy',
                  'cautiousness',
                  'general_appreciation',
                ],
                idNameToDataTable: 'evaluation_id',
              ),
            ]))
            .first;

        evaluation['attitude'] = (evaluationSubquery['attitude'] as List).first;
        evaluation['present'] = [
          for (final person in (evaluationSubquery['present'] as List? ?? []))
            person['person_name']
        ];
        attitudeEvaluations.add(evaluation);
      }
      internship['attitude_evaluations'] = attitudeEvaluations;

      final visaEvaluations = [];
      for (final Map<String, dynamic> evaluation
          in (internship['visa_evaluations'] as List? ?? [])) {
        final evaluationSubquery = (await sqlInterface.performSelectQuery(
                user: user,
                tableName: 'internship_visa_evaluations',
                filters: {
              'id': evaluation['id']
            },
                subqueries: [
              sqlInterface.selectSubquery(
                dataTableName: 'internship_visa_evaluation_items',
                asName: 'visa',
                fieldsToFetch: [
                  'id',
                  'evaluation_id',
                  'inattendance',
                  'ponctuality',
                  'sociability',
                  'politeness',
                  'motivation',
                  'dressCode',
                  'quality_of_work',
                  'productivity',
                  'autonomy',
                  'cautiousness',
                  'general_appreciation',
                ],
                idNameToDataTable: 'evaluation_id',
              ),
            ]))
            .first;

        evaluation['attitude'] = (evaluationSubquery['visa'] as List).first;
        visaEvaluations.add(evaluation);
      }
      internship['visa_evaluations'] = visaEvaluations;

      final sstEvaluationInfo =
          internship['sst_evaluation_info'] as List? ?? [];
      final sstEvaluationPersonsPresent =
          internship['sst_evaluation_persons_present'] as List? ?? [];
      final sstEvaluationQuestions =
          internship['sst_evaluation_questions'] as List? ?? [];
      if (sstEvaluationInfo.length != 1) {
        internship['sst_evaluation'] = null;
      } else {
        internship['sst_evaluation'] = {
          'id': sstEvaluationInfo.first['internship_id'],
          'date': sstEvaluationInfo.first['date'] ?? 0,
          'present_at_evaluation': [
            for (final person in sstEvaluationPersonsPresent)
              person['person_name']
          ],
          'questions': {
            for (final Map question in sstEvaluationQuestions)
              question['question']:
                  (question['answers'] as String?)?.split('\n') ?? []
          }
        };
      }

      internship['enterprise_evaluation'] =
          (internship['enterprise_evaluation'] as List?)?.firstOrNull;
      if (internship['enterprise_evaluation'] != null) {
        final skills = await sqlInterface.performSelectQuery(
            user: user,
            tableName: 'post_internship_enterprise_evaluation_skills',
            filters: {
              'post_evaluation_id': internship['enterprise_evaluation']['id']
            });
        internship['enterprise_evaluation']['skills_required'] = [
          for (final skill in (skills as List? ?? [])) skill['skill_name']
        ];
      }

      map[id] = Internship.fromSerialized(internship);
    }
    return map;
  }

  @override
  Future<Internship?> _getInternshipById({
    required String id,
    required DatabaseUser user,
  }) async =>
      (await _getAllInternships(internshipId: id, user: user))[id];

  Future<void> _insertToInternships(Internship internship) async {
    // Insert the internship
    await sqlInterface.performInsertQuery(
        tableName: 'entities', data: {'shared_id': internship.id});
    await sqlInterface.performInsertQuery(tableName: 'internships', data: {
      'id': internship.id,
      'school_board_id': internship.schoolBoardId.serialize(),
      'student_id': internship.studentId.serialize(),
      'enterprise_id': internship.enterpriseId.serialize(),
      'job_id': internship.jobId.serialize(),
      'expected_duration': internship.expectedDuration.serialize(),
      'achieved_duration': internship.achievedDuration.serialize(),
      'teacher_notes': internship.teacherNotes.serialize(),
      'end_date': internship.endDate.serialize(),
    });
  }

  Future<void> _updateToInternships(
      Internship internship, Internship previous) async {
    // Update the internship
    final differences = internship.getDifference(previous);
    if (differences.contains('school_board_id')) {
      throw InvalidRequestException('School board id cannot be changed');
    }
    if (differences.contains('student_id')) {
      throw InvalidRequestException('Student id cannot be changed');
    }
    if (differences.contains('enterprise_id')) {
      throw InvalidRequestException('Enterprise id cannot be changed');
    }
    if (differences.contains('job_id')) {
      throw InvalidRequestException('Job id cannot be changed');
    }

    final toUpdate = <String, dynamic>{};
    if (differences.contains('expected_duration')) {
      toUpdate['expected_duration'] = internship.expectedDuration.serialize();
    }
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

  Future<void> _insertExtraSpecializations(Internship internship) async {
    for (final specializationId in internship.extraSpecializationIds) {
      await sqlInterface.performInsertQuery(
          tableName: 'internship_extra_specializations',
          data: {
            'internship_id': internship.id,
            'specialization_id': specializationId
          });
    }
  }

  Future<void> _updateToExtraSpecializations(
      Internship internship, Internship previous) async {
    final toUpdate = internship.getDifference(previous);
    if (toUpdate.contains('extra_specialization_ids')) {
      // This is a bit tricky to simply update, so we delete and reinsert
      await sqlInterface.performDeleteQuery(
          tableName: 'internship_extra_specializations',
          filters: {'internship_id': internship.id});

      await _insertExtraSpecializations(internship);
    }
  }

  Future<void> _insertToMutables(Internship internship,
      {Internship? previous, required DatabaseUser user}) async {
    final previousSerialized = previous?.serializedMutables ?? [];
    bool supervisorIsUpdated = false;
    for (final mutable in internship.serializedMutables) {
      if (previousSerialized.any((e) => e['id'] == mutable['id'])) {
        // Skip if the mutable already exists
        continue;
      }
      if (!supervisorIsUpdated) {
        final previousSupervisor = (await sqlInterface.performSelectQuery(
                    user: user,
                    tableName: 'persons',
                    filters: {
                  'id': mutable['supervisor']['id']
                },
                    subqueries: [
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
                ]) as List?)
                ?.firstOrNull as Map<String, dynamic>? ??
            {};
        if (previousSupervisor.isNotEmpty) {
          previousSupervisor['phone'] =
              (previousSupervisor['phone_numbers'] as List?)?[0] ?? [];
          previousSupervisor['address'] =
              (previousSupervisor['addresses'] as List?)?[0] ?? [];
        }

        if (previousSupervisor.isEmpty) {
          await sqlInterface.performInsertPerson(person: internship.supervisor);
        } else {
          // Update the person (without the phone numbers and addresses of previous as they were removed)
          await sqlInterface.performUpdatePerson(
              person: internship.supervisor,
              previous: Person.fromSerialized(previousSupervisor));
        }
        supervisorIsUpdated = true;
      }

      await sqlInterface
          .performInsertQuery(tableName: 'internship_mutable_data', data: {
        'id': mutable['id'],
        'internship_id': internship.id,
        'creation_date': mutable['creation_date'],
        'supervisor_id': internship.supervisor.id,
        'starting_date': mutable['starting_date'],
        'ending_date': mutable['ending_date'],
        'visit_frequencies': mutable['visit_frequencies'],
      });

      // Insert the weekly schedules
      for (final schedule in mutable['schedules'] as List) {
        await sqlInterface.performInsertQuery(
            tableName: 'internship_weekly_schedules',
            data: {
              'id': schedule['id'],
              'mutable_data_id': mutable['id'],
              'starting_date': schedule['start'],
              'ending_date': schedule['end'],
            });

        // Insert the daily schedules
        for (final pair in (schedule['days'] as Map? ?? {}).entries) {
          final day = int.parse(pair.key);
          final entry = pair.value;
          for (int blockIndex = 0;
              blockIndex < (entry['blocks'] as List).length;
              blockIndex++) {
            await sqlInterface.performInsertQuery(
                tableName: 'internship_daily_schedules',
                data: {
                  'id': entry['id'],
                  'weekly_schedule_id': schedule['id'],
                  'day': day,
                  'block_index': blockIndex,
                  'starting_hour': entry['blocks'][blockIndex]['start'][0],
                  'starting_minute': entry['blocks'][blockIndex]['start'][1],
                  'ending_hour': entry['blocks'][blockIndex]['end'][0],
                  'ending_minute': entry['blocks'][blockIndex]['end'][1],
                });
          }
        }
      }

      // Insert the transportations
      for (final transportation in mutable['transportations'] as List) {
        await sqlInterface.performInsertQuery(
            tableName: 'internship_transportations',
            data: {'id': mutable['id'], 'transportation': transportation});
      }
    }
  }

  Future<void> _updateToMutables(
      Internship internship, Internship previous, DatabaseUser user) async {
    // We don't update the mutable data, but stack them
    await _insertToMutables(internship, previous: previous, user: user);
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
              'job_id': skill['job_id'],
              'skill_name': skill['skill'],
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
            'comments': evaluation['comments'],
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

      // Insert the attitude
      await sqlInterface.performInsertQuery(
          tableName: 'internship_attitude_evaluation_items',
          data: {
            'id': evaluation['attitude']['id'],
            'evaluation_id': evaluation['id'],
            'inattendance': evaluation['attitude']['inattendance'],
            'ponctuality': evaluation['attitude']['ponctuality'],
            'sociability': evaluation['attitude']['sociability'],
            'politeness': evaluation['attitude']['politeness'],
            'motivation': evaluation['attitude']['motivation'],
            'dressCode': evaluation['attitude']['dressCode'],
            'quality_of_work': evaluation['attitude']['quality_of_work'],
            'productivity': evaluation['attitude']['productivity'],
            'autonomy': evaluation['attitude']['autonomy'],
            'cautiousness': evaluation['attitude']['cautiousness'],
            'general_appreciation': evaluation['attitude']
                ['general_appreciation']
          });
    }
  }

  Future<void> _updateToAttitudeEvaluations(
      Internship internship, Internship previous) async {
    // Attitude evaluations are not updated, but stacked
    _insertToAttitudeEvaluations(internship, previous);
  }

  Future<void> _insertToVisaEvaluations(Internship internship,
      [Internship? previous]) async {
    for (final evaluation in internship.visaEvaluations.serialize()) {
      if (previous?.visaEvaluations.any((e) => e.id == evaluation['id']) ??
          false) {
        // Skip if the evaluation already exists
        continue;
      }

      await sqlInterface
          .performInsertQuery(tableName: 'internship_visa_evaluations', data: {
        'id': evaluation['id'],
        'internship_id': internship.id,
        'date': evaluation['date'],
        'form_version': evaluation['form_version'],
      });

      // Insert the attitude
      await sqlInterface.performInsertQuery(
          tableName: 'internship_visa_evaluation_items',
          data: {
            'id': evaluation['attitude']['id'],
            'evaluation_id': evaluation['id'],
            'inattendance': evaluation['attitude']['inattendance'],
            'ponctuality': evaluation['attitude']['ponctuality'],
            'sociability': evaluation['attitude']['sociability'],
            'politeness': evaluation['attitude']['politeness'],
            'motivation': evaluation['attitude']['motivation'],
            'dressCode': evaluation['attitude']['dressCode'],
            'quality_of_work': evaluation['attitude']['quality_of_work'],
            'productivity': evaluation['attitude']['productivity'],
            'autonomy': evaluation['attitude']['autonomy'],
            'cautiousness': evaluation['attitude']['cautiousness'],
            'general_appreciation': evaluation['attitude']
                ['general_appreciation']
          });
    }
  }

  Future<void> _updateToVisaEvaluations(
      Internship internship, Internship previous) async {
    // Attitude evaluations are not updated, but stacked
    _insertToVisaEvaluations(internship, previous);
  }

  Future<void> _insertJobSstEvaluation(Internship internship) async {
    final serialized = internship.sstEvaluation?.serialize();
    if (serialized == null) return;

    final toWait = <Future>[];

    toWait.add(sqlInterface
        .performInsertQuery(tableName: 'internship_sst_evaluation_info', data: {
      'internship_id': internship.id,
      'date': serialized['date'],
    }));

    for (final person in (serialized['present_at_evaluation'] as List? ?? [])) {
      toWait.add(sqlInterface.performInsertQuery(
          tableName: 'internship_sst_evaluation_persons',
          data: {'internship_id': internship.id, 'person_name': person}));
    }

    final questions = serialized['questions'] as Map?;
    for (final question in (questions?.keys.toList() ?? [])) {
      toWait.add(sqlInterface.performInsertQuery(
          tableName: 'internship_sst_evaluation_questions',
          data: {
            'internship_id': internship.id,
            'question': question,
            'answers': (questions![question] as List?)?.join('\n'),
          }));
    }

    await Future.wait(toWait);
  }

  Future<void> _updateJobSstEvaluation(
      Internship internship, Internship previous) async {
    final differences = internship.getDifference(previous);
    if (!differences.contains('sst_evaluation')) return;

    // It would be possible to update properly the sst evaluation, but
    // it is not so important, so we use the trick of deleting and reinserting.
    final toWait = <Future>[];
    toWait.add(sqlInterface.performDeleteQuery(
        tableName: 'internship_sst_evaluation_info',
        filters: {'internship_id': internship.id}));
    toWait.add(sqlInterface.performDeleteQuery(
        tableName: 'internship_sst_evaluation_persons',
        filters: {'internship_id': internship.id}));
    toWait.add(sqlInterface.performDeleteQuery(
        tableName: 'internship_sst_evaluation_questions',
        filters: {'internship_id': internship.id}));
    await Future.wait(toWait);

    await _insertJobSstEvaluation(internship);
  }

  Future<void> _insertToEnterpriseEvaluation(Internship internship) async {
    if (internship.enterpriseEvaluation != null) {
      final evaluation = internship.enterpriseEvaluation!.serialize();
      await sqlInterface.performInsertQuery(
          tableName: 'post_internship_enterprise_evaluations',
          data: {
            'id': evaluation['id'],
            'date': evaluation['date'],
            'internship_id': internship.id,
            'task_variety': evaluation['task_variety'],
            'training_plan_respect': evaluation['training_plan_respect'],
            'autonomy_expected': evaluation['autonomy_expected'],
            'efficiency_expected': evaluation['efficiency_expected'],
            'supervision_style': evaluation['supervision_style'],
            'ease_of_communication': evaluation['ease_of_communication'],
            'absence_acceptance': evaluation['absence_acceptance'],
            'supervision_comments': evaluation['supervision_comments'],
            'acceptance_tsa': evaluation['acceptance_tsa'],
            'acceptance_language_disorder':
                evaluation['acceptance_language_disorder'],
            'acceptance_intellectual_disability':
                evaluation['acceptance_intellectual_disability'],
            'acceptance_physical_disability':
                evaluation['acceptance_physical_disability'],
            'acceptance_mental_health_disorder':
                evaluation['acceptance_mental_health_disorder'],
            'acceptance_behavior_difficulties':
                evaluation['acceptance_behavior_difficulties'],
          });

      for (final skill in evaluation['skills_required'] as List) {
        await sqlInterface.performInsertQuery(
            tableName: 'post_internship_enterprise_evaluation_skills',
            data: {
              'post_evaluation_id': evaluation['id'],
              'skill_name': skill
            });
      }
    }
  }

  Future<void> _updateToEnterpriseEvaluation(
      Internship internship, Internship previous) async {
    final toUpdate = internship.getDifference(previous);
    if (toUpdate.contains('enterprise_evaluation')) {
      // First remove the previous evaluation
      await sqlInterface.performDeleteQuery(
          tableName: 'post_internship_enterprise_evaluations',
          filters: {'internship_id': internship.id});
      await sqlInterface.performDeleteQuery(
          tableName: 'post_internship_enterprise_evaluation_skills',
          filters: {'post_evaluation_id': previous.enterpriseEvaluation!.id});

      await _insertToEnterpriseEvaluation(internship);
    }
  }

  @override
  Future<void> _putInternship({
    required Internship internship,
    required Internship? previous,
    required DatabaseUser user,
  }) async {
    if (previous == null) {
      await _insertToInternships(internship);
    } else {
      await _updateToInternships(internship, previous);
    }

    // Insert simultaneously elements
    final toWait = <Future>[];
    if (previous == null) {
      toWait.add(_insertToSupervisingTeachers(internship));
      toWait.add(_insertExtraSpecializations(internship));
      toWait.add(_insertToMutables(internship, user: user));
      toWait.add(_insertToSkillEvaluations(internship));
      toWait.add(_insertToAttitudeEvaluations(internship));
      toWait.add(_insertToVisaEvaluations(internship));
      toWait.add(_insertToEnterpriseEvaluation(internship));
      toWait.add(_insertJobSstEvaluation(internship));
    } else {
      toWait.add(_updateToSupervisingTeachers(internship, previous));
      toWait.add(_updateToExtraSpecializations(internship, previous));
      toWait.add(_updateToMutables(internship, previous, user));
      toWait.add(_updateToSkillEvaluations(internship, previous));
      toWait.add(_updateToAttitudeEvaluations(internship, previous));
      toWait.add(_updateToVisaEvaluations(internship, previous));
      toWait.add(_updateToEnterpriseEvaluation(internship, previous));
      toWait.add(_updateJobSstEvaluation(internship, previous));
    }
    await Future.wait(toWait);
  }

  @override
  Future<String?> _deleteInternship({
    required String id,
    required DatabaseUser user,
  }) async {
    try {
      final mutable = (await sqlInterface.performSelectQuery(
        user: user,
        tableName: 'internship_mutable_data',
        filters: {'internship_id': id},
      ))
          .lastOrNull;

      await sqlInterface.performDeleteQuery(
        tableName: 'entities',
        filters: {'shared_id': id},
      );
      if (mutable != null) {
        await sqlInterface.performDeleteQuery(
          tableName: 'entities',
          filters: {'shared_id': mutable['supervisor_id']},
        );
      }

      return id;
    } catch (e) {
      return null;
    }
  }
}

class InternshipsRepositoryMock extends InternshipsRepository {
  // Simulate a database with a map
  final _dummyDatabase = {
    '0': Internship(
      id: '0',
      schoolBoardId: '0',
      studentId: '12345',
      signatoryTeacherId: '67890',
      extraSupervisingTeacherIds: [],
      enterpriseId: '12345',
      jobId: '67890',
      extraSpecializationIds: ['12345'],
      dates: DateTimeRange(
          start: DateTime(1990, 1, 1), end: DateTime(1990, 1, 31)),
      supervisor: Person(
          firstName: 'Mine',
          middleName: null,
          lastName: 'Yours',
          dateBirth: null,
          address: Address.empty,
          phone: PhoneNumber.empty,
          email: null),
      creationDate: DateTime(2000, 1, 1),
      weeklySchedules: [
        WeeklySchedule(
            schedule: {
              Day.monday: DailySchedule(blocks: [
                TimeBlock(
                    start: TimeOfDay(hour: 8, minute: 0),
                    end: TimeOfDay(hour: 12, minute: 0)),
                TimeBlock(
                    start: TimeOfDay(hour: 13, minute: 0),
                    end: TimeOfDay(hour: 16, minute: 0))
              ]),
              Day.wednesday: DailySchedule(blocks: [
                TimeBlock(
                    start: TimeOfDay(hour: 8, minute: 0),
                    end: TimeOfDay(hour: 12, minute: 0)),
                TimeBlock(
                    start: TimeOfDay(hour: 13, minute: 0),
                    end: TimeOfDay(hour: 16, minute: 0))
              ]),
              Day.friday: DailySchedule(blocks: [
                TimeBlock(
                    start: TimeOfDay(hour: 8, minute: 0),
                    end: TimeOfDay(hour: 12, minute: 0)),
                TimeBlock(
                    start: TimeOfDay(hour: 13, minute: 0),
                    end: TimeOfDay(hour: 16, minute: 0))
              ]),
            },
            period: DateTimeRange(
                start: DateTime(1990, 1, 1), end: DateTime(1990, 1, 31)))
      ],
      expectedDuration: 30,
      achievedDuration: -1,
      endDate: DateTime(0),
      teacherNotes: 'Nope',
      transportations: [Transportation.pass],
      visitFrequencies: 'Toutes les semaines',
    ),
    '1': Internship(
      id: '1',
      schoolBoardId: '0',
      studentId: '54321',
      signatoryTeacherId: '09876',
      extraSupervisingTeacherIds: ['54321'],
      enterpriseId: '54321',
      jobId: '09876',
      extraSpecializationIds: ['54321', '09876'],
      dates: DateTimeRange(
          start: DateTime(1990, 2, 1), end: DateTime(1990, 2, 28)),
      supervisor: Person(
          firstName: 'Mine',
          middleName: null,
          lastName: 'Yours',
          dateBirth: null,
          address: Address.empty,
          phone: PhoneNumber.empty,
          email: null),
      creationDate: DateTime(2000, 2, 1),
      weeklySchedules: [
        WeeklySchedule(
            schedule: {
              Day.tuesday: DailySchedule(
                blocks: [
                  TimeBlock(
                      start: TimeOfDay(hour: 9, minute: 0),
                      end: TimeOfDay(hour: 12, minute: 0)),
                  TimeBlock(
                      start: TimeOfDay(hour: 13, minute: 0),
                      end: TimeOfDay(hour: 17, minute: 0))
                ],
              ),
              Day.thursday: DailySchedule(blocks: [
                TimeBlock(
                    start: TimeOfDay(hour: 9, minute: 0),
                    end: TimeOfDay(hour: 12, minute: 0)),
                TimeBlock(
                    start: TimeOfDay(hour: 13, minute: 0),
                    end: TimeOfDay(hour: 17, minute: 0))
              ]),
            },
            period: DateTimeRange(
                start: DateTime(1990, 2, 1), end: DateTime(1990, 2, 28)))
      ],
      expectedDuration: 20,
      achievedDuration: -1,
      endDate: DateTime(0),
      teacherNotes: 'Yes',
      transportations: [Transportation.yes, Transportation.ticket],
      visitFrequencies: 'Toutes les deux semaines',
    ),
  };

  @override
  Future<Map<String, Internship>> _getAllInternships({
    required DatabaseUser user,
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
