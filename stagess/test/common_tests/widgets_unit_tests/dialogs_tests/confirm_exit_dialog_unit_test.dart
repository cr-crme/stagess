import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';

import '../utils.dart';

void main() {
  group('ConfirmExitDialog', () {
    testWidgets('renders a title', (tester) async {
      await tester.pumpWidget(
        declareWidget(const ConfirmExitDialog(content: Text('My content'))),
      );

      expect(find.text('Voulez-vous quitter?'), findsOneWidget);
    });

    testWidgets('renders a content', (tester) async {
      await tester.pumpWidget(
        declareWidget(const ConfirmExitDialog(content: Text('My content'))),
      );

      expect(find.text('My content'), findsOneWidget);
    });

    testWidgets('should display a cancel button', (tester) async {
      await tester.pumpWidget(
        declareWidget(const ConfirmExitDialog(content: Text('My content'))),
      );

      final cancelFinder = find.byType(OutlinedButton);
      expect(find.byType(OutlinedButton), findsOneWidget);

      final textFinder = find.descendant(
        of: cancelFinder,
        matching: find.byType(Text),
      );
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.data, 'Non');
    });

    testWidgets('should display a confirm button', (tester) async {
      await tester.pumpWidget(
        declareWidget(const ConfirmExitDialog(content: Text('My content'))),
      );

      final confirmFinder = find.byType(TextButton);
      expect(confirmFinder, findsOneWidget);

      final textFinder = find.descendant(
        of: confirmFinder,
        matching: find.byType(Text),
      );
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.data, 'Quitter');
    });

    testWidgets('can cancel', (tester) async {
      await tester.pumpWidget(
        declareWidget(const ConfirmExitDialog(content: Text('My content'))),
      );

      await tester.tap(find.text('Non'));
      await tester.pumpAndSettle();

      // The dialog should be closed
      expect(find.byType(ConfirmExitDialog), findsNothing);
    });

    testWidgets('can confirm', (tester) async {
      await tester.pumpWidget(
        declareWidget(const ConfirmExitDialog(content: Text('My content'))),
      );

      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();

      // The dialog should be closed
      expect(find.byType(ConfirmExitDialog), findsNothing);
    });
  });
}
