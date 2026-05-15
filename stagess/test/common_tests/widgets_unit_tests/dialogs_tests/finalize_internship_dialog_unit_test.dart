import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/helpers/program_helpers.dart';
import 'package:stagess_common_flutter/widgets/dialogs/finalize_internship_dialog.dart';

import '../../../utils.dart';
import '../../utils.dart';
import '../utils.dart';

void main() {
  group('FinalizeInternshipDialog', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize();

    testWidgets('renders a title', (tester) async {
      await tester.pumpWidgetWithNotifiers(
          const FinalizeInternshipDialog(internshipId: 'internshipId'),
          withInternships: true,
          dummyInternship: dummyInternship());

      expect(find.text('Mettre fin au stage?'), findsOneWidget);
    });

    testWidgets('renders a text zone', (tester) async {
      await tester.pumpWidgetWithNotifiers(
          const FinalizeInternshipDialog(internshipId: 'internshipId'),
          withInternships: true,
          dummyInternship: dummyInternship());

      expect(find.text('Nombre d\'heures de stage faites'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('h'), findsOneWidget);
    });

    testWidgets('text zone has 0 as default if no achievedLength exists',
        (tester) async {
      await tester.pumpWidgetWithNotifiers(
          const FinalizeInternshipDialog(internshipId: 'internshipId'),
          withInternships: true,
          dummyInternship: dummyInternship(achievedLength: -1));

      final textFormField =
          tester.widget<TextFormField>(find.byType(TextFormField));

      expect(textFormField.initialValue, '0');
    });

    testWidgets('text zone has achievedLength as default value if exists',
        (tester) async {
      await tester.pumpWidgetWithNotifiers(
          const FinalizeInternshipDialog(internshipId: 'internshipId'),
          withInternships: true,
          dummyInternship: dummyInternship(achievedLength: 100));

      final textFormField =
          tester.widget<TextFormField>(find.byType(TextFormField));

      expect(textFormField.initialValue, '100');
    });

    testWidgets('should display a cancel button', (tester) async {
      await tester.pumpWidgetWithNotifiers(
          const FinalizeInternshipDialog(internshipId: 'internshipId'),
          withInternships: true,
          dummyInternship: dummyInternship());

      final cancelFinder = find.byType(OutlinedButton);
      expect(find.byType(OutlinedButton), findsOneWidget);

      final textFinder =
          find.descendant(of: cancelFinder, matching: find.byType(Text));
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.data, 'Non');
    });

    testWidgets('should display a confirm button', (tester) async {
      await tester.pumpWidgetWithNotifiers(
          const FinalizeInternshipDialog(internshipId: 'internshipId'),
          withInternships: true,
          dummyInternship: dummyInternship());

      final confirmFinder = find.byType(TextButton);
      expect(confirmFinder, findsOneWidget);

      final textFinder =
          find.descendant(of: confirmFinder, matching: find.byType(Text));
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.data, 'Oui');
    });

    testWidgets('can cancel', (tester) async {
      await tester.pumpWidgetWithNotifiers(
          declareWidget(
              const FinalizeInternshipDialog(internshipId: 'internshipId')),
          withInternships: true,
          dummyInternship: dummyInternship());

      await tester.tap(find.text('Non'));
      await tester.pumpAndSettle();

      // The dialog should be closed
      expect(find.byType(FinalizeInternshipDialog), findsNothing);
    });

    testWidgets('confirming is refused if no time is entered', (tester) async {
      await tester.pumpWidgetWithNotifiers(
          declareWidget(
              const FinalizeInternshipDialog(internshipId: 'internshipId')),
          withInternships: true,
          dummyInternship: dummyInternship(achievedLength: -1));

      await tester.tap(find.text('Oui'));
      await tester.pumpAndSettle();

      // The dialog should still be open
      expect(find.byType(FinalizeInternshipDialog), findsOneWidget);

      // An error message should be displayed
      expect(find.text('Entrer une valeur'), findsOneWidget);
    });

    testWidgets('Cannot enter non integer values', (tester) async {
      await tester.pumpWidgetWithNotifiers(
          declareWidget(
              const FinalizeInternshipDialog(internshipId: 'internshipId')),
          withInternships: true,
          dummyInternship: dummyInternship(achievedLength: -1));

      final textFormField = find.byType(TextFormField);
      await tester.enterText(textFormField, '100.1');
      await tester.pump();
      expect(
          tester.widget<TextFormField>(textFormField).controller!.text, '1001');

      await tester.enterText(textFormField, '-1');
      await tester.pump();
      expect(tester.widget<TextFormField>(textFormField).controller!.text, '1');
    });

    testWidgets('confirming is accepted if a valid time is entered',
        (tester) async {
      await tester.pumpWidgetWithNotifiers(
          declareWidget(
              const FinalizeInternshipDialog(internshipId: 'internshipId')),
          withInternships: true,
          dummyInternship: dummyInternship(achievedLength: -1));

      await tester.enterText(find.byType(TextFormField), '100');
      await tester.pump();

      await tester.tap(find.text('Oui'));
      await tester.pumpAndSettle();

      // The dialog should still be open
      expect(find.byType(FinalizeInternshipDialog), findsNothing);
    });
  });
}
