import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

import '../../utils.dart';
import '../utils.dart';

void main() {
  group('InternshipsProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    test('"byStudentId" return the right student', () {
      final internships = InternshipsProvider(
        uri: Uri.parse('ws://localhost'),
        mockMe: true,
      );
      internships.add(dummyInternship(studentId: '123'));
      internships.add(dummyInternship(studentId: '123'));
      internships.add(dummyInternship(studentId: '456'));

      expect(internships.byStudentId('123').length, 2);
      expect(internships.byStudentId('123')[0].studentId, '123');
      expect(internships.byStudentId('123')[1].studentId, '123');
      expect(internships.byStudentId('456').length, 1);
      expect(internships.byStudentId('456')[0].studentId, '456');
      expect(internships.byStudentId('789').length, 0);
    });

    test('deserializeItem works', () {
      final internships = InternshipsProvider(
        uri: Uri.parse('ws://localhost'),
        mockMe: true,
      );
      final internship = internships.deserializeItem({
        'student_id': '123',
        'enterprise_id': '456',
        'priority': 0,
      });
      expect(internship.studentId, '123');
      expect(internship.enterpriseId, '456');
    });

    testWidgets('can get "of" context', (tester) async {
      final context = await tester.contextWithNotifiers(withInternships: true);
      final internships = InternshipsProvider.of(context, listen: false);
      expect(internships, isNotNull);
    });
  });
}
