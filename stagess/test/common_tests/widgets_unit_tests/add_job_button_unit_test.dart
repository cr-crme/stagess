import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/add_job_button.dart';

import 'utils.dart';

void main() {
  group('AddJobButton', () {
    testWidgets('renders a button with an icon and a text', (tester) async {
      await tester.pumpWidget(
          declareWidget(AddJobButton(controllers: [], onJobAdded: () {})));

      expect(find.byIcon(Icons.business_center_rounded), findsOneWidget);
      expect(find.text('Ajouter un métier'), findsOneWidget);
    });

    testWidgets('renders a button with a custom style', (tester) async {
      await tester.pumpWidget(declareWidget(AddJobButton(
        controllers: [],
        onJobAdded: () {},
        style: TextButton.styleFrom(backgroundColor: Colors.red),
      )));

      final button = tester.widget<TextButton>(find.bySubtype<TextButton>());
      expect(button.style!.backgroundColor!.resolve({}), Colors.red);
    });

    testWidgets('renders a button with a custom onPressed callback',
        (tester) async {
      bool wasClicked = false;
      await tester.pumpWidget(declareWidget(AddJobButton(
        controllers: [],
        onJobAdded: () {
          wasClicked = true;
        },
      )));

      await tester.tap(find.bySubtype<TextButton>());
      await tester.pumpAndSettle();
      expect(wasClicked, isTrue);
    });
  });
}
