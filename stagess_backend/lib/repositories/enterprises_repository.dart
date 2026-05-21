import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:stagess_backend/repositories/internships_repository.dart';
import 'package:stagess_backend/repositories/repository_abstract.dart';
import 'package:stagess_backend/repositories/sql_interfaces.dart';
import 'package:stagess_backend/repositories/students_repository.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_backend/utils/security_policies.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/enterprises/job_comment.dart';
import 'package:stagess_common/models/enterprises/job_list.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/photo.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/services/image_helpers.dart';
import 'package:stagess_common/utils.dart';

final _logger = Logger('EnterprisesRepository');

// AccessLevel in this repository is discarded as all operations are currently
// available to all users

abstract class EnterprisesRepository extends RepositoryAbstract {
  @override
  Future<RepositoryResponse> getAll({
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    final enterprises = await _getAllEnterprises(user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      ...enterprises.values
          .map((e) => UserIsFromSameSchoolBoard(user: user, item: e)),
    ]).validate();

    return RepositoryResponse(
        data: enterprises.map(
            (key, value) => MapEntry(key, value.serializeWithFields(fields))));
  }

  @override
  Future<RepositoryResponse> getById({
    required String id,
    required FetchableFields fields,
    required DatabaseUser user,
  }) async {
    final enterprise = await _getEnterpriseById(id: id, user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: enterprise),
      UserIsFromSameSchoolBoard(user: user, item: enterprise),
    ]).validate();

    return RepositoryResponse(data: enterprise!.serializeWithFields(fields));
  }

  @override
  Future<RepositoryResponse> putById({
    required String id,
    required Map<String, dynamic> data,
    required DatabaseUser user,
    InternshipsRepository? internshipsRepository,
    StudentsRepository? studentsRepository,
    bool tryRequestingLock = true,
  }) async {
    if (internshipsRepository == null) {
      throw InvalidRequestException(
          'Internships repository is required for this operation');
    }
    if (studentsRepository == null) {
      throw InvalidRequestException(
          'Students repository is required for this operation');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock) {
        throw InvalidRequestException(
            'You must acquire a lock before editing this enterprise');
      }
      return await requestLockAndPerformTask(
          id: id,
          user: user,
          task: () {
            return putById(
              id: id,
              data: data,
              user: user,
              internshipsRepository: internshipsRepository,
              tryRequestingLock: false,
            );
          });
    }

    // Update if exists, insert if not
    final previous = await _getEnterpriseById(id: id, user: user);
    final newEnterprise = previous?.copyWithData(data) ??
        Enterprise.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: newEnterprise),
      UserIsFromSameSchoolBoard(user: user, item: newEnterprise),
      ModificationsAreValid(
        user: user,
        item: newEnterprise,
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
        whiteList: {
          AccessLevel.teacher: [
            'name',
            'activity_types',
            'jobs',
            'contact',
            'contact_function',
            'address',
            'phone',
            'fax',
            'website',
            'headquarters_address',
            'neq',
          ],
        },
        blackList: {
          AccessLevel.schoolAdmin: ['id', 'school_board_id', 'school_id'],
          AccessLevel.schoolBoardAdmin: ['id', 'school_board_id', 'school_id'],
          AccessLevel.superAdmin: ['id', 'school_board_id', 'school_id'],
        },
        itemValidator: (user, item, previousItem) async {
          if (previousItem?.contact.id != null &&
              (item.contact.id != previousItem?.contact.id)) {
            throw InvalidRequestException(
                'Cannot update the contact id of an enterprise');
          }

          for (final job in item.jobs) {
            if (job.photos.length > 3) {
              throw InvalidRequestException(
                  'You cannot upload more than 3 photos per job');
            }

            final previousJob =
                previousItem?.jobs.firstWhereOrNull((e) => e.id == job.id);
            if (previousJob == null) continue; // Dealt with above

            final differences = job.getDifference(previousJob);
            if (differences.isEmpty) continue;

            if (differences.contains('id')) {
              throw InvalidRequestException('Cannot update the id of a job');
            }
            if (differences.contains('enterprise_id')) {
              throw InvalidRequestException(
                  'Cannot update the enterprise id of a job');
            }

            if (differences.contains('comments')) {
              // Make sure the user has the permission to update the comments
              // i.e. it is an admin or the teacher has supervised at least one internship in this enterprise
              if (user.accessLevel < AccessLevel.schoolAdmin) {
                final internships = (await internshipsRepository.getAll(
                  user: user,
                  fields: FetchableFields({
                    'enterprise_id': FetchableFields.mandatory,
                    'signatory_teacher_id': FetchableFields.mandatory,
                    'extra_supervising_teacher_ids': FetchableFields.mandatory,
                  }),
                  studentsRepository: studentsRepository,
                ));
                final teacherHasSupervizedInThisEnterprise = internships
                        .data?.values
                        .where((internship) =>
                            internship['enterprise_id'] == item.id &&
                            (internship['signatory_teacher_id'] ==
                                    user.userId ||
                                (internship['extra_supervising_teacher_ids']
                                        as List)
                                    .contains(user.userId)))
                        .isNotEmpty ??
                    false;
                if (!teacherHasSupervizedInThisEnterprise) {
                  throw InvalidRequestException(
                      'You do not have permission to update this enterprise');
                }
              }
            }
          }
        },
      ),
    ]).validate();

    // Put enterprise can remove internships if a job is removed
    await _putEnterprise(
        enterprise: newEnterprise,
        previous: previous,
        user: user,
        internshipsRepository: internshipsRepository,
        studentsRepository: studentsRepository);

    return RepositoryResponse(
      updatedData: {
        RequestFields.enterprise: {
          newEnterprise.id: Enterprise.fetchableFields
              .extractFrom(newEnterprise.getDifference(previous))
        },
      },
    );
  }

  @override
  Future<RepositoryResponse> deleteById({
    required String id,
    required DatabaseUser user,
    InternshipsRepository? internshipsRepository,
    StudentsRepository? studentsRepository,
    bool tryRequestingLock = true,
  }) async {
    if (internshipsRepository == null) {
      throw InvalidRequestException(
          'Internships repository is required for this operation');
    }
    if (studentsRepository == null) {
      throw InvalidRequestException(
          'Students repository is required for this operation');
    }

    if (!canEdit(user: user, id: id)) {
      if (!tryRequestingLock) {
        throw InvalidRequestException(
            'You must acquire a lock before deleting this enterprise');
      }
      return await requestLockAndPerformTask(
          id: id,
          user: user,
          task: () {
            return deleteById(
              id: id,
              user: user,
              internshipsRepository: internshipsRepository,
              tryRequestingLock: false,
            );
          });
    }

    final enterprise = await _getEnterpriseById(id: id, user: user);

    await SecurityPolicies([
      UserIsVerified(user: user),
      HasData(item: enterprise),
      HasMinimumAccessLevel(user: user, minimumLevel: AccessLevel.schoolAdmin),
      UserIsFromSameSchoolBoard(user: user, item: enterprise),
      GenericPolicy(validationFunction: () async {
        // Prevent from deleting an enterprise that has at least one internship
        if (user.accessLevel < AccessLevel.superAdmin) {
          final internships = (await internshipsRepository.getAll(
                user: user,
                fields: FetchableFields(
                    {'enterprise_id': FetchableFields.mandatory}),
                studentsRepository: studentsRepository,
              ))
                  .data ??
              {};
          if (internships.values
              .any((internship) => internship['enterprise_id'] == id)) {
            throw InvalidRequestException(
                'You cannot delete this enterprise because it has active internships');
          }
        }
      }),
    ]).validate();

    final response = await _deleteEnterprise(
        id: id,
        user: user,
        internshipsRepository: internshipsRepository,
        studentsRepository: studentsRepository);
    if (response.deletedData?[RequestFields.enterprise] == null) {
      throw DatabaseFailureException('Failed to delete enterprise with id $id');
    }

    return RepositoryResponse(deletedData: {
      RequestFields.enterprise:
          response.deletedData![RequestFields.enterprise]!,
    });
  }

  Future<Map<String, Enterprise>> _getAllEnterprises({
    required DatabaseUser user,
  });

  Future<Enterprise?> _getEnterpriseById({
    required String id,
    required DatabaseUser user,
  });

  Future<void> _putEnterprise({
    required Enterprise enterprise,
    required Enterprise? previous,
    required DatabaseUser user,
    required InternshipsRepository internshipsRepository,
    required StudentsRepository studentsRepository,
  });

  Future<RepositoryResponse> _deleteEnterprise({
    required String id,
    required DatabaseUser user,
    required InternshipsRepository internshipsRepository,
    required StudentsRepository studentsRepository,
  });
}

