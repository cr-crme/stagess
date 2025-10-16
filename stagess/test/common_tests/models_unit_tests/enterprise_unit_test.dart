import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/extensions/enterprise_extension.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job_list.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

import '../../utils.dart';
import '../utils.dart';

void main() {
  group('Enterprise', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    test('"copyWith" changes the requested elements', () {
      final enterprise = dummyEnterprise(addJob: true);

      final enterpriseSame = enterprise.copyWith();
      expect(enterpriseSame.id, enterprise.id);
      expect(enterpriseSame.name, enterprise.name);
      expect(enterpriseSame.activityTypes, enterprise.activityTypes);
      expect(enterpriseSame.recruiterId, enterprise.recruiterId);
      expect(enterpriseSame.jobs, enterprise.jobs);
      expect(enterpriseSame.contact, enterprise.contact);
      expect(enterpriseSame.contactFunction, enterprise.contactFunction);
      expect(enterpriseSame.address, enterprise.address);
      expect(enterpriseSame.phone, enterprise.phone);
      expect(enterpriseSame.fax, enterprise.fax);
      expect(enterpriseSame.website, enterprise.website);
      expect(
        enterpriseSame.headquartersAddress,
        enterprise.headquartersAddress,
      );
      expect(enterpriseSame.neq, enterprise.neq);

      final enterpriseDifferent = enterprise.copyWith(
        id: 'newId',
        name: 'newName',
        activityTypes: {ActivityTypes.autre},
        recruiterId: 'newRecrutedBy',
        jobs: JobList()..add(dummyJob(id: 'newJobId')),
        contact: Person(
          firstName: 'Pariterre',
          middleName: null,
          lastName: 'Nobody',
          dateBirth: null,
          phone: PhoneNumber.empty,
          address: Address.empty,
          email: null,
        ),
        contactFunction: 'newContactFunction',
        address: dummyAddress().copyWith(id: 'newAddressId'),
        phone: PhoneNumber.fromString('866-666-6666'),
        fax: PhoneNumber.fromString('866-666-6666'),
        website: 'newWebsite',
        headquartersAddress: dummyAddress().copyWith(
          id: 'newHeadquartersAddressId',
        ),
        neq: 'newNeq',
      );

      expect(enterpriseDifferent.id, 'newId');
      expect(enterpriseDifferent.name, 'newName');
      expect(enterpriseDifferent.activityTypes, {ActivityTypes.autre});
      expect(enterpriseDifferent.recruiterId, 'newRecrutedBy');
      expect(enterpriseDifferent.jobs[0].id, 'newJobId');
      expect(enterpriseDifferent.contact.fullName, 'Pariterre Nobody');
      expect(enterpriseDifferent.contactFunction, 'newContactFunction');
      expect(enterpriseDifferent.address!.id, 'newAddressId');
      expect(enterpriseDifferent.phone.toString(), '(866) 666-6666');
      expect(enterpriseDifferent.fax.toString(), '(866) 666-6666');
      expect(enterpriseDifferent.website, 'newWebsite');
      expect(
        enterpriseDifferent.headquartersAddress!.id,
        'newHeadquartersAddressId',
      );
      expect(enterpriseDifferent.neq, 'newNeq');
    });

    testWidgets('"internships" behaves properly', (tester) async {
      final enterprise = dummyEnterprise(addJob: true);
      final context = await tester.contextWithNotifiers(withInternships: true);
      final internships = InternshipsProvider.of(context, listen: false);

      // Add an internship to another enterprise, which should not be counted
      internships.add(
        dummyInternship(
          id: 'anotherInternshipId',
          enterpriseId: 'anotherEnterpriseId',
          jobId: 'anotherJobId',
        ),
      );

      // No internships
      expect(enterprise.internships(context, listen: false).length, 0);

      // One internship
      internships.add(
        dummyInternship(
          enterpriseId: enterprise.id,
          jobId: enterprise.jobs[0].id,
        ),
      );
      expect(enterprise.internships(context, listen: false).length, 1);

      // Two internships
      internships.add(
        dummyInternship(
          id: 'anotherInternshipId',
          enterpriseId: enterprise.id,
          jobId: enterprise.jobs[0].id,
        ),
      );
      expect(enterprise.internships(context, listen: false).length, 2);

      // One internship is terminated, but still counts as an internship
      internships.replace(
        internships[1].copyWith(
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      expect(enterprise.internships(context, listen: false).length, 2);
    });

    testWidgets('"withRemainingPositions" behaves properly', (tester) async {
      final enterprise = dummyEnterprise(addJob: true);
      final context = await tester.contextWithNotifiers(withInternships: true);
      final internships = InternshipsProvider.of(context, listen: false);

      // Add an internship to another enterprise, which should not be counted
      internships.add(
        dummyInternship(
          id: 'anotherInternshipId',
          enterpriseId: 'anotherEnterpriseId',
          jobId: 'anotherJobId',
        ),
      );

      // One job with two positions was created, so it should be available
      expect(
        enterprise
            .withRemainingPositions(context, schoolId: 'school_id')
            .length,
        1,
      );

      // Fill one of that position, so it should still be available
      internships.add(
        dummyInternship(
          enterpriseId: enterprise.id,
          jobId: enterprise.jobs[0].id,
        ),
      );
      expect(
        enterprise
            .withRemainingPositions(context, schoolId: 'school_id')
            .length,
        1,
      );

      // Fill the remainning one, so it should not be available anymore
      internships.add(
        dummyInternship(
          id: 'anotherInternshipId',
          enterpriseId: enterprise.id,
          jobId: enterprise.jobs[0].id,
        ),
      );
      expect(
        enterprise
            .withRemainingPositions(context, schoolId: 'school_id')
            .length,
        0,
      );

      // Terminate one the of job, so it should be available again
      internships.replace(
        internships[1].copyWith(
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      expect(
        enterprise
            .withRemainingPositions(context, schoolId: 'school_id')
            .length,
        1,
      );
    });

    test('serialization and deserialization works', () {
      final enterprise = dummyEnterprise(addJob: true);
      final serialized = enterprise.serialize();
      final deserialized = Enterprise.fromSerialized(serialized);

      expect(serialized, {
        'id': enterprise.id,
        'school_board_id': enterprise.schoolBoardId,
        'name': enterprise.name,
        'version': Enterprise.currentVersion,
        'activity_types': enterprise.activityTypes.toList(),
        'recruiter_id': enterprise.recruiterId,
        'jobs': enterprise.jobs.serialize(),
        'contact': enterprise.contact.serialize(),
        'contact_function': enterprise.contactFunction,
        'address': enterprise.address?.serialize(),
        'phone': enterprise.phone?.serialize(),
        'fax': enterprise.fax?.serialize(),
        'website': enterprise.website,
        'headquarters_address': enterprise.headquartersAddress?.serialize(),
        'status': enterprise.status.index,
        'neq': enterprise.neq,
      });

      expect(deserialized.id, enterprise.id);
      expect(deserialized.schoolBoardId, enterprise.schoolBoardId);
      expect(deserialized.name, enterprise.name);
      expect(deserialized.activityTypes, enterprise.activityTypes);
      expect(deserialized.recruiterId, enterprise.recruiterId);
      expect(deserialized.jobs[0].id, enterprise.jobs[0].id);
      expect(deserialized.contact.id, enterprise.contact.id);
      expect(deserialized.contactFunction, enterprise.contactFunction);
      expect(deserialized.address?.id, enterprise.address?.id);
      expect(deserialized.phone.toString(), enterprise.phone.toString());
      expect(deserialized.fax.toString(), enterprise.fax.toString());
      expect(deserialized.website, enterprise.website);
      expect(
        deserialized.headquartersAddress?.id,
        enterprise.headquartersAddress?.id,
      );
      expect(deserialized.status.index, enterprise.status.index);
      expect(deserialized.neq, enterprise.neq);

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = Enterprise.fromSerialized({'id': 'emptyId'});
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.name, 'Unnamed enterprise');
      expect(emptyDeserialized.activityTypes, <Set>{});
      expect(emptyDeserialized.recruiterId, '');
      expect(emptyDeserialized.jobs.length, 0);
      expect(emptyDeserialized.contact.firstName, 'Unnamed');
      expect(emptyDeserialized.contactFunction, '');
      expect(emptyDeserialized.address, isNull);
      expect(emptyDeserialized.phone, isNull);
      expect(emptyDeserialized.fax, isNull);
      expect(emptyDeserialized.website, isNull);
      expect(emptyDeserialized.headquartersAddress, isNull);
      expect(emptyDeserialized.neq, isNull);
    });
  });
}
