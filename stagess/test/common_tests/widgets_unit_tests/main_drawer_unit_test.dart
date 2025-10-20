import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/program_helpers.dart';

import '../../utils.dart';
import 'utils.dart';

Future<void> _initializedDrawer(WidgetTester tester) async {
  await tester.pumpWidgetWithNotifiers(
    declareWidget(const MainDrawer()),
    withInternships: true,
    withEnterprises: true,
    withAuthentication: true,
    withTeachers: true,
    withStudents: true,
  );
}

void main() {
  group('MainDrawer', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    testWidgets('renders the proper title', (tester) async {
      await _initializedDrawer(tester);

      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets('The drawer tiles content', (WidgetTester tester) async {
      await _initializedDrawer(tester);

      // Verify that the drawer contains the expected tiles
      for (final screenName in ScreenTest.values) {
        expect(
          find.ancestor(
            of: find.text(screenName.name),
            matching: find.byType(Card),
          ),
          findsWidgets,
        );
      }
    });
  });
}
