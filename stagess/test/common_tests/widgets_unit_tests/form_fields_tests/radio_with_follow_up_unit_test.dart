import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/radio_with_follow_up.dart';

import '../../../utils.dart';
import '../utils.dart';

enum _MyTestingEnum {
  a,
  b,
  c;

  @override
  String toString() {
    switch (this) {
      case _MyTestingEnum.a:
        return 'My choice a';
      case _MyTestingEnum.b:
        return 'Your choice b';
      case _MyTestingEnum.c:
        return 'Her choice c';
    }
  }
}

void main() {
  group('RadioWithFollowUp', () {
    testWidgets('renders all the choices', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          const RadioWithFollowUp<_MyTestingEnum>(
            elements: _MyTestingEnum.values,
            followUpChild: Text('My follow up'),
          ),
        ),
      );

      for (final choice in _MyTestingEnum.values) {
        expect(find.text(choice.toString()), findsOneWidget);
      }

      // The follow up is not present
      expect(find.text('My follow up'), findsNothing);
    });

    testWidgets('can render a title', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          const RadioWithFollowUp<_MyTestingEnum>(
            title: 'My title',
            elements: _MyTestingEnum.values,
          ),
        ),
      );

      final titleFinder = find.text('My title');
      expect(titleFinder, findsOneWidget);
      expect(
        tester.widget<Text>(titleFinder).style,
        Theme.of(tester.context(titleFinder)).textTheme.titleSmall,
      );
    });

    testWidgets('can customize the title', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          const RadioWithFollowUp<_MyTestingEnum>(
            elements: _MyTestingEnum.values,
            title: 'My title',
            titleStyle: TextStyle(color: Colors.red),
          ),
        ),
      );

      expect(
        tester.widget<Text>(find.text('My title')).style!.color,
        Colors.red,
      );
    });

    testWidgets('tapping values that add follow up does show it', (
      tester,
    ) async {
      await tester.pumpWidget(
        declareWidget(
          const RadioWithFollowUp<_MyTestingEnum>(
            elements: _MyTestingEnum.values,
            elementsThatShowChild: [_MyTestingEnum.a, _MyTestingEnum.c],
            followUpChild: Text('My follow up'),
          ),
        ),
      );

      // The follow up is not present
      expect(find.text('My follow up'), findsNothing);

      for (final choice in _MyTestingEnum.values) {
        // Tap the choice
        await tester.tap(find.text(choice.toString()));
        await tester.pump();

        // The follow up is present if in requested element
        if (choice == _MyTestingEnum.a || choice == _MyTestingEnum.c) {
          expect(find.text('My follow up'), findsOneWidget);
        } else {
          expect(find.text('My follow up'), findsNothing);
        }
      }
    });

    testWidgets('nothing is selected by default', (tester) async {
      final controller = RadioWithFollowUpController<_MyTestingEnum>();
      await tester.pumpWidget(
        declareWidget(
          RadioWithFollowUp<_MyTestingEnum>(
            controller: controller,
            elements: _MyTestingEnum.values,
            followUpChild: const Text('My follow up'),
          ),
        ),
      );

      // No radio is checked
      expect(controller.value, isNull);
    });

    testWidgets('cannot send controller and initial value', (tester) async {
      final controller = RadioWithFollowUpController<_MyTestingEnum>();
      await tester.pumpWidget(
        declareWidget(
          RadioWithFollowUp<_MyTestingEnum>(
            controller: controller,
            initialValue: _MyTestingEnum.a,
            elements: _MyTestingEnum.values,
          ),
        ),
      );

      // An error is thrown
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('can initialize with value from controller', (tester) async {
      final controller = RadioWithFollowUpController<_MyTestingEnum>(
        initialValue: _MyTestingEnum.c,
      );
      await tester.pumpWidget(
        declareWidget(
          RadioWithFollowUp<_MyTestingEnum>(
            controller: controller,
            elements: _MyTestingEnum.values,
          ),
        ),
      );

      // The value returns the current checked value
      expect(controller.value, _MyTestingEnum.c);
    });

    testWidgets('can tap a value', (tester) async {
      final controller = RadioWithFollowUpController<_MyTestingEnum>();
      await tester.pumpWidget(
        declareWidget(
          RadioWithFollowUp<_MyTestingEnum>(
            controller: controller,
            elements: _MyTestingEnum.values,
          ),
        ),
      );

      // Tap the choice
      await tester.tap(find.text(_MyTestingEnum.a.toString()));
      await tester.pump();

      // The value returns the current checked value
      expect(controller.value, _MyTestingEnum.a);
    });

    testWidgets('can force a selection', (tester) async {
      final controller = RadioWithFollowUpController<_MyTestingEnum>();
      await tester.pumpWidget(
        declareWidget(
          RadioWithFollowUp<_MyTestingEnum>(
            controller: controller,
            elements: _MyTestingEnum.values,
          ),
        ),
      );

      // Force the choice
      controller.forceSet(_MyTestingEnum.b);
      await tester.pump();

      // The value returns the current checked value
      expect(controller.value, _MyTestingEnum.b);
    });

    testWidgets('cannot tap if disabled', (tester) async {
      final controller = RadioWithFollowUpController<_MyTestingEnum>();
      await tester.pumpWidget(
        declareWidget(
          RadioWithFollowUp<_MyTestingEnum>(
            controller: controller,
            elements: _MyTestingEnum.values,
            enabled: false,
          ),
        ),
      );

      // Tap the choice
      await tester.tap(find.text(_MyTestingEnum.a.toString()));
      await tester.pump();

      // The value returns the current checked value
      expect(controller.value, isNull);
    });

    testWidgets('"onChanged" is called when a selection is made', (
      tester,
    ) async {
      bool wasCalled = false;
      _MyTestingEnum? value;
      await tester.pumpWidget(
        declareWidget(
          RadioWithFollowUp<_MyTestingEnum>(
            elements: _MyTestingEnum.values,
            onChanged: (option) {
              wasCalled = true;
              value = option;
            },
          ),
        ),
      );

      // Tap a choice one by one
      await tester.tap(find.text(_MyTestingEnum.b.toString()));
      await tester.pump();
      expect(wasCalled, isTrue);
      expect(value, _MyTestingEnum.b);
    });
  });
}
