import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/widgets/dialogs/job_creator_dialog.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';

import '../../../utils.dart';
import '../../utils.dart';

Future<void> _prepareDialog(WidgetTester tester) async {
  final enterprise = dummyEnterprise();
  return await tester.pumpWidgetWithNotifiers(
    withAuthentication: true,
    withSchools: true,
    withEnterprises: true,
    withStudents: true,
    withInternships: true,
    dummySchoolBoard: SchoolBoard(
      id: 'MockedSchoolBoardId',
      name: 'Mocked School Board',
      logo: null,
      cnesstNumber: '123456789',
      schools: [dummySchool(id: 'MockedSchoolId')],
    ),
    dummyEnterprise: enterprise,
    Scaffold(body: JobCreatorDialog(enterprise: enterprise)),
  );
}

void main() {
  group('JobCreatorDialog', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    testWidgets('renders a title', (tester) async {
      await _prepareDialog(tester);

      expect(find.text('Ajouter un nouveau poste'), findsOneWidget);
    });

    testWidgets('should display a cancel button', (tester) async {
      await _prepareDialog(tester);

      final cancelFinder = find.byType(OutlinedButton);
      expect(find.byType(OutlinedButton), findsOneWidget);

      final textFinder = find.descendant(
        of: cancelFinder,
        matching: find.byType(Text),
      );
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.data, 'Annuler');
    });

    testWidgets('should display a confirm button', (tester) async {
      await _prepareDialog(tester);

      final confirmFinder = find.byType(TextButton);
      expect(confirmFinder, findsOneWidget);

      final textFinder = find.descendant(
        of: confirmFinder,
        matching: find.byType(Text),
      );
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.data, 'Confirmer');
    });

    testWidgets('can cancel', (tester) async {
      await _prepareDialog(tester);

      // Drag the screen up to reveal the cancel button
      await tester.drag(find.byType(JobCreatorDialog), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // The dialog should be closed
      expect(find.byType(JobCreatorDialog), findsNothing);
    });

    testWidgets(
      'confirming is refused with snackbar if not all mandatory fields are filled',
      (tester) async {
        await _prepareDialog(tester);

        // Drag the screen up to reveal the cancel button
        await tester.drag(find.byType(JobCreatorDialog), const Offset(0, -500));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        // The dialog should still be open
        expect(find.byType(JobCreatorDialog), findsOneWidget);

        // A snackbar should be displayed
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );
  });
}
