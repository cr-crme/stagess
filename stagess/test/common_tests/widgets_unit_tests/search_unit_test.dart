import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/search.dart';

import 'utils.dart';

void main() {
  group('Search', () {
    testWidgets('renders a title', (tester) async {
      await tester.pumpWidget(declareWidget(Search(
        controller: TextEditingController(),
      )));

      expect(find.text('Rechercher'), findsOneWidget);
    });

    testWidgets('renders a search icon', (tester) async {
      await tester.pumpWidget(declareWidget(Search(
        controller: TextEditingController(),
      )));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders a clear icon', (tester) async {
      await tester.pumpWidget(declareWidget(Search(
        controller: TextEditingController(),
      )));

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('typing text is reflected in the controller', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(declareWidget(Search(
        controller: controller,
      )));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(controller.text, 'test');
    });

    testWidgets('tapping clear removes the text', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(declareWidget(Search(
        controller: controller,
      )));

      controller.text = 'test';
      expect(controller.text, 'test');

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(controller.text, '');
    });

    testWidgets('the preferred height is 72 points', (tester) async {
      await tester.pumpWidget(declareWidget(Search(
        controller: TextEditingController(),
      )));

      expect(
          tester.widget<Search>(find.byType(Search)).preferredSize.height, 72);
    });
  });
}
