import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/extensions/internship_extension.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/time_utils.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

import '../../utils.dart';
import '../utils.dart';

void main() {
  group('Intenship', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    test('"isActive" and "isClosed" behave properly', () {
      final internship = dummyInternship();

      expect(internship.isActive, isTrue);
      expect(internship.isClosed, isFalse);

      final internshipClosed = internship.copyWith(
        endDate: DateTime(2020, 2, 4),
      );

      expect(internshipClosed.isActive, isFalse);
      expect(internshipClosed.isClosed, isTrue);
    });

    test('can add new version', () {
      final internship = dummyInternship();

      expect(internship.nbVersions, 1);
      expect(
        internship.creationDate.millisecondsSinceEpoch,
        DateTime(2005, 10, 31).millisecondsSinceEpoch,
      );
      expect(internship.creationDateFrom(0), internship.creationDate);
      expect(internship.supervisor.toString(), 'Nobody Forever');
      expect(internship.supervisorFrom(0), internship.supervisor);
      expect(
        internship.dates.start.millisecondsSinceEpoch,
        DateTime(2005, 10, 31).millisecondsSinceEpoch,
      );
      expect(
        internship.dates.end.millisecondsSinceEpoch,
        DateTime(
          2005,
          10,
          31,
        ).add(const Duration(days: 20)).millisecondsSinceEpoch,
      );
      expect(internship.dateFrom(0), internship.dates);
      expect(internship.weeklySchedules.length, 1);
      expect(internship.weeklySchedules[0].id, 'weeklyScheduleId');
      expect(internship.weeklySchedulesFrom(0), internship.weeklySchedules);

      internship.addVersion(
        creationDate: DateTime(2020, 2, 4),
        weeklySchedules: [dummyWeeklySchedule(id: 'newWeeklyScheduleId')],
        dates: DateTimeRange(
          start: DateTime(2000, 1, 1),
          end: DateTime(2001, 1, 1),
        ),
        supervisor: Person(
          firstName: 'New',
          middleName: null,
          lastName: 'Supervisor',
          dateBirth: null,
          phone: PhoneNumber.empty,
          address: Address.empty,
          email: null,
        ),
        transportations: [Transportation.none],
        visitFrequencies: 'Toutes les semaines',
      );

      expect(internship.nbVersions, 2);
      expect(
        internship.creationDate.millisecondsSinceEpoch,
        DateTime(2020, 2, 4).millisecondsSinceEpoch,
      );
      expect(internship.creationDateFrom(1), internship.creationDate);
      expect(internship.supervisor.toString(), 'New Supervisor');
      expect(internship.supervisorFrom(1), internship.supervisor);
      expect(
        internship.dates.start.millisecondsSinceEpoch,
        DateTime(2000, 1, 1).millisecondsSinceEpoch,
      );
      expect(
        internship.dates.end.millisecondsSinceEpoch,
        DateTime(2001, 1, 1).millisecondsSinceEpoch,
      );
      expect(internship.dateFrom(1), internship.dates);
      expect(internship.weeklySchedules.length, 1);
      expect(internship.weeklySchedules[0].id, 'newWeeklyScheduleId');
      expect(internship.weeklySchedulesFrom(1), internship.weeklySchedules);
    });

    testWidgets('can add and remove supervisors', (tester) async {
      final context = await tester.contextWithNotifiers(
        withTeachers: true,
        withStudents: true,
        withInternships: true,
      );
      final auth = AuthProvider(mockMe: true);
      final teachers = TeachersProvider.of(context, listen: false);
      teachers.initializeAuth(auth);
      teachers.add(dummyTeacher(id: 'extraTeacherId'));
      final students = StudentsProvider.of(context, listen: false);
      students.initializeAuth(auth);
      students.add(dummyStudent());

      Internship internship = dummyInternship();
      InternshipsProvider.of(context, listen: false).add(internship);
      expect(
        internship.id,
        InternshipsProvider.of(context, listen: false)[0].id,
      );

      expect(internship.supervisingTeacherIds.length, 1);
      expect(internship.supervisingTeacherIds, ['teacherId']);

      InternshipsProvider.of(context, listen: false).replace(
        internship.copyWithTeacher(context, teacherId: 'extraTeacherId'),
      );
      internship = InternshipsProvider.of(context, listen: false)[0];
      expect(internship.supervisingTeacherIds.length, 2);
      expect(internship.supervisingTeacherIds, ['teacherId', 'extraTeacherId']);

      InternshipsProvider.of(context, listen: false).replace(
        internship.copyWithoutTeacher(context, teacherId: 'extraTeacherId'),
      );
      internship = InternshipsProvider.of(context, listen: false)[0];

      expect(internship.supervisingTeacherIds.length, 1);
      expect(internship.supervisingTeacherIds, ['teacherId']);

      // Prevent from adding a teacher which is not related to a group
      teachers.add(dummyTeacher(id: 'bannedTeacher', groups: ['103']));
      expect(
        () => internship.copyWithTeacher(context, teacherId: 'bannedTeacher'),
        throwsException,
      );
      expect(internship.supervisingTeacherIds.length, 1);
      expect(internship.supervisingTeacherIds, ['teacherId']);
    });

    test('"copyWith" behaves properly', () {
      final internship = dummyInternship();

      final internshipSame = internship.copyWith();
      expect(internshipSame.id, internship.id);
      expect(internshipSame.studentId, internship.studentId);
      expect(internshipSame.signatoryTeacherId, internship.signatoryTeacherId);
      expect(
        internshipSame.supervisingTeacherIds,
        internship.supervisingTeacherIds,
      );
      expect(internshipSame.enterpriseId, internship.enterpriseId);
      expect(internshipSame.jobId, internship.jobId);
      expect(internshipSame.nbVersions, internship.nbVersions);
      expect(
        internshipSame.creationDate.toString(),
        internship.creationDate.toString(),
      );
      expect(
        internshipSame.supervisor.toString(),
        internship.supervisor.toString(),
      );
      expect(internshipSame.dates.toString(), internship.dates.toString());
      expect(
        internshipSame.weeklySchedules.length,
        internship.weeklySchedules.length,
      );
      expect(internshipSame.expectedDuration, internship.expectedDuration);
      expect(internshipSame.achievedDuration, internship.achievedDuration);
      expect(internshipSame.teacherNotes, internship.teacherNotes);
      expect(internshipSame.endDate, internship.endDate);
      expect(
        internshipSame.skillEvaluations.length,
        internship.skillEvaluations.length,
      );
      expect(
        internshipSame.attitudeEvaluations.length,
        internship.attitudeEvaluations.length,
      );
      expect(
        internshipSame.enterpriseEvaluation!.id,
        internship.enterpriseEvaluation!.id,
      );

      final internshipDifferent = internship.copyWith(
        id: 'newId',
        studentId: 'newStudentId',
        signatoryTeacherId: 'newTeacherId',
        extraSupervisingTeacherIds: ['newExtraTeacherId'],
        enterpriseId: 'newEnterpriseId',
        jobId: 'newJobId',
        extraSpecializationIds: ['newSpecializationId'],
        expectedDuration: 135,
        achievedDuration: 130,
        teacherNotes: 'newTeacherNotes',
        endDate: DateTime(2020, 2, 4),
        skillEvaluations: [
          dummyInternshipEvaluationSkill(id: 'newSkillEvaluationId'),
          dummyInternshipEvaluationSkill(id: 'newSkillEvaluationId2'),
        ],
        attitudeEvaluations: [
          dummyInternshipEvaluationAttitude(id: 'newAttitudeEvaluationId'),
          dummyInternshipEvaluationAttitude(id: 'newAttitudeEvaluationId2'),
        ],
        enterpriseEvaluation: dummyPostInternshipEnterpriseEvaluation(
          id: 'newEnterpriseEvaluationId',
        ),
      );

      expect(internshipDifferent.id, 'newId');
      expect(internshipDifferent.studentId, 'newStudentId');
      expect(internshipDifferent.signatoryTeacherId, 'newTeacherId');
      expect(internshipDifferent.supervisingTeacherIds, [
        'newTeacherId',
        'newExtraTeacherId',
      ]);
      expect(internshipDifferent.enterpriseId, 'newEnterpriseId');
      expect(internshipDifferent.jobId, 'newJobId');
      expect(internshipDifferent.expectedDuration, 135);
      expect(internshipDifferent.achievedDuration, 130);
      expect(internshipDifferent.teacherNotes, 'newTeacherNotes');
      expect(internshipDifferent.endDate, DateTime(2020, 2, 4));
      expect(internshipDifferent.skillEvaluations.length, 2);
      expect(
        internshipDifferent.skillEvaluations[0].id,
        'newSkillEvaluationId',
      );
      expect(
        internshipDifferent.skillEvaluations[1].id,
        'newSkillEvaluationId2',
      );
      expect(internshipDifferent.attitudeEvaluations.length, 2);
      expect(
        internshipDifferent.attitudeEvaluations[0].id,
        'newAttitudeEvaluationId',
      );
      expect(
        internshipDifferent.attitudeEvaluations[1].id,
        'newAttitudeEvaluationId2',
      );
      expect(
        internshipDifferent.enterpriseEvaluation!.id,
        'newEnterpriseEvaluationId',
      );
    });

    test('"Internship" serialization and deserialization works', () {
      final internship = dummyInternship(hasEndDate: true);
      final serialized = internship.serialize();
      final deserialized = Internship.fromSerialized(serialized);

      final period = DateTimeRange(
        start: DateTime(2005, 10, 31),
        end: DateTime(2005, 10, 31).add(const Duration(days: 20)),
      );

      final expected = {
        'id': 'internshipId',
        'version': Internship.currentVersion,
        'school_board_id': 'schoolBoardId',
        'student_id': 'studentId',
        'signatory_teacher_id': 'teacherId',
        'extra_supervising_teacher_ids': [],
        'enterprise_id': 'enterpriseId',
        'job_id': 'jobId',
        'extra_specialization_ids': ['8168', '8134'],
        'mutables': [
          {
            'id': serialized['mutables'][0]['id'],
            'creation_date': internship.creationDate.millisecondsSinceEpoch,
            'supervisor': internship.supervisor.serialize(),
            'starting_date': internship.dates.start.millisecondsSinceEpoch,
            'ending_date': internship.dates.end.millisecondsSinceEpoch,
            'schedules': [dummyWeeklySchedule(period: period).serialize()],
            'transportations': [Transportation.none.serialize()],
            'visit_frequencies': 'Tous les jours',
          },
        ],
        'expected_duration': 135,
        'achieved_duration': 130,
        'teacher_notes': '',
        'end_date': DateTime(2034, 10, 28).millisecondsSinceEpoch,
        'skill_evaluations': [dummyInternshipEvaluationSkill().serialize()],
        'attitude_evaluations': [
          dummyInternshipEvaluationAttitude().serialize(),
        ],
        'enterprise_evaluation':
            dummyPostInternshipEnterpriseEvaluation().serialize(),
        'visa_evaluations': [dummyInternshipVisaEvaluation().serialize()],
      };
      expect(serialized, expected);

      expect(deserialized.id, 'internshipId');
      expect(deserialized.studentId, 'studentId');
      expect(deserialized.signatoryTeacherId, 'teacherId');
      expect(deserialized.supervisingTeacherIds, ['teacherId']);
      expect(deserialized.enterpriseId, 'enterpriseId');
      expect(deserialized.jobId, 'jobId');
      expect(deserialized.nbVersions, 1);
      expect(
        deserialized.creationDate.toString(),
        internship.creationDate.toString(),
      );
      expect(
        deserialized.supervisor.toString(),
        internship.supervisor.toString(),
      );
      expect(deserialized.dates.toString(), internship.dates.toString());
      expect(deserialized.weeklySchedules.length, 1);
      expect(
        deserialized.weeklySchedules[0].id,
        internship.weeklySchedules[0].id,
      );
      expect(deserialized.expectedDuration, 135);
      expect(deserialized.achievedDuration, 130);
      expect(deserialized.teacherNotes, '');
      expect(
        deserialized.endDate.millisecondsSinceEpoch,
        internship.endDate.millisecondsSinceEpoch,
      );
      expect(deserialized.skillEvaluations.length, 1);
      expect(
        deserialized.skillEvaluations[0].id,
        internship.skillEvaluations[0].id,
      );
      expect(deserialized.attitudeEvaluations.length, 1);
      expect(
        deserialized.attitudeEvaluations[0].id,
        internship.attitudeEvaluations[0].id,
      );
      expect(
        deserialized.enterpriseEvaluation!.id,
        internship.enterpriseEvaluation!.id,
      );
      expect(
        deserialized.visaEvaluations[0].id,
        internship.visaEvaluations[0].id,
      );

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = Internship.fromSerialized({'id': 'emptyId'});
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.studentId, '');
      expect(emptyDeserialized.signatoryTeacherId, '');
      expect(emptyDeserialized.supervisingTeacherIds, ['']);
      expect(emptyDeserialized.enterpriseId, '');
      expect(emptyDeserialized.jobId, '');
      expect(emptyDeserialized.nbVersions, 0);
      expect(emptyDeserialized.expectedDuration, -1);
      expect(emptyDeserialized.achievedDuration, -1);
      expect(emptyDeserialized.teacherNotes, '');
      expect(emptyDeserialized.endDate, DateTime(0));
      expect(emptyDeserialized.skillEvaluations.length, 0);
      expect(emptyDeserialized.attitudeEvaluations.length, 0);
      expect(emptyDeserialized.enterpriseEvaluation, isNull);
      expect(emptyDeserialized.visaEvaluations.length, 0);

      expect(() => emptyDeserialized.dates, throwsStateError);
      expect(() => emptyDeserialized.weeklySchedules, throwsStateError);
      expect(() => emptyDeserialized.supervisor, throwsStateError);
    });
  });
}
