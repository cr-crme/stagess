import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';

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
  group('CheckboxWithOther', () {
    testWidgets('renders all the choices with other as extra choice', (
      tester,
    ) async {
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
            ),
          ),
        ),
      );

      for (final choice in _MyTestingEnum.values) {
        expect(find.text(choice.toString()), findsOneWidget);
      }
      expect(find.text('Autre'), findsOneWidget);

      // The other text field is not present
      expect(find.text('Préciser\u00a0:'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('renders a not applicable if requested', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
              hasNotApplicableOption: true,
            ),
          ),
        ),
      );

      expect(find.text('Ne s\'applique pas'), findsOneWidget);
    });

    testWidgets('do not renders with other option if requested not to', (
      tester,
    ) async {
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
            ),
            showOtherOption: false,
          ),
        ),
      );

      expect(find.text('Autre'), findsNothing);
    });

    testWidgets('can render a title', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
            ),
            title: 'My title',
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
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
            ),
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

    testWidgets('tapping other renders a text box to enter text', (
      tester,
    ) async {
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Autre'));
      await tester.pump();

      expect(find.text('Préciser\u00a0:'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('can check all if not applicable is not present', (
      tester,
    ) async {
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
            ),
          ),
        ),
      );

      // They all start unchecked
      for (final checkbox in tester.widgetList<Checkbox>(
        find.byType(Checkbox),
      )) {
        expect(checkbox.value, isFalse);
      }

      // Check them all
      for (final choice in _MyTestingEnum.values) {
        await tester.tap(find.text(choice.toString()));
        await tester.pump();
      }
      await tester.tap(find.text('Autre'));
      await tester.pump();

      // They are all checked
      for (final checkbox in tester.widgetList<Checkbox>(
        find.byType(Checkbox),
      )) {
        expect(checkbox.value, isTrue);
      }
    });

    testWidgets('tapping not applicable uncheck and disable all', (
      tester,
    ) async {
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
              hasNotApplicableOption: true,
            ),
          ),
        ),
      );

      // Check them all
      for (final choice in _MyTestingEnum.values) {
        await tester.tap(find.text(choice.toString()));
        await tester.pump();
      }
      await tester.tap(find.text('Autre'));
      await tester.pump();

      // Tap not applicable
      await tester.tap(find.text('Ne s\'applique pas'));
      await tester.pump();

      // Only the not applicable is checked and enabled
      for (final checkbox in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        if ((checkbox.title as Text).data == 'Ne s\'applique pas') {
          expect(checkbox.value, isTrue);
          expect(checkbox.enabled, isTrue);
        } else {
          expect(checkbox.value, isFalse);
          expect(checkbox.enabled, isFalse);
        }
      }

      // Unchecking not applicable re-enable but without rechecking
      await tester.tap(find.text('Ne s\'applique pas'));
      await tester.pump();

      for (final checkbox in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        expect(checkbox.value, isFalse);
        expect(checkbox.enabled, isTrue);
      }
    });

    testWidgets('can initialize with values and other', (tester) async {
      final values = [
        _MyTestingEnum.a.toString(),
        _MyTestingEnum.c.toString(),
        'My other choice',
      ];
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
              initialValues: values,
            ),
          ),
        ),
      );

      // Only the first, last checked and other is checked
      for (final checkbox in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        final title = (checkbox.title as Text).data;
        if (values.contains(title) || title == 'Autre') {
          expect(checkbox.value, isTrue);
        } else {
          expect(checkbox.value, isFalse);
        }
      }

      // The other text field is present and filled with the other value
      expect(find.text('Préciser\u00a0:'), findsOneWidget);
      expect(find.text('My other choice'), findsOneWidget);
    });

    testWidgets('can initialize with not applicable', (tester) async {
      final values = ['__NOT_APPLICABLE_INTERNAL__'];
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
              initialValues: values,
              hasNotApplicableOption: true,
            ),
          ),
        ),
      );

      // only not applicable is checked and enabled
      for (final checkbox in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        if ((checkbox.title as Text).data == 'Ne s\'applique pas') {
          expect(checkbox.value, isTrue);
          expect(checkbox.enabled, isTrue);
        } else {
          expect(checkbox.value, isFalse);
          expect(checkbox.enabled, isFalse);
        }
      }

      // The other text field is not present
      expect(find.text('Préciser\u00a0:'), findsNothing);
      expect(find.byType(TextField), findsNothing);

      // The not applicable is checked
    });

    testWidgets(
      'if the not applicable tag is not alone it is howeber considered as a normal other value',
      (tester) async {
        final values = ['__NOT_APPLICABLE_INTERNAL__', 'My other choice'];
        await tester.pumpWidget(
          declareWidget(
            CheckboxWithOther<_MyTestingEnum>(
              controller: CheckboxWithOtherController(
                elements: _MyTestingEnum.values,
                initialValues: values,
                hasNotApplicableOption: true,
              ),
            ),
          ),
        );

        // only other is checked
        for (final checkbox in tester.widgetList<CheckboxListTile>(
          find.byType(CheckboxListTile),
        )) {
          final title = (checkbox.title as Text).data;
          if (title == 'Autre') {
            expect(checkbox.value, isTrue);
          } else {
            expect(checkbox.value, isFalse);
          }
        }

        // The other text field is present and filled with the other value and
        // the not applicable tag
        expect(find.text('Préciser\u00a0:'), findsOneWidget);
        expect(
          find.text('__NOT_APPLICABLE_INTERNAL__\nMy other choice'),
          findsOneWidget,
        );
      },
    );

    testWidgets('can disable the whole widget', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(
            controller: CheckboxWithOtherController(
              elements: _MyTestingEnum.values,
              initialValues: [_MyTestingEnum.b.toString(), 'My other value'],
            ),
            enabled: false,
          ),
        ),
      );

      // All checkboxes are disabled, those checked are still checked if initialized
      for (final checkbox in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        expect(checkbox.enabled, isFalse);
        final title = (checkbox.title as Text).data;
        if ([_MyTestingEnum.b.toString(), 'Autre'].contains(title)) {
          expect(checkbox.value, isTrue);
        } else {
          expect(checkbox.value, isFalse);
        }
      }

      // The other text field is disabled but filled
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(find.text('My other value'), findsOneWidget);
    });

    testWidgets(
      'renders a follow on any selection except not applicable if requested',
      (tester) async {
        final controller = CheckboxWithOtherController(
          elements: _MyTestingEnum.values,
          hasNotApplicableOption: true,
        );
        await tester.pumpWidget(
          declareWidget(
            CheckboxWithOther<_MyTestingEnum>(
              controller: controller,
              followUpChild: const Text('My follow up'),
            ),
          ),
        );

        // The follow up is not present
        expect(find.text('My follow up'), findsNothing);

        // Test the follow appear and disapear on selection
        for (final choice in _MyTestingEnum.values) {
          await tester.tap(find.text(choice.toString()));
          await tester.pump();

          // The follow up is present
          expect(find.text('My follow up'), findsOneWidget);
          expect(controller.hasFollowUp, isTrue);

          // Uncheck
          await tester.tap(find.text(choice.toString()));
          await tester.pump();

          // The follow up is not present anymore
          expect(find.text('My follow up'), findsNothing);
          expect(controller.hasFollowUp, isFalse);
        }
        await tester.tap(find.text('Autre'));
        await tester.pump();

        // The follow up is present
        expect(find.text('My follow up'), findsOneWidget);
        expect(controller.hasFollowUp, isTrue);

        // Uncheck
        await tester.tap(find.text('Autre'));
        await tester.pump();

        // The follow up is not present anymore
        expect(find.text('My follow up'), findsNothing);
        expect(controller.hasFollowUp, isFalse);

        // Tap not applicable
        await tester.tap(find.text('Ne s\'applique pas'));
        await tester.pump();

        // The follow up is not present
        expect(find.text('My follow up'), findsNothing);
        expect(controller.hasFollowUp, isFalse);
      },
    );

    testWidgets(
      '"onOptionSelected" is called with any modification of the widget and filled properly',
      (tester) async {
        bool wasCalled = false;
        List<String> values = [];
        await tester.pumpWidget(
          declareWidget(
            CheckboxWithOther<_MyTestingEnum>(
              controller: CheckboxWithOtherController(
                elements: _MyTestingEnum.values,
                hasNotApplicableOption: true,
              ),
              onOptionSelected: (options) {
                wasCalled = true;
                values = options;
              },
            ),
          ),
        );

        // Tap choices one by one
        for (final choice in _MyTestingEnum.values) {
          await tester.tap(find.text(choice.toString()));
          await tester.pump();

          // The callback is called with the values
          expect(wasCalled, isTrue);
          expect(values.length, 1);
          expect(values[0], choice.toString());

          // Reset the testers
          wasCalled = false;
          values = [];

          // Untapping returns to initial state
          await tester.tap(find.text(choice.toString()));
          await tester.pump();
          expect(wasCalled, isTrue);
          expect(values.length, 0);

          // Reset the testers
          wasCalled = false;
          values = [];
        }

        // Tap other
        await tester.tap(find.text('Autre'));
        await tester.pump();
        expect(wasCalled, isTrue);
        expect(values.length, 0);

        // Reset the testers
        wasCalled = false;
        values = [];

        // Enter text
        await tester.enterText(find.byType(TextField), 'My other choice');
        await tester.pump();
        expect(wasCalled, isTrue);
        expect(values.length, 1);
        expect(values[0], 'My other choice');

        // Reset the testers
        wasCalled = false;
        values = [];

        // Tap not applicable
        await tester.tap(find.text('Ne s\'applique pas'));
        await tester.pump();
        expect(wasCalled, isTrue);
        expect(values.length, 1);
        expect(values[0], '__NOT_APPLICABLE_INTERNAL__');

        // Uncheck not applicable
        await tester.tap(find.text('Ne s\'applique pas'));
        await tester.pump();
        expect(wasCalled, isTrue);
        expect(values.length, 0);

        // Reset the testers
        wasCalled = false;
        values = [];

        // Tap everything except not applicable
        for (final choice in _MyTestingEnum.values) {
          await tester.tap(find.text(choice.toString()));
          await tester.pump();
        }
        await tester.tap(find.text('Autre'));
        await tester.pump();
        // Add text
        await tester.enterText(find.byType(TextField), 'My other choice');
        await tester.pump();

        expect(wasCalled, isTrue);
        expect(values.length, 4);
        expect(values[0], _MyTestingEnum.a.toString());
        expect(values[1], _MyTestingEnum.b.toString());
        expect(values[2], _MyTestingEnum.c.toString());
        expect(values[3], 'My other choice');
      },
    );

    testWidgets('"selected" is filled properly', (tester) async {
      final controller = CheckboxWithOtherController(
        elements: _MyTestingEnum.values,
        hasNotApplicableOption: true,
      );
      await tester.pumpWidget(
        declareWidget(
          CheckboxWithOther<_MyTestingEnum>(controller: controller),
        ),
      );

      // Tap choices one by one
      for (final choice in _MyTestingEnum.values) {
        await tester.tap(find.text(choice.toString()));
        await tester.pump();

        // The callback is called with the values
        expect(controller.selected.length, 1);
        expect(controller.selected[0], choice);

        // Untapping returns to initial state
        await tester.tap(find.text(choice.toString()));
        await tester.pump();
        expect(controller.selected.length, 0);
      }

      // Tap other
      await tester.tap(find.text('Autre'));
      await tester.pump();
      expect(controller.selected.length, 0);

      // Enter text
      await tester.enterText(find.byType(TextField), 'My other choice');
      await tester.pump();
      expect(controller.selected.length, 0);

      // Tap not applicable
      await tester.tap(find.text('Ne s\'applique pas'));
      await tester.pump();
      expect(controller.selected.length, 0);

      // Uncheck not applicable
      await tester.tap(find.text('Ne s\'applique pas'));
      await tester.pump();
      expect(controller.selected.length, 0);

      // Tap everything except not applicable
      for (final choice in _MyTestingEnum.values) {
        await tester.tap(find.text(choice.toString()));
        await tester.pump();
      }
      await tester.tap(find.text('Autre'));
      await tester.pump();
      // Add text
      await tester.enterText(find.byType(TextField), 'My other choice');
      await tester.pump();

      expect(controller.selected.length, 3);
      expect(controller.selected[0], _MyTestingEnum.a);
      expect(controller.selected[1], _MyTestingEnum.b);
      expect(controller.selected[2], _MyTestingEnum.c);
    });

    testWidgets('can validate form properly', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        declareWidget(
          Form(
            key: formKey,
            child: CheckboxWithOther<_MyTestingEnum>(
              controller: CheckboxWithOtherController(
                elements: _MyTestingEnum.values,
                hasNotApplicableOption: true,
              ),
            ),
          ),
        ),
      );

      // The form validate if empty
      expect(formKey.currentState!.validate(), isTrue);

      // Tap not applicable
      await tester.tap(find.text('Ne s\'applique pas'));
      await tester.pump();

      // The form stills validate
      expect(formKey.currentState!.validate(), isTrue);

      // Uncheck not applicable
      await tester.tap(find.text('Ne s\'applique pas'));
      await tester.pump();

      // The form stills validate
      expect(formKey.currentState!.validate(), isTrue);

      // Tap other but do not fill the text field
      await tester.tap(find.text('Autre'));
      await tester.pump();
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Préciser au moins un élément'), findsOneWidget);

      // Fill the text field
      await tester.enterText(find.byType(TextField), 'My other choice');
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('Préciser au moins un élément'), findsNothing);

      // Tap everything except not applicable, but not fill the other
      for (final choice in _MyTestingEnum.values) {
        await tester.tap(find.text(choice.toString()));
        await tester.pump();
      }

      // The form stills validate
      expect(formKey.currentState!.validate(), isTrue);
    });
  });
}