class MySqlEnterprisesRepository extends EnterprisesRepository {
  // coverage:ignore-start
  final SqlInterface sqlInterface;
  MySqlEnterprisesRepository({required this.sqlInterface});

  @override
  Future<Map<String, Enterprise>> _getAllEnterprises({
    String? enterpriseId,
    required DatabaseUser user,
  }) async {
    final schoolFilters = ({
      'school_board_id': user.accessLevel < AccessLevel.superAdmin
          ? user.schoolBoardId!
          : null,
    }..removeWhere((key, value) => value == null))
        .cast<String, String>();

    final enterprises = await sqlInterface.performSelectQuery(
      user: user,
      tableName: 'enterprises',
      filters: (enterpriseId == null ? {} : {'id': enterpriseId})
        ..addAll(schoolFilters),
      subqueries: [
        sqlInterface.joinSubquery(
            dataTableName: 'persons',
            asName: 'contact',
            idNameToDataTable: 'contact_id',
            idNameToMainTable: 'enterprise_id',
            relationTableName: 'enterprise_contacts',
            fieldsToFetch: ['id']),
        sqlInterface.joinSubquery(
            dataTableName: 'addresses',
            asName: 'address',
            idNameToDataTable: 'address_id',
            idNameToMainTable: 'enterprise_id',
            relationTableName: 'enterprise_addresses',
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
            dataTableName: 'addresses',
            asName: 'headquarters_address',
            idNameToDataTable: 'address_id',
            idNameToMainTable: 'enterprise_id',
            relationTableName: 'enterprise_headquarters_addresses',
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
            dataTableName: 'phone_numbers',
            asName: 'phone_number',
            idNameToDataTable: 'phone_number_id',
            idNameToMainTable: 'enterprise_id',
            relationTableName: 'enterprise_phone_numbers',
            fieldsToFetch: ['id', 'phone_number']),
        sqlInterface.joinSubquery(
            dataTableName: 'phone_numbers',
            asName: 'fax_number',
            idNameToDataTable: 'fax_number_id',
            idNameToMainTable: 'enterprise_id',
            relationTableName: 'enterprise_fax_numbers',
            fieldsToFetch: ['id', 'phone_number']),
        sqlInterface.selectSubquery(
            dataTableName: 'enterprise_activity_types',
            asName: 'activity_types',
            idNameToDataTable: 'enterprise_id',
            fieldsToFetch: ['activity_type']),
      ],
    );

    final map = <String, Enterprise>{};
    for (final enterprise in enterprises) {
      final contactId =
          (enterprise['contact'] as List?)?.map((e) => e['id']).firstOrNull;
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
      enterprise['contact'] = contacts?.firstOrNull ?? {};
      enterprise['contact']['address'] =
          (enterprise['contact']['addresses'] as List?)?.firstOrNull ?? {};
      enterprise['contact']['phone'] =
          (enterprise['contact']['phone_numbers'] as List?)?.firstOrNull ?? {};
      enterprise['activity_types'] =
          (enterprise['activity_types'] as List? ?? [])
              .map((e) => e['activity_type'])
              .toList();
      enterprise['phone'] = (enterprise['phone_number'] as List?)?.firstOrNull;
      enterprise['fax'] = (enterprise['fax_number'] as List?)?.firstOrNull;
      enterprise['address'] =
          (enterprise['address'] as List?)?.firstOrNull ?? {};
      enterprise['headquarters_address'] =
          (enterprise['headquarters_address'] as List?)?.firstOrNull ?? {};

      final jobsTp = await sqlInterface.performSelectQuery(
        user: user,
        tableName: 'enterprise_jobs',
        filters: {'enterprise_id': enterprise['id']},
        subqueries: [
          sqlInterface.selectSubquery(
              dataTableName: 'enterprise_job_positions_offered',
              asName: 'positions_offered',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['school_id', 'positions']),
          sqlInterface.selectSubquery(
              dataTableName: 'enterprise_job_photos',
              asName: 'photo',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['photo']),
          sqlInterface.selectSubquery(
              dataTableName: 'enterprise_job_comments',
              asName: 'comments',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['comment', 'user_id', 'date']),
          sqlInterface.selectSubquery(
              dataTableName: 'enterprise_job_pre_internship_requests',
              asName: 'pre_internship_requests',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['id', 'other', 'is_applicable']),
          sqlInterface.selectSubquery(
              dataTableName: 'enterprise_job_incidents',
              asName: 'incidents',
              idNameToDataTable: 'job_id',
              fieldsToFetch: [
                'id',
                'user_id',
                'incident_type',
                'incident',
                'date'
              ]),
        ],
      );
      final jobs = <String, dynamic>{};
      for (final job in jobsTp) {
        jobs[job['id']] = job;
        jobs[job['id']]['positions_offered'] =
            (job['positions_offered'] as List?)?.asMap().map((_, e) => MapEntry(
                    e['school_id'].toString(), e['positions'] as int? ?? 0)) ??
                {};
        if ((job['photo'] as List?) != null) {
          // The 'photos' in this list were casted to String when fetching from the database
          // So we need to refetch them properly
          final photos = (await sqlInterface.performSelectQuery(
              user: user,
              tableName: 'enterprise_job_photos',
              filters: {'job_id': job['id']}) as List);
          jobs[job['id']]['photos'] = photos
              .map((e) => {'bytes': (e['photo'] as Blob).toBytes()})
              .toList();
        }
        jobs[job['id']]['comments'] = (job['comments'] as List?)
                ?.map((e) => {
                      'id': e['job_id'],
                      'comment': e['comment'],
                      'user_id': e['user_id'],
                      'date': e['date']
                    })
                .toList() ??
            [];
        jobs[job['id']]['pre_internship_requests'] =
            ((job['pre_internship_requests'] as List?)?.first as Map?) ?? {};
        jobs[job['id']]['pre_internship_requests']['is_applicable'] =
            jobs[job['id']]['pre_internship_requests']['is_applicable'] == 1;
        jobs[job['id']]['pre_internship_requests']['requests'] =
            (await sqlInterface.performSelectQuery(
                  user: user,
                  tableName: 'enterprise_job_pre_internship_request_items',
                  filters: {
                    'internship_request_id': job['pre_internship_requests']
                        ['id']
                  },
                ) as List?)
                    ?.map((e) => e['request'] as int)
                    .toList() ??
                [];
        final incidents = job['incidents'] as List? ?? [];
        jobs[job['id']]['incidents'] = incidents.isEmpty
            ? null
            : {
                'severe_injuries': incidents
                    .where((e) => e['incident_type'] == 'severe_injuries')
                    .toList(),
                'verbal_abuses': incidents
                    .where((e) => e['incident_type'] == 'verbal_abuses')
                    .toList(),
                'minor_injuries': incidents
                    .where((e) => e['incident_type'] == 'minor_injuries')
                    .toList(),
              };
      }
      enterprise['jobs'] = jobs;

      map[enterprise['id'].toString()] = Enterprise.fromSerialized(enterprise);
    }

    return map;
  }

