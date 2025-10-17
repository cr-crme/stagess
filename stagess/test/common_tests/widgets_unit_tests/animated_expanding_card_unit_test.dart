import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

import 'utils.dart';

void main() {
  group('AnimatedExpandingCard', () {
    testWidgets('Header is always displayed', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          AnimatedExpandingCard(
            header: (ctx, isExpanded) => Text('Header'),
            child: Text('Child'),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);

      // Tap the card header
      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();

      expect(find.text('Header'), findsOneWidget);
    });

    testWidgets('tapping expands the card', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          AnimatedExpandingCard(
            header: (ctx, isExpanded) => Text('Header'),
            child: Text('Child'),
          ),
        ),
      );

      // Verify the card is not expanded
      expect(find.byType(SizeTransition), findsNothing);

      // Tap the card header
      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();

      // Verify the card is expanded
      expect(tester.getSize(find.byType(SizeTransition)).height, isPositive);

      // Tap the card header
      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();

      // Verify the card is not expanded
      expect(tester.getSize(find.byType(SizeTransition)).height, 0);
    });

    testWidgets('icon changes when card is expanded', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          AnimatedExpandingCard(
            header: (ctx, isExpanded) => Text('Header'),
            child: Text('Child'),
          ),
        ),
      );

      // Verify the card shows it is not expanded
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      // Tap the card header
      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();

      // Verify the card shows it is expanded
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      // Tap the card header
      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();

      // Verify the card shows it is not expanded
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('can start expanded', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          AnimatedExpandingCard(
            header: (ctx, isExpanded) => Text('Header'),
            initialExpandedState: true,
            child: Text('Child'),
          ),
        ),
      );

      // Verify the card is expanded
      expect(tester.getSize(find.byType(SizeTransition)).height, isPositive);

      // Tap the card header
      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();

      // Verify the card is not expanded
      expect(tester.getSize(find.byType(SizeTransition)).height, 0);
    });
  });
}
