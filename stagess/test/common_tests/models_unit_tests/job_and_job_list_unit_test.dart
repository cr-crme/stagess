import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/extensions/job_extension.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/enterprises/job_comment.dart';
import 'package:stagess_common/models/enterprises/job_list.dart';
import 'package:stagess_common/models/generic/photo.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

import '../../utils.dart';
import '../utils.dart';

void main() {
  group('Job and JobList', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    testWidgets('can get evaluation of all enterprises', (tester) async {
      final context = await tester.contextWithNotifiers(withInternships: true);
      final job = dummyJob();

      // No evaluation yet
      expect(job.postInternshipEnterpriseEvaluations(context).length, 0);

      // Add an evaluation
      InternshipsProvider.of(context, listen: false).add(dummyInternship());
      expect(job.postInternshipEnterpriseEvaluations(context).length, 1);
    });

    test('"copyWith" behaves properly', () {
      final job = dummyJob(
        preInternshipId: 'newPreInternshipId',
        uniformId: 'newUniformId',
        protectionsId: 'newProtectionsId',
        incidentsId: 'newIncidentsId',
      );

      final jobSame = job.copyWith();
      expect(jobSame.id, job.id);
      expect(jobSame.specialization, job.specialization);
      expect(jobSame.positionsOffered, job.positionsOffered);
      expect(jobSame.minimumAge, job.minimumAge);
      expect(jobSame.preInternshipRequests, job.preInternshipRequests);
      expect(jobSame.uniforms, job.uniforms);
      expect(jobSame.protections, job.protections);
      expect(jobSame.photos, job.photos);
      expect(jobSame.incidents, job.incidents);
      expect(jobSame.comments, job.comments);

      final jobDifferent = job.copyWith(
        id: 'newId',
        specialization:
            ActivitySectorsService.activitySectors[2].specializations[8],
        positionsOffered: {'school_id': 2},
        minimumAge: 12,
        preInternshipRequests: dummyPreInternshipRequests(
          id: 'newPreInternshipId',
        ),
        uniforms: dummyUniforms(id: 'newUniformId'),
        protections: dummyProtections(id: 'newProtectionsId'),
        photos: [dummyPhoto()],
        incidents: dummyIncidents(id: 'newIncidentsId'),
        comments: [dummyJobComment()],
      );

      expect(jobDifferent.id, 'newId');
      expect(
        jobDifferent.specialization.id,
        ActivitySectorsService.activitySectors[2].specializations[8].id,
      );
      expect(jobDifferent.positionsOffered, {'school_id': 2});
      expect(jobDifferent.minimumAge, 12);
      expect(jobDifferent.preInternshipRequests.id, 'newPreInternshipId');
      expect(jobDifferent.uniforms.id, 'newUniformId');
      expect(jobDifferent.protections.id, 'newProtectionsId');
      expect(jobDifferent.photos, isA<List<Photo>>());
      expect(jobDifferent.photos.length, 1);
      expect(jobDifferent.photos[0].id, 'photoId');
      expect(jobDifferent.incidents.id, 'newIncidentsId');
      expect(jobDifferent.preInternshipRequests.id, 'newPreInternshipId');
      expect(jobDifferent.uniforms.id, 'newUniformId');
      expect(jobDifferent.protections.id, 'newProtectionsId');
      expect(jobDifferent.comments, isA<List<JobComment>>());
      expect(jobDifferent.comments.length, 1);
      expect(jobDifferent.comments[0].id, 'jobCommentId');
    });

    test('has the rigt amount', () {
      final jobList = dummyJobList();
      expect(jobList.length, 1);
    });

    test('"specialization" behaves properly', () {
      expect(dummyJob().specialization, isNotNull);
      expect(() => Job.fromSerialized({}).specialization, throwsArgumentError);
    });

    test('serialization and deserialization works for Job', () {
      final job = dummyJob();
      final serialized = job.serialize();
      final deserialized = Job.fromSerialized(serialized);

      expect(serialized, {
        'id': job.id,
        'version': Job.currentVersion,
        'specialization_id': job.specialization.id,
        'positions_offered': job.positionsOffered,
        'minimum_age': job.minimumAge,
        'pre_internship_requests': job.preInternshipRequests.serialize(),
        'uniforms': job.uniforms.serialize(),
        'protections': job.protections.serialize(),
        'photos': job.photos.serialize(),
        'incidents': job.incidents.serialize(),
        'comments': job.comments,
        'reserved_for_id': job.reservedForId,
      });

      expect(deserialized.id, job.id);
      expect(deserialized.specialization.id, job.specialization.id);
      expect(deserialized.positionsOffered, job.positionsOffered);
      expect(deserialized.minimumAge, job.minimumAge);
      expect(
        deserialized.preInternshipRequests.id,
        job.preInternshipRequests.id,
      );
      expect(deserialized.uniforms.id, job.uniforms.id);
      expect(deserialized.protections.id, job.protections.id);
      expect(deserialized.photos, job.photos);
      expect(deserialized.incidents.id, job.incidents.id);
      expect(deserialized.comments, job.comments);

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = Job.fromSerialized({'id': 'emptyId'});
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.positionsOffered, {});
      expect(emptyDeserialized.minimumAge, 0);
      expect(emptyDeserialized.preInternshipRequests.id, isNotNull);
      expect(emptyDeserialized.uniforms.id, isNotNull);
      expect(emptyDeserialized.protections.id, isNotNull);
      expect(emptyDeserialized.photos, []);
      expect(emptyDeserialized.incidents.id, isNotNull);
      expect(emptyDeserialized.comments, []);
    });

    test('serialization and deserialization works for JobList', () {
      final jobList = dummyJobList();
      jobList.add(dummyJob(id: 'newJobId'));
      final serialized = jobList.serialize();
      final deserialized = JobList.fromSerialized(serialized);

      expect(serialized, {
        for (var e in jobList)
          e.id: {
            'id': e.id,
            'version': Job.currentVersion,
            'specialization_id': e.specialization.id,
            'positions_offered': e.positionsOffered,
            'minimum_age': e.minimumAge,
            'pre_internship_requests': e.preInternshipRequests.serialize(),
            'uniforms': e.uniforms.serialize(),
            'protections': e.protections.serialize(),
            'photos': e.photos,
            'incidents': e.incidents.serialize(),
            'comments': e.comments,
            'reserved_for_id': e.reservedForId,
          },
      });

      expect(deserialized[0].id, jobList[0].id);
      expect(deserialized[0].specialization.id, jobList[0].specialization.id);
      expect(deserialized[0].positionsOffered, jobList[0].positionsOffered);
      expect(deserialized[0].incidents.id, jobList[0].incidents.id);
      expect(deserialized[0].minimumAge, jobList[0].minimumAge);
      expect(
        deserialized[0].preInternshipRequests.id,
        jobList[0].preInternshipRequests.id,
      );
      expect(deserialized[0].uniforms.id, jobList[0].uniforms.id);
      expect(deserialized[0].protections.id, jobList[0].protections.id);

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = JobList.fromSerialized({});
      expect(emptyDeserialized.length, 0);
    });
  });
}