  @override
  Future<Enterprise?> _getEnterpriseById({
    required String id,
    required DatabaseUser user,
  }) async =>
      (await _getAllEnterprises(enterpriseId: id, user: user))[id];

  Future<void> _insertToEnterprises(Enterprise enterprise) async {
    await sqlInterface.performInsertQuery(
        tableName: 'entities', data: {'shared_id': enterprise.id.serialize()});
    await sqlInterface.performInsertQuery(
      tableName: 'enterprises',
      data: {
        'id': enterprise.id.serialize(),
        'school_board_id': enterprise.schoolBoardId.serialize(),
        'version': Enterprise.currentVersion.serialize(),
        'name': enterprise.name.serialize(),
        'status': enterprise.status.serialize(),
        'recruiter_id': enterprise.recruiterId.isEmpty
            ? null
            : enterprise.recruiterId.serialize(),
        'contact_function': enterprise.contactFunction.serialize(),
        'website': enterprise.website.serialize(),
        'neq': enterprise.neq.serialize(),
      },
    );
  }

  Future<void> _updateToEnterprises(
      Enterprise enterprise, Enterprise previous) async {
    final differences = enterprise.getDifference(previous);

    final toUpdate = <String, dynamic>{};
    if (differences.contains('name')) {
      toUpdate['name'] = enterprise.name.serialize();
    }
    if (differences.contains('status')) {
      toUpdate['status'] = enterprise.status.serialize();
    }
    if (differences.contains('recruiter_id')) {
      toUpdate['recruiter_id'] = enterprise.recruiterId.isEmpty
          ? null
          : enterprise.recruiterId.serialize();
    }
    if (differences.contains('contact_function')) {
      toUpdate['contact_function'] = enterprise.contactFunction.serialize();
    }
    if (differences.contains('website')) {
      toUpdate['website'] = enterprise.website.serialize();
    }
    if (differences.contains('neq')) {
      toUpdate['neq'] = enterprise.neq.serialize();
    }

    if (toUpdate.isNotEmpty) {
      await sqlInterface.performUpdateQuery(
        tableName: 'enterprises',
        filters: {'id': previous.id},
        data: toUpdate,
      );
    }
  }

