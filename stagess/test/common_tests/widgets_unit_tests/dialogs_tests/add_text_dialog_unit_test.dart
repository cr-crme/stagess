import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/dialogs/add_text_dialog.dart';

import '../utils.dart';

void main() {
  group('AddTextDialog', () {
    testWidgets('renders a title', (tester) async {
      await tester
          .pumpWidget(declareWidget(const AddTextDialog(title: 'My title')));

      expect(find.text('My title'), findsOneWidget);
    });

    testWidgets('renders a text zone', (tester) async {
      await tester
          .pumpWidget(declareWidget(const AddTextDialog(title: 'My title')));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should display a cancel button', (tester) async {
      await tester
          .pumpWidget(declareWidget(const AddTextDialog(title: 'My title')));

      final cancelFinder = find.byType(OutlinedButton);
      expect(find.byType(OutlinedButton), findsOneWidget);

      final textFinder =
          find.descendant(of: cancelFinder, matching: find.byType(Text));
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.data, 'Annuler');
    });

    testWidgets('should display a confirm button', (tester) async {
      await tester
          .pumpWidget(declareWidget(const AddTextDialog(title: 'My title')));

      final confirmFinder = find.byType(TextButton);
      expect(confirmFinder, findsOneWidget);

      final textFinder =
          find.descendant(of: confirmFinder, matching: find.byType(Text));
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.data, 'Ajouter');
    });

    testWidgets('can cancel', (tester) async {
      await tester
          .pumpWidget(declareWidget(const AddTextDialog(title: 'My title')));

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // The dialog should be closed
      expect(find.byType(AddTextDialog), findsNothing);
    });

    testWidgets('confirming is refused if no description is entered',
        (tester) async {
      await tester
          .pumpWidget(declareWidget(const AddTextDialog(title: 'My title')));

      await tester.tap(find.text('Ajouter'));
      await tester.pump();

      // The dialog should still be open
      expect(find.byType(AddTextDialog), findsOneWidget);

      // An error message should be displayed
      expect(find.text('Le champ ne peut pas être vide.'), findsOneWidget);
    });

    testWidgets('confirming is accepted if a description is entered',
        (tester) async {
      await tester
          .pumpWidget(declareWidget(const AddTextDialog(title: 'My title')));

      await tester.enterText(find.byType(TextFormField), 'Test description');
      await tester.pump();

      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

      // The dialog should be closed
      expect(find.byType(AddTextDialog), findsNothing);
    });
  });
}
