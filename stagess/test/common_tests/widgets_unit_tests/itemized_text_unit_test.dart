import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/itemized_text.dart';

import 'utils.dart';

void main() {
  group('ItemizedText', () {
    testWidgets('renders a list of strings', (tester) async {
      await tester.pumpWidget(
          declareWidget(const ItemizedText(['This', 'is', 'a', 'test'])));

      expect(find.text('\u2022 '), findsNWidgets(4));
      expect(find.text('This'), findsOneWidget);
      expect(find.text('is'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('test'), findsOneWidget);

      // The default interline is 0
      final paddings = find.byType(Padding).evaluate();
      for (int i = 0; i < paddings.length; i++) {
        expect((paddings.elementAt(i).widget as Padding).padding.vertical, 0);
      }
    });

    testWidgets('can change style', (tester) async {
      await tester.pumpWidget(declareWidget(const ItemizedText(
        ['This', 'is', 'a', 'test'],
        style: TextStyle(color: Colors.red),
      )));

      for (final found in find.text('\u2022 ').evaluate()) {
        expect((found.widget as Text).style!.color, Colors.red);
      }
      expect(tester.widget<Text>(find.text('This')).style!.color, Colors.red);
      expect(tester.widget<Text>(find.text('is')).style!.color, Colors.red);
      expect(tester.widget<Text>(find.text('a')).style!.color, Colors.red);
      expect(tester.widget<Text>(find.text('test')).style!.color, Colors.red);
    });

    testWidgets('can change interline', (tester) async {
      await tester.pumpWidget(declareWidget(const ItemizedText(
        ['This', 'is', 'a', 'test'],
        interline: 10,
      )));

      final paddings = find.byType(Padding).evaluate();
      for (int i = 0; i < paddings.length; i++) {
        expect((paddings.elementAt(i).widget as Padding).padding.vertical,
            i == 0 ? 0 : 10);
      }
    });
  });
}