  Future<void> _insertToEnterprisesActivityTypes(Enterprise enterprise) async {
    for (final activityType in enterprise.activityTypesSerialized) {
      await sqlInterface
          .performInsertQuery(tableName: 'enterprise_activity_types', data: {
        'enterprise_id': enterprise.id.serialize(),
        'activity_type': activityType,
      });
    }
  }

  Future<void> _updateToEnterprisesActivityTypes(
      Enterprise enterprise, Enterprise previous) async {
    final toUpdate = enterprise.getDifference(previous);
    if (!toUpdate.contains('activity_types')) return;

    // This is a bit tricky to simply update, so we delete and reinsert
    await sqlInterface.performDeleteQuery(
        tableName: 'enterprise_activity_types',
        filters: {'enterprise_id': previous.id});
    await _insertToEnterprisesActivityTypes(enterprise);
  }

  Future<void> _insertPositionsOffered(
      Map<String, int> positionOffered, String jobId) async {
    final toWait = <Future>[];
    for (final entry in positionOffered.entries) {
      toWait.add(sqlInterface.performInsertQuery(
          tableName: 'enterprise_job_positions_offered',
          data: {
            'job_id': jobId.serialize(),
            'school_id': entry.key,
            'positions': entry.value,
          }));
    }
    await Future.wait(toWait);
  }

  Future<void> _insertJobPhotos(List<Photo> photos, String jobId) async {
    final toWait = <Future>[];
    for (final photo in photos) {
      toWait.add(sqlInterface
          .performInsertQuery(tableName: 'enterprise_job_photos', data: {
        'job_id': jobId.serialize(),
        'photo':
            ImageHelpers.resizeImage(photo.bytes, width: null, height: 350),
      }));
    }
    await Future.wait(toWait);
  }

