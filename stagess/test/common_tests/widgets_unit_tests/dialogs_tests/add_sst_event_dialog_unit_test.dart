import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/widgets/dialogs/add_sst_event_dialog.dart';
import 'package:stagess/common/widgets/form_fields/text_with_form.dart';

import '../utils.dart';

void main() {
  group('AddSstEventDialog', () {
    testWidgets('should display the dialog', (tester) async {
      await tester.pumpWidget(declareWidget(const AddSstEventDialog()));

      expect(find.byType(AddSstEventDialog), findsOneWidget);
      expect(find.text('Signaler un incident'), findsOneWidget);
    });

    testWidgets('renders three radio boxes with text', (tester) async {
      await tester.pumpWidget(declareWidget(const AddSstEventDialog()));

      final radioFinders = find.bySubtype<RadioListTile>();
      expect(radioFinders, findsNWidgets(3));

      for (int i = 0; i < radioFinders.evaluate().length; i++) {
        final textFinder = find.descendant(
          of: radioFinders.at(i),
          matching: find.byType(Text),
        );
        expect(textFinder, findsOneWidget);
        final text = tester.widget<Text>(textFinder);
        expect(text.data, SstEventType.values[i].description);
      }
    });

    testWidgets('can only select one radio button at a time', (tester) async {
      await tester.pumpWidget(declareWidget(const AddSstEventDialog()));

      final radioFinders = find.bySubtype<RadioListTile>();
      expect(radioFinders, findsNWidgets(3));

      for (int i = 0; i < radioFinders.evaluate().length; i++) {
        await tester.tap(radioFinders.at(i));
        await tester.pump();

        for (int j = 0; j < radioFinders.evaluate().length; j++) {
          final radio = tester.widget<RadioListTile>(radioFinders.at(j));
          expect(radio.value, SstEventType.values[j]);
        }
      }
    });

    testWidgets('should display a description text field', (tester) async {
      await tester.pumpWidget(declareWidget(const AddSstEventDialog()));

      final textFinder = find.byType(TextWithForm);
      expect(textFinder, findsOneWidget);

      final text = tester.widget<TextWithForm>(textFinder);
      expect(text.title, 'Raconter ce qu\'il s\'est passé:');
    });

    testWidgets('should display a cancel button', (tester) async {
      await tester.pumpWidget(declareWidget(const AddSstEventDialog()));

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
      await tester.pumpWidget(declareWidget(const AddSstEventDialog()));

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
      await tester.pumpWidget(declareWidget(const AddSstEventDialog()));

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // The dialog should be closed
      expect(find.byType(AddSstEventDialog), findsNothing);
    });

    testWidgets('confirming is refused with snackbar if nothing is selected', (
      tester,
    ) async {
      await tester.pumpWidget(declareWidget(const AddSstEventDialog()));
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(find.text('Confirmer'));
      await tester.pump(const Duration(seconds: 1));

      // The dialog should still be open
      expect(find.byType(AddSstEventDialog), findsOneWidget);

      // A snackbar should be displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Sélectionner un type d\'incident.'), findsOneWidget);
    });

    testWidgets('confirming is refused if no description is entered', (
      tester,
    ) async {
      await tester.pumpWidget(declareWidget(const AddSstEventDialog()));

      await tester.tap(find.text(SstEventType.severe.description));
      await tester.pump();

      await tester.tap(find.text('Confirmer'));
      await tester.pump();

      // The dialog should still be open
      expect(find.byType(AddSstEventDialog), findsOneWidget);

      // An error message should be displayed
      expect(find.text('Que s\'est-il passé?'), findsOneWidget);
    });

    testWidgets(
      'confirming is accepted if a type and a description is entered',
      (tester) async {
        await tester.pumpWidget(declareWidget(const AddSstEventDialog()));

        await tester.tap(find.text(SstEventType.severe.description));
        await tester.pump();

        await tester.enterText(find.byType(TextFormField), 'Test description');
        await tester.pump();

        await tester.tap(find.text('Confirmer'));
        await tester.pumpAndSettle();

        // The dialog should be closed
        expect(find.byType(AddSstEventDialog), findsNothing);
      },
    );
  });
}
