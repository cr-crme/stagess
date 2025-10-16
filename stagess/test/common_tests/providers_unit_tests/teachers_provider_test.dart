import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:uuid/uuid.dart';

import '../../utils.dart';
import '../utils.dart';

void main() {
  group('TeachersProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    test('"currentTeacherId" works', () {
      final teachers = TeachersProvider(
        uri: Uri.parse('ws://localhost'),
        mockMe: true,
      );
      expect(() => teachers.currentTeacher?.id, throwsException);

      teachers.initializeAuth(AuthProvider(mockMe: true));
      var uuid = Uuid();
      final namespace = UuidValue.fromNamespace(Namespace.dns);
      final teacherId = uuid.v5(namespace.toString(), 'Mock User');
      expect(teachers.currentTeacher?.id, teacherId);
    });

    test('"getCurrentTeacher" works', () {
      final teachers = TeachersProvider(
        uri: Uri.parse('ws://localhost'),
        mockMe: true,
      );
      expect(teachers.currentTeacher?.firstName, 'Error');

      final auth = AuthProvider(mockMe: true);
      teachers.initializeAuth(auth);
      teachers.add(dummyTeacher());
      expect(teachers.currentTeacher?.firstName, 'Error');

      teachers.add(
        dummyTeacher(id: teachers.currentTeacher?.id ?? 'FailedToGetId'),
      );
      expect(teachers.currentTeacher?.firstName, 'Pierre');
    });

    test('"deserializeItem" works', () {
      final teachers = TeachersProvider(
        uri: Uri.parse('ws://localhost'),
        mockMe: true,
      );
      final teacher = teachers.deserializeItem(dummyTeacher().serialize());

      expect(teacher.firstName, 'Pierre');
      expect(teacher.middleName, 'Jean');
      expect(teacher.lastName, 'Jacques');
      expect(teacher.schoolBoardId, 'school_board_id');
      expect(teacher.schoolId, 'school_id');
      expect(teacher.email, 'peter.john.jakob@test.com');
      expect(teacher.groups, ['101', '102']);
    });

    testWidgets('can get "of" context', (tester) async {
      final context = await tester.contextWithNotifiers(withTeachers: true);
      final teachers = TeachersProvider.of(context, listen: false);
      expect(teachers, isNotNull);
    });
  });
}