  Future<void> _insertJobComments(
      List<JobComment> comments, String jobId) async {
    final toWait = <Future>[];
    for (final comment in comments) {
      toWait.add(sqlInterface
          .performInsertQuery(tableName: 'enterprise_job_comments', data: {
        'job_id': jobId.serialize(),
        'user_id': comment.userId.serialize(),
        'date': comment.date.serialize(),
        'comment': comment.comment.serialize(),
      }));
    }
    await Future.wait(toWait);
  }

  Future<void> _insertJobPreintershipRequests(
      PreInternshipRequests requests, String jobId) async {
    // Insert pre-internship requests for the job
    final preInternshipRequests = requests.serialize();
    await sqlInterface.performInsertQuery(
        tableName: 'enterprise_job_pre_internship_requests',
        data: {
          'id': preInternshipRequests['id'],
          'job_id': jobId.serialize(),
          'other': preInternshipRequests['other'],
          'is_applicable': preInternshipRequests['is_applicable'],
        });

    final toWait = <Future>[];
    for (final request in (preInternshipRequests['requests'] as List)) {
      toWait.add(sqlInterface.performInsertQuery(
          tableName: 'enterprise_job_pre_internship_request_items',
          data: {
            'internship_request_id': preInternshipRequests['id'],
            'request': request,
          }));
    }
    await Future.wait(toWait);
  }

  Future<void> _insertJobIncidents(Incidents incidents, String jobId) async {
    final serialized = incidents.serialize();
    final toWait = <Future>[];
    for (final incidentType in serialized.keys) {
      if (incidentType == 'id') continue;
      for (final incident in serialized[incidentType]) {
        toWait.add(sqlInterface
            .performInsertQuery(tableName: 'enterprise_job_incidents', data: {
          'id': incident['id'],
          'user_id': incident['user_id'],
          'job_id': jobId.serialize(),
          'incident_type': incidentType.serialize(),
          'incident': incident['incident'],
          'date': incident['date'],
        }));
      }
    }
    await Future.wait(toWait);
  }

  Future<void> _insertToEnterprisesJob(String enterpriseId, Job job) async {
    await sqlInterface.performInsertQuery(tableName: 'enterprise_jobs', data: {
      'id': job.id.serialize(),
      'version': Job.currentVersion.serialize(),
      'enterprise_id': enterpriseId.serialize(),
      'specialization_id': job.specialization.id.serialize(),
      'minimum_age': job.minimumAge.serialize(),
      'reserved_for_id':
          job.reservedForId.isEmpty ? null : job.reservedForId.serialize(),
    });

    final toWait = <Future>[];
    toWait
        .add(_insertPositionsOffered(job.positionsOffered, job.id.serialize()));
    toWait.add(_insertJobPhotos(job.photos, job.id.serialize()));
    toWait.add(_insertJobComments(job.comments, job.id.serialize()));
    toWait.add(_insertJobPreintershipRequests(
        job.preInternshipRequests, job.id.serialize()));
    toWait.add(_insertJobIncidents(job.incidents, job.id.serialize()));

    await Future.wait(toWait);
  }

  Future<void> _insertToEnterprisesJobs(Enterprise enterprise) async {
    final toWait = <Future>[];
    for (final job in enterprise.jobs) {
      toWait.add(_insertToEnterprisesJob(enterprise.id, job));
    }
    await Future.wait(toWait);
  }

