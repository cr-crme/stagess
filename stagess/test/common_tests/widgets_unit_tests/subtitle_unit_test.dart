import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/sub_title.dart';

import '../../utils.dart';
import 'utils.dart';

void main() {
  group('SubTitle', () {
    testWidgets('renders a title with default paddings', (tester) async {
      await tester.pumpWidget(declareWidget(const SubTitle('My subtitle')));

      final textFinder = find.text('My subtitle');
      expect(textFinder, findsOneWidget);
      expect(tester.widget<Text>(textFinder).style,
          Theme.of(tester.context(textFinder)).textTheme.titleLarge);

      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsOneWidget);

      final padding = tester.widget<Padding>(paddingFinder);
      expect(
          padding.padding,
          const EdgeInsets.only(
              left: 16.0, top: 24.0, bottom: 8.0, right: 0.0));
    });

    testWidgets('renders a title with custom paddings', (tester) async {
      await tester.pumpWidget(declareWidget(const SubTitle('My subtitle',
          left: 12.0, top: 12.0, bottom: 12.0, right: 12.0)));

      expect(find.text('My subtitle'), findsOneWidget);

      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsOneWidget);

      final padding = tester.widget<Padding>(paddingFinder);
      expect(padding.padding, const EdgeInsets.all(12.0));
    });
  });
}
