import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';

import '../../utils.dart';

void main() {
  group('AuthProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    test('can sign in and out', () async {
      final authProvider = AuthProvider(
        mockMe: true,
        automaticallySignInIfMocked: false,
      );
      expect(authProvider.isFullySignedIn, isFalse);

      authProvider.signInWithEmailAndPassword(
        email: 'my.email@test.ca',
        password: 'no password',
      );
      expect(authProvider.isAuthenticatorSignedIn, isTrue);
      expect(authProvider.currentUser?.uid, 'Mock User');

      expect(authProvider.databaseAccessLevel, AccessLevel.invalid);
      expect(authProvider.schoolBoardId, isNull);
      expect(authProvider.schoolId, isNull);
      expect(authProvider.teacherId, isNull);
      expect(authProvider.isFullySignedIn, isFalse);

      authProvider.teacherId = 'teacherId';
      authProvider.schoolId = 'schoolId';
      authProvider.schoolBoardId = 'schoolBoardId';
      expect(authProvider.schoolBoardId, 'schoolBoardId');
      expect(authProvider.schoolId, 'schoolId');
      expect(authProvider.teacherId, 'teacherId');
      expect(authProvider.isFullySignedIn, isTrue);

      await authProvider.signOut();
      expect(authProvider.isFullySignedIn, isFalse);
      expect(authProvider.currentUser?.uid, isNull);
      expect(authProvider.databaseAccessLevel, AccessLevel.invalid);
      expect(authProvider.schoolBoardId, isNull);
      expect(authProvider.schoolId, isNull);
      expect(authProvider.teacherId, isNull);
    });

    testWidgets('can get "of" context', (tester) async {
      final context = await tester.contextWithNotifiers(
        withAuthentication: true,
      );

      final authProvider = AuthProvider.of(context);
      expect(authProvider.isFullySignedIn, isTrue);
    });
  });
}