  Future<RepositoryResponse> _updateToEnterprisesJobs(
    Enterprise enterprise,
    Enterprise previous, {
    required DatabaseUser user,
    required InternshipsRepository internshipsRepository,
    required StudentsRepository studentsRepository,
  }) async {
    final out = RepositoryResponse();

    final toUpdate = enterprise.getDifference(previous);
    if (!toUpdate.contains('jobs')) return out;

    // Prevent from removing a job from an enterprise
    for (final job in previous.jobs) {
      if (!enterprise.jobs.map((e) => e.id).contains(job.id)) {
        if (user.accessLevel < AccessLevel.schoolAdmin) {
          _logger.warning(
              'User ${user.userId} tried to remove job (${job.id}) from enterprise '
              '(${enterprise.id}) but does not have permission, skipping');
          continue;
        }

        await _deleteInternshipsFromJob(job.id,
            user: user,
            internshipsRepository: internshipsRepository,
            studentsRepository: studentsRepository);

        await sqlInterface.performDeleteQuery(
            tableName: 'enterprise_jobs', filters: {'id': job.id});
      }
    }

    // Add the new jobs
    final toWait = <Future>[];
    for (final job in enterprise.jobs) {
      if (!previous.jobs.map((e) => e.id).contains(job.id)) {
        toWait.add(_insertToEnterprisesJob(enterprise.id, job));
      }
    }
    await Future.wait(toWait);

    for (final job in enterprise.jobs) {
      final previousJob = previous.jobs.firstWhereOrNull((e) => e.id == job.id);
      if (previousJob == null) continue; // Dealt with above

      final differences = job.getDifference(previousJob);
      final toUpdate = <String, dynamic>{};
      if (differences.contains('specialization_id')) {
        if (user.accessLevel < AccessLevel.schoolAdmin) {
          _logger.warning(
              'User ${user.userId} tried to update "specialization_id" of job (${job.id}) '
              'of enterprise (${enterprise.id}) but does not have permission, skipping');
        } else {
          toUpdate['specialization_id'] = job.specialization.id.serialize();
        }
      }

      if (differences.contains('minimum_age')) {
        toUpdate['minimum_age'] = job.minimumAge.serialize();
      }
      if (differences.contains('reserved_for_id')) {
        if (user.accessLevel < AccessLevel.schoolAdmin) {
          _logger.warning(
              'User ${user.userId} tried to update "reserved_for_id" of job (${job.id}) '
              'of enterprise (${enterprise.id}) but does not have permission, skipping');
        } else {
          toUpdate['reserved_for_id'] =
              job.reservedForId.isEmpty ? null : job.reservedForId.serialize();
        }
      }

      if (toUpdate.isNotEmpty) {
        await sqlInterface.performUpdateQuery(
          tableName: 'enterprise_jobs',
          filters: {'id': job.id},
          data: toUpdate,
        );
      }

      // Position offered, Photos, Comments, and incidents are
      // tricky to update (particularly those who can be removed), so we delete them all
      // and reinsert all of them.
      final toWaitDeleted = <Future>[];
      toWait.clear();
      if (differences.contains('positions_offered')) {
        toWaitDeleted.add(sqlInterface.performDeleteQuery(
          tableName: 'enterprise_job_positions_offered',
          filters: {'job_id': job.id},
        ));

        late final Map<String, int> newPositionsOffered;
        if (user.accessLevel < AccessLevel.schoolBoardAdmin) {
          // Only school admins can modify all positions offered, others can only
          // modify their own school positions offered
          newPositionsOffered =
              previousJob.positionsOffered.map((k, v) => MapEntry(k, v));
          newPositionsOffered[user.schoolId!] =
              job.positionsOffered[user.schoolId] ?? 0;
        } else {
          newPositionsOffered = job.positionsOffered;
        }

        toWait.add(
            _insertPositionsOffered(newPositionsOffered, job.id.serialize()));
      }
      if (differences.contains('photos')) {
        // This is a bit tricky to simply update, so we delete and reinsert
        toWaitDeleted.add(sqlInterface.performDeleteQuery(
            tableName: 'enterprise_job_photos', filters: {'job_id': job.id}));
        toWait.add(_insertJobPhotos(job.photos, job.id.serialize()));
      }

      if (differences.contains('comments')) {
        toWaitDeleted.add(sqlInterface.performDeleteQuery(
            tableName: 'enterprise_job_comments', filters: {'job_id': job.id}));
        toWait.add(_insertJobComments(job.comments, job.id.serialize()));
      }

      // Pre-internship requests would not be that hard to actually update, but
      // is not so important, so we use the same trick of deleting and reinserting.
      // It helps to keep the code simple and consistent and also helps for the items.
      if (differences.contains('pre_internship_requests')) {
        toWaitDeleted.add(sqlInterface.performDeleteQuery(
            tableName: 'enterprise_job_pre_internship_requests',
            filters: {'job_id': job.id}));
        toWait.add(_insertJobPreintershipRequests(
            job.preInternshipRequests, job.id.serialize()));
      }

      if (differences.contains('incidents')) {
        toWaitDeleted.add(sqlInterface.performDeleteQuery(
            tableName: 'enterprise_job_incidents',
            filters: {'job_id': job.id}));
        toWait.add(_insertJobIncidents(job.incidents, job.id.serialize()));
      }

      // Wait for all the deletions and insertions to finish
      await Future.wait(toWaitDeleted);
      await Future.wait(toWait);
    }
    return out;
  }

  Future<void> _insertToContact(Enterprise enterprise) async {
    // Insert the contact
    await sqlInterface.performInsertPerson(person: enterprise.contact);
    await sqlInterface.performInsertQuery(
        tableName: 'enterprise_contacts',
        data: {
          'enterprise_id': enterprise.id,
          'contact_id': enterprise.contact.id
        });
  }

  Future<void> _updateToContact(
      Enterprise enterprise, Enterprise previous) async {
    final toUpdate = enterprise.getDifference(previous);
    if (!toUpdate.contains('contact')) return;

    await sqlInterface.performUpdatePerson(
        person: enterprise.contact, previous: previous.contact);
  }

  Future<void> _insertToEnterpriseAddress(Enterprise enterprise) async {
    await sqlInterface.performInsertAddress(
        address: enterprise.address, entityId: enterprise.id);
    await sqlInterface.performInsertQuery(
        tableName: 'enterprise_addresses',
        data: {
          'enterprise_id': enterprise.id,
          'address_id': enterprise.address.id
        });
  }

