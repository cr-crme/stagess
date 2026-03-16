import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/extensions/internship_extension.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common/models/internships/internship.dart';
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
      expect(
        internshipSame.currentContract!.date.toString(),
        internship.currentContract!.date.toString(),
      );
      expect(internshipSame.currentContract!.specializationId,
          internship.currentContract!.specializationId);
      expect(internshipSame.currentContract!.extraSpecializationIds,
          internship.currentContract!.extraSpecializationIds);
      expect(
        internshipSame.currentContract!.supervisor.toString(),
        internship.currentContract!.supervisor.toString(),
      );
      expect(internshipSame.currentContract!.dates.toString(),
          internship.currentContract!.dates.toString());
      expect(
        internshipSame.currentContract!.weeklySchedules.length,
        internship.currentContract!.weeklySchedules.length,
      );
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
      expect(internshipSame.sstEvaluations.length,
          internship.sstEvaluations.length);
      expect(
        internshipSame.enterpriseEvaluations.length,
        internship.enterpriseEvaluations.length,
      );

      final internshipDifferent = internship.copyWith(
        id: 'newId',
        studentId: 'newStudentId',
        signatoryTeacherId: 'newTeacherId',
        extraSupervisingTeacherIds: ['newExtraTeacherId'],
        enterpriseId: 'newEnterpriseId',
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
        sstEvaluations: [
          dummySstEvaluation(id: 'newSstEvaluationId'),
          dummySstEvaluation(id: 'newSstEvaluationId2'),
        ],
        enterpriseEvaluations: [
          dummyPostInternshipEnterpriseEvaluation(
              id: 'newEnterpriseEvaluationId'),
          dummyPostInternshipEnterpriseEvaluation(
              id: 'newEnterpriseEvaluationId2'),
        ],
      );

      expect(internshipDifferent.id, 'newId');
      expect(internshipDifferent.studentId, 'newStudentId');
      expect(internshipDifferent.signatoryTeacherId, 'newTeacherId');
      expect(internshipDifferent.supervisingTeacherIds, [
        'newTeacherId',
        'newExtraTeacherId',
      ]);
      expect(internshipDifferent.enterpriseId, 'newEnterpriseId');
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
      expect(internshipDifferent.sstEvaluations[0].id, 'newSstEvaluationId');
      expect(internshipDifferent.sstEvaluations[1].id, 'newSstEvaluationId2');
      expect(internshipDifferent.enterpriseEvaluations[0].id,
          'newEnterpriseEvaluationId');
      expect(internshipDifferent.enterpriseEvaluations[1].id,
          'newEnterpriseEvaluationId2');
    });

    test('"Internship" serialization and deserialization works', () {
      final internship = dummyInternship(hasEndDate: true);
      final serialized = internship.serialize();
      final deserialized = Internship.fromSerialized(serialized);

      final expected = {
        'id': 'internshipId',
        'version': Internship.currentVersion,
        'school_board_id': 'schoolBoardId',
        'student_id': 'studentId',
        'signatory_teacher_id': 'teacherId',
        'extra_supervising_teacher_ids': [],
        'enterprise_id': 'enterpriseId',
        'contracts': [dummyInternshipContract().serialize()],
        'expected_duration': 135,
        'achieved_duration': 130,
        'teacher_notes': '',
        'end_date': DateTime(2034, 10, 28).millisecondsSinceEpoch,
        'skill_evaluations': [dummyInternshipEvaluationSkill().serialize()],
        'attitude_evaluations': [
          dummyInternshipEvaluationAttitude().serialize(),
        ],
        'sst_evaluations': [dummySstEvaluation().serialize()],
        'enterprise_evaluations': [
          dummyPostInternshipEnterpriseEvaluation().serialize()
        ],
      };
      expect(serialized, expected);

      expect(deserialized.id, 'internshipId');
      expect(deserialized.studentId, 'studentId');
      expect(deserialized.signatoryTeacherId, 'teacherId');
      expect(deserialized.supervisingTeacherIds, ['teacherId']);
      expect(deserialized.enterpriseId, 'enterpriseId');
      expect(
        deserialized.currentContract!.date.toString(),
        internship.currentContract!.date.toString(),
      );
      expect(
        deserialized.currentContract!.supervisor.toString(),
        internship.currentContract!.supervisor.toString(),
      );
      expect(deserialized.currentContract!.dates.toString(),
          internship.currentContract!.dates.toString());
      expect(deserialized.currentContract!.weeklySchedules.length, 1);
      expect(
        deserialized.currentContract!.weeklySchedules[0].id,
        internship.currentContract!.weeklySchedules[0].id,
      );
      expect(deserialized.currentContract!.expectedDuration, 135);
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
          deserialized.sstEvaluations[0].id, internship.sstEvaluations[0].id);
      expect(
        deserialized.enterpriseEvaluations[0].id,
        internship.enterpriseEvaluations[0].id,
      );

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = Internship.fromSerialized({'id': 'emptyId'});
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.studentId, '');
      expect(emptyDeserialized.signatoryTeacherId, '');
      expect(emptyDeserialized.supervisingTeacherIds, ['']);
      expect(emptyDeserialized.enterpriseId, '');
      expect(emptyDeserialized.achievedDuration, -1);
      expect(emptyDeserialized.teacherNotes, '');
      expect(emptyDeserialized.endDate, DateTime(0));
      expect(emptyDeserialized.skillEvaluations.length, 0);
      expect(emptyDeserialized.attitudeEvaluations.length, 0);
      expect(emptyDeserialized.sstEvaluations[0].id, isNotNull);
      expect(emptyDeserialized.enterpriseEvaluations.length, 0);

      expect(() => emptyDeserialized.currentContract!.dates, throwsStateError);
      expect(() => emptyDeserialized.currentContract!.weeklySchedules,
          throwsStateError);
      expect(() => emptyDeserialized.currentContract!.supervisor,
          throwsStateError);
      expect(emptyDeserialized.currentContract!.expectedDuration, -1);
    });
  });
}
