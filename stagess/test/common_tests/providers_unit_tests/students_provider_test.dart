import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/extensions/internship_extension.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

import '../../utils.dart';
import '../utils.dart';

void _prepareProviders(BuildContext context) {
  final auth = AuthProvider(mockMe: true);
  final teachers = TeachersProvider.of(context, listen: false);
  teachers.initializeAuth(auth);
  teachers.add(
    dummyTeacher(id: teachers.currentTeacher?.id ?? 'FailedToGetId'),
  );
  final students = StudentsProvider.of(context, listen: false);
  students.initializeAuth(auth);
}

void main() {
  group('StudentsProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    testWidgets('"studentsInMyGroups" works', (tester) async {
      // Prepare the StudentsProvider
      final context = await tester.contextWithNotifiers(
        withStudents: true,
        withTeachers: true,
      );
      _prepareProviders(context);

      // Add random students (my groups are 101 and 102)
      final students = StudentsProvider.of(context, listen: false);
      students.add(dummyStudent(group: '101'));
      students.add(dummyStudent(group: '101'));
      students.add(dummyStudent(group: '102'));
      students.add(dummyStudent(group: '103'));

      expect(
        StudentsHelpers.studentsInMyGroups(context, listen: false).length,
        3,
      );
    });

    testWidgets('"mySupervizedStudents" works', (tester) async {
      // Prepare the StudentsProvider
      final context = await tester.contextWithNotifiers(
        withStudents: true,
        withTeachers: true,
        withInternships: true,
      );
      _prepareProviders(context);

      final students = StudentsProvider.of(context, listen: false);
      students.add(dummyStudent(id: 'myStudent1', group: '101'));
      students.add(dummyStudent(id: 'myStudent2', group: '101'));
      students.add(dummyStudent(id: 'myStudent3', group: '102'));
      students.add(dummyStudent(id: 'notYetMyStudent', group: '101'));
      students.add(dummyStudent(id: 'neverMyStudent1', group: '102'));
      students.add(dummyStudent(id: 'neverMyStudent2', group: '103'));

      expect(
        StudentsHelpers.mySupervizedStudents(context, listen: false).length,
        0,
      );

      // Add internship to all of the students
      final internships = InternshipsProvider.of(context, listen: false);
      final teacherId =
          TeachersProvider.of(context).currentTeacher?.id ?? 'FailedToGetId';
      for (int i = 0; i < students.length; i++) {
        final student = students[i];
        internships.add(
          dummyInternship(
            id: 'internshipId$i',
            studentId: student.id,
            teacherId: i >= 3 ? 'anotherTeacherId' : teacherId,
          ),
        );
      }
      expect(
        StudentsHelpers.mySupervizedStudents(context, listen: false).length,
        3,
      );

      // Add the fourth student to the supervising list of the teacher
      internships
          .firstWhere((e) => e.studentId == 'notYetMyStudent')
          .copyWithTeacher(
            context,
            teacherId:
                TeachersProvider.of(context).currentTeacher?.id ??
                'FailedToGetId',
          );
      expect(
        StudentsHelpers.mySupervizedStudents(context, listen: false).length,
        4,
      );

      // Terminate one of the internships
      final internship = internships
          .firstWhere((e) => e.studentId == 'myStudent1')
          .copyWith(endDate: DateTime(0));
      internships.replace(internship);
      expect(
        StudentsHelpers.mySupervizedStudents(
          context,
          listen: false,
          activeOnly: false,
        ).length,
        4,
      );
      expect(
        StudentsHelpers.mySupervizedStudents(
          context,
          listen: false,
          activeOnly: true,
        ).length,
        3,
      );

      // Try to add a student that is not on the right group
      expect(
        () => internships
            .firstWhere((e) => e.studentId == 'neverMyStudent2')
            .copyWithTeacher(
              context,
              teacherId:
                  TeachersProvider.of(context).currentTeacher?.id ??
                  'FailedToGetId',
            ),
        throwsException,
      );
      expect(
        StudentsHelpers.mySupervizedStudents(context, listen: false).length,
        4,
      );
    });

    test('deserializeItem works', () {
      final students = StudentsProvider(
        uri: Uri.parse('ws://localhost'),
        mockMe: true,
      );
      final student = students.deserializeItem({
        'first_name': 'NotPierre',
        'middle_name': 'NotJean',
        'last_name': 'NotJacques',
        'group': '10101',
      });

      expect(student.firstName, 'NotPierre');
      expect(student.middleName, 'NotJean');
      expect(student.lastName, 'NotJacques');
      expect(student.group, '10101');
    });
  });
}