  Future<void> _updateToEnterpriseAddress(
      Enterprise enterprise, Enterprise previous) async {
    final toUpdate = enterprise.getDifference(previous);
    if (!toUpdate.contains('address')) return;

    await sqlInterface.performUpdateAddress(
        address: enterprise.address, previous: previous.address);
  }

  Future<void> _insertToEnterpriseHeadquartersAddress(
      Enterprise enterprise) async {
    await sqlInterface.performInsertAddress(
        address: enterprise.headquartersAddress, entityId: enterprise.id);
    await sqlInterface.performInsertQuery(
        tableName: 'enterprise_headquarters_addresses',
        data: {
          'enterprise_id': enterprise.id,
          'address_id': enterprise.headquartersAddress.id
        });
  }

  Future<void> _updateToEnterpriseHeadquartersAddress(
      Enterprise enterprise, Enterprise previous) async {
    final toUpdate = enterprise.getDifference(previous);
    if (!toUpdate.contains('headquarters_address')) return;

    await sqlInterface.performUpdateAddress(
        address: enterprise.headquartersAddress,
        previous: previous.headquartersAddress);
  }

  Future<void> _insertToEnterprisePhoneNumber(Enterprise enterprise) async {
    await sqlInterface.performInsertPhoneNumber(
        phoneNumber: enterprise.phone, entityId: enterprise.id);
    await sqlInterface.performInsertQuery(
        tableName: 'enterprise_phone_numbers',
        data: {
          'enterprise_id': enterprise.id,
          'phone_number_id': enterprise.phone.id
        });
  }

  Future<void> _updateToEnterprisePhoneNumber(
      Enterprise enterprise, Enterprise previous) async {
    final toUpdate = enterprise.getDifference(previous);
    if (!toUpdate.contains('phone')) return;

    await sqlInterface.performUpdatePhoneNumber(
        phoneNumber: enterprise.phone, previous: previous.phone);
  }

  Future<void> _insertToEnterpriseFax(Enterprise enterprise) async {
    await sqlInterface.performInsertPhoneNumber(
        phoneNumber: enterprise.fax, entityId: enterprise.id);
    await sqlInterface.performInsertQuery(
        tableName: 'enterprise_fax_numbers',
        data: {
          'enterprise_id': enterprise.id,
          'fax_number_id': enterprise.fax.id
        });
  }

  Future<void> _updateToEnterpriseFax(
      Enterprise enterprise, Enterprise previous) async {
    final toUpdate = enterprise.getDifference(previous);
    if (!toUpdate.contains('fax')) return;

    await sqlInterface.performUpdatePhoneNumber(
        phoneNumber: enterprise.fax, previous: previous.fax);
  }

  @override
  Future<void> _putEnterprise({
    required Enterprise enterprise,
    required Enterprise? previous,
    required DatabaseUser user,
    required InternshipsRepository internshipsRepository,
    required StudentsRepository studentsRepository,
  }) async {
    try {
      // Set to transaction to rollback at the end of the operation
      await sqlInterface.beginTransaction();

      if (previous == null) {
        await _insertToEnterprises(enterprise);
      } else {
        await _updateToEnterprises(enterprise, previous);
      }

      final toWait = <Future>[];
      if (previous == null) {
        toWait.add(_insertToEnterprisesActivityTypes(enterprise));
        toWait.add(_insertToEnterprisesJobs(enterprise));
        toWait.add(_insertToContact(enterprise));
        toWait.add(_insertToEnterpriseAddress(enterprise));
        toWait.add(_insertToEnterpriseHeadquartersAddress(enterprise));
        toWait.add(_insertToEnterprisePhoneNumber(enterprise));
        toWait.add(_insertToEnterpriseFax(enterprise));
      } else {
        toWait.add(_updateToEnterprisesActivityTypes(enterprise, previous));
        toWait.add(_updateToEnterprisesJobs(enterprise, previous,
            user: user,
            internshipsRepository: internshipsRepository,
            studentsRepository: studentsRepository));
        toWait.add(_updateToContact(enterprise, previous));
        toWait.add(_updateToEnterpriseAddress(enterprise, previous));
        toWait
            .add(_updateToEnterpriseHeadquartersAddress(enterprise, previous));
        toWait.add(_updateToEnterprisePhoneNumber(enterprise, previous));
        toWait.add(_updateToEnterpriseFax(enterprise, previous));
      }
      await Future.wait(toWait);

      await sqlInterface.commitTransaction();
    } catch (_) {
      await sqlInterface.rollbackTransaction();
      rethrow;
    }
  }

  Future<void> _deleteInternshipsFromJob(
    String jobId, {
    required DatabaseUser user,
    required InternshipsRepository internshipsRepository,
    required StudentsRepository? studentsRepository,
  }) async {
    final internshipIds = (await sqlInterface.performSelectQuery(
        user: user,
        tableName: 'internship_contracts',
        fieldsToFetch: ['internship_id'],
        filters: {'job_id': jobId.serialize()}));

    final toWait = <Future>[];
    for (final internshipId in internshipIds) {
      toWait.add(internshipsRepository.deleteById(
          id: internshipId['internship_id'],
          user: user,
          studentsRepository: studentsRepository));
    }
    await Future.wait(toWait);
  }

  @override
  Future<RepositoryResponse> _deleteEnterprise({
    required String id,
    required DatabaseUser user,
    required InternshipsRepository internshipsRepository,
    required StudentsRepository studentsRepository,
  }) async {
    final out = RepositoryResponse();

    try {
      await sqlInterface.beginTransaction();

      final enterprise = await _getEnterpriseById(id: id, user: user);
      if (enterprise == null) {
        throw InvalidRequestException('Enterprise with id $id not found');
      }

      if (enterprise.jobs.isNotEmpty) {
        for (final job in enterprise.jobs) {
          await _deleteInternshipsFromJob(job.id,
              user: user,
              internshipsRepository: internshipsRepository,
              studentsRepository: studentsRepository);
        }
        out.deletedData ??= {};
        out.deletedData![RequestFields.internship] = {
          enterprise.id: Enterprise.fetchableFields.extractFrom(['jobs'])
        };
      }

      await sqlInterface.performDeleteQuery(
        tableName: 'enterprise_addresses',
        filters: {'enterprise_id': id},
      );
      await sqlInterface.performDeleteQuery(
        tableName: 'enterprise_headquarters_addresses',
        filters: {'enterprise_id': id},
      );
      await sqlInterface.performDeleteQuery(
        tableName: 'entities',
        filters: {'shared_id': id},
      );

      await sqlInterface.performDeleteQuery(
        tableName: 'addresses',
        filters: {'entity_id': enterprise.address.id},
      );
      await sqlInterface.performDeleteQuery(
        tableName: 'addresses',
        filters: {'entity_id': enterprise.headquartersAddress.id},
      );
      await sqlInterface.performDeleteQuery(
        tableName: 'phone_numbers',
        filters: {'entity_id': enterprise.phone.id},
      );
      await sqlInterface.performDeleteQuery(
        tableName: 'phone_numbers',
        filters: {'entity_id': enterprise.fax.id},
      );

      await sqlInterface.performDeleteQuery(
        tableName: 'entities',
        filters: {'shared_id': enterprise.contact.id},
      );

      out.deletedData ??= {};
      out.deletedData![RequestFields.enterprise] ??= {id: FetchableFields.all};

      await sqlInterface.commitTransaction();
    } catch (e) {
      await sqlInterface.rollbackTransaction();
      throw InvalidRequestException(
          'Unable to delete the enterprise with id $id. Is there any internships associated with this enterprise? $e');
    }
    return out;
  }
  // coverage:ignore-end
}

class EnterprisesRepositoryMock extends EnterprisesRepository {
  // Simulate a database with a map
  final _dummyDatabase = {
    '0': Enterprise.empty.copyWith(
      id: '0',
      schoolBoardId: '0',
      name: 'My First Enterprise',
      status: EnterpriseStatus.active,
      jobs: JobList(),
      activityTypes: {ActivityTypes.magasin, ActivityTypes.entreposage},
      recruiterId: 'Recruiter 1',
      contact: Person.empty,
      address: Address.empty,
      phone: PhoneNumber.fromString('123-456-7890'),
      fax: PhoneNumber.fromString('098-765-4321'),
    ),
    '1': Enterprise.empty.copyWith(
      id: '1',
      schoolBoardId: '0',
      name: 'My Second Enterprise',
      status: EnterpriseStatus.active,
      jobs: JobList(),
      activityTypes: {
        ActivityTypes.magasin,
        ActivityTypes.entreposage,
        ActivityTypes.ebenisterie
      },
      recruiterId: 'Recruiter 2',
      contact: Person.empty,
      address: Address.empty,
      phone: PhoneNumber.fromString('123-456-7890'),
      fax: PhoneNumber.fromString('098-765-4321'),
    )
  };

  @override
  Future<Map<String, Enterprise>> _getAllEnterprises({
    required DatabaseUser user,
  }) async =>
      _dummyDatabase;

  @override
  Future<Enterprise?> _getEnterpriseById({
    required String id,
    required DatabaseUser user,
  }) async =>
      _dummyDatabase[id];

  @override
  Future<void> _putEnterprise({
    required Enterprise enterprise,
    required Enterprise? previous,
    required DatabaseUser user,
    required InternshipsRepository internshipsRepository,
    required StudentsRepository studentsRepository,
  }) async {
    _dummyDatabase[enterprise.id] = enterprise;
  }

  @override
  Future<RepositoryResponse> _deleteEnterprise({
    required String id,
    required DatabaseUser user,
    required InternshipsRepository internshipsRepository,
    required StudentsRepository studentsRepository,
  }) async {
    if (_dummyDatabase.containsKey(id)) {
      _dummyDatabase.remove(id);
      return RepositoryResponse(deletedData: {
        RequestFields.enterprise: {id: FetchableFields.all}
      });
    }
    return RepositoryResponse();
  }
}
