import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lorem_ipsum/lorem_ipsum.dart';
import 'package:stagess_common_flutter/widgets/scrollable_stepper.dart';

import '../utils.dart';
import 'utils.dart';

class _MyScrollableStepper extends StatefulWidget {
  const _MyScrollableStepper({
    required this.stepperType,
    required this.nbSteps,
    this.initial = 0,
    this.onTapTile,
    this.onTapContinue,
    this.onTapCancel,
    this.stepsState,
    this.smallContent = false,
  });

  final StepperType stepperType;
  final int nbSteps;
  final int initial;
  final Function()? onTapTile;
  final Function()? onTapContinue;
  final Function()? onTapCancel;
  final List<StepState>? stepsState;
  final bool smallContent;

  @override
  State<_MyScrollableStepper> createState() => _MyScrollableStepperState();
}

class _MyScrollableStepperState extends State<_MyScrollableStepper> {
  late int _current = widget.initial;

  @override
  Widget build(BuildContext context) {
    return ScrollableStepper(
      type: widget.stepperType,
      scrollController: ScrollController(),
      currentStep: _current,
      onStepTapped: (value) {
        if (widget.onTapTile != null) widget.onTapTile!();
        setState(() => _current = value);
      },
      onTapContinue: () {
        if (widget.onTapContinue != null) widget.onTapContinue!();
        setState(() => _current += _current < widget.nbSteps ? 1 : 0);
      },
      onTapCancel: () {
        if (widget.onTapCancel != null) widget.onTapCancel!();
      },
      steps: [
        for (int i = 0; i < widget.nbSteps; i++)
          Step(
            state: widget.stepsState == null
                ? StepState.indexed
                : widget.stepsState![i],
            isActive: _current == i,
            title: Text('Title $i'),
            subtitle: Text('Subtitle $i'),
            label: Text('Label $i'),
            content: Text(widget.smallContent
                ? 'One line'
                : loremIpsum(paragraphs: 5, words: 400)),
          ),
      ],
    );
  }
}

void main() {
  group('ScrollableStepper', () {
    group('vertical', () {
      testWidgets('renders the titles, subtitles and labels', (tester) async {
        await tester.pumpWidget(declareWidget(
          const _MyScrollableStepper(
              stepperType: StepperType.vertical, nbSteps: 3, initial: 1),
        ));

        expect(find.text('Title 0'), findsOneWidget);
        expect(find.text('Title 1'), findsOneWidget);
        expect(find.text('Title 2'), findsNothing); // Outside of screen

        expect(find.text('Subtitle 0'), findsOneWidget);
        expect(find.text('Subtitle 1'), findsOneWidget);
        expect(find.text('Subtitle 2'), findsNothing); // Outside of screen

        // Vertical does not render the labels
        expect(find.text('Label 0'), findsNothing);
        expect(find.text('Label 1'), findsNothing);
        expect(find.text('Label 2'), findsNothing);
      });

      testWidgets('render the indices', (tester) async {
        await tester.pumpWidget(declareWidget(
          const _MyScrollableStepper(
              stepperType: StepperType.vertical, nbSteps: 3, initial: 1),
        ));

        // AnimatedContainer contains the indexed number
        expect(find.text('1'), findsOneWidget);
        final color1 = (tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
                .decoration as BoxDecoration)
            .color!;
        // Not selected
        expectNear(color1.a, 0.3800, epsilon: 1e-4);
        expectNear(color1.r, 0.1137, epsilon: 1e-4);
        expectNear(color1.g, 0.1059, epsilon: 1e-4);
        expectNear(color1.b, 0.1255, epsilon: 1e-4);

        expect(find.text('2'), findsOneWidget);
        final color2 = (tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).last)
                .decoration as BoxDecoration)
            .color!;
        // Selected
        expectNear(color2.a, 1.0, epsilon: 1e-4);
        expectNear(color2.r, 0.4039, epsilon: 1e-4);
        expectNear(color2.g, 0.3137, epsilon: 1e-4);
        expectNear(color2.b, 0.6431, epsilon: 1e-4);
      });

      testWidgets('can change which tab is selected', (tester) async {
        await tester.pumpWidget(declareWidget(
          const _MyScrollableStepper(
              stepperType: StepperType.vertical, nbSteps: 3, initial: 1),
        ));

        await tester.tap(find.text('Title 0'));
        await tester.pumpAndSettle();

        // AnimatedContainer contains the indexed number
        expect(find.text('1'), findsOneWidget);
        final color1 = (tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).last)
                .decoration as BoxDecoration)
            .color!;
        // Selected
        expectNear(color1.a, 1.0, epsilon: 1e-4);
        expectNear(color1.r, 0.4039, epsilon: 1e-4);
        expectNear(color1.g, 0.3137, epsilon: 1e-4);
        expectNear(color1.b, 0.6431, epsilon: 1e-4);

        expect(find.text('2'), findsNothing); // offscreen

        // Tapping on an open tile doest not close it
        await tester.tap(find.text('Title 0'));
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsNothing); // still offscreen
      });

      testWidgets('callbacks work properly', (tester) async {
        bool tapTile = false;
        bool tapContinue = false;
        bool tapCancel = false;
        await tester.pumpWidget(declareWidget(
          _MyScrollableStepper(
            stepperType: StepperType.vertical,
            nbSteps: 3,
            initial: 1,
            onTapTile: () => tapTile = true,
            onTapContinue: () => tapContinue = true,
            onTapCancel: () => tapCancel = true,
          ),
        ));

        // Test the tap on the tile
        await tester.tap(find.text('Title 0'));
        await tester.pumpAndSettle();
        expect(tapTile, isTrue);

        // Scroll the stepper to the end
        await tester.drag(find.text('Title 0'), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Test the cancel button
        expect(find.text('Annuler'), findsNWidgets(3));
        await tester.tap(find.text('Annuler').first);
        await tester.pumpAndSettle();
        expect(tapCancel, isTrue);

        // Test the continue button
        expect(find.text('Continuer'), findsNWidgets(3));
        await tester.tap(find.text('Continuer').first);
        await tester.pumpAndSettle();
        expect(tapContinue, isTrue);
      });

      testWidgets('the proper status is showns', (tester) async {
        await tester.pumpWidget(declareWidget(
          const _MyScrollableStepper(
            stepperType: StepperType.vertical,
            nbSteps: 5,
            initial: 0,
            stepsState: [
              StepState.complete,
              StepState.editing,
              StepState.error,
              StepState.disabled,
              StepState.indexed
            ],
            smallContent: true,
          ),
        ));

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.text('!'), findsOneWidget);

        // The fourth and fifth steps are simply indexed
        expect(find.text('4'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });
    });

    group('horizontal', () {
      testWidgets('renders the titles, subtitles and labels', (tester) async {
        await tester.pumpWidget(declareWidget(
          const _MyScrollableStepper(
              stepperType: StepperType.horizontal, nbSteps: 2, initial: 1),
        ));

        expect(find.text('Title 0'), findsOneWidget);
        expect(find.text('Title 1'), findsOneWidget);

        expect(find.text('Subtitle 0'), findsOneWidget);
        expect(find.text('Subtitle 1'), findsOneWidget);

        // Horizontal renderd the labels
        expect(find.text('Label 0'), findsOneWidget);
        expect(find.text('Label 1'), findsOneWidget);
      });

      testWidgets('render the indices', (tester) async {
        await tester.pumpWidget(declareWidget(
          const _MyScrollableStepper(
              stepperType: StepperType.horizontal, nbSteps: 2, initial: 1),
        ));

        // AnimatedContainer contains the indexed number
        expect(find.byType(AnimatedContainer), findsNWidgets(2));

        expect(find.text('1'), findsOneWidget);
        final color1 = (tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
                .decoration as BoxDecoration)
            .color!;
        // Not selected
        expectNear(color1.a, 0.3800, epsilon: 1e-4);
        expectNear(color1.r, 0.1137, epsilon: 1e-4);
        expectNear(color1.g, 0.1059, epsilon: 1e-4);
        expectNear(color1.b, 0.1255, epsilon: 1e-4);

        expect(find.text('2'), findsOneWidget);
        final color2 = (tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).last)
                .decoration as BoxDecoration)
            .color!;
        // Selected
        expectNear(color2.a, 1.0, epsilon: 1e-4);
        expectNear(color2.r, 0.4039, epsilon: 1e-4);
        expectNear(color2.g, 0.3137, epsilon: 1e-4);
        expectNear(color2.b, 0.6431, epsilon: 1e-4);
      });

      testWidgets('can change which tab is selected', (tester) async {
        await tester.pumpWidget(declareWidget(
          const _MyScrollableStepper(
              stepperType: StepperType.horizontal, nbSteps: 2, initial: 1),
        ));

        // AnimatedContainer contains the indexed number
        expect(find.byType(AnimatedContainer), findsNWidgets(2));

        expect(find.text('1'), findsOneWidget);
        final color1 = (tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
                .decoration as BoxDecoration)
            .color!;
        // Not selected
        expectNear(color1.a, 0.3800, epsilon: 1e-4);
        expectNear(color1.r, 0.1137, epsilon: 1e-4);
        expectNear(color1.g, 0.1059, epsilon: 1e-4);
        expectNear(color1.b, 0.1255, epsilon: 1e-4);

        expect(find.text('2'), findsOneWidget);

        {
          final color = (tester
                  .widget<AnimatedContainer>(
                      find.byType(AnimatedContainer).last)
                  .decoration as BoxDecoration)
              .color!;
          // Selected
          expectNear(color.a, 1.0, epsilon: 1e-4);
          expectNear(color.r, 0.4039, epsilon: 1e-4);
          expectNear(color.g, 0.3137, epsilon: 1e-4);
          expectNear(color.b, 0.6431, epsilon: 1e-4);
        }

        // Tapping on an open tile doest not close it
        await tester.tap(find.text('Title 0'));
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);
        {
          final color = (tester
                  .widget<AnimatedContainer>(
                      find.byType(AnimatedContainer).first)
                  .decoration as BoxDecoration)
              .color!;
          // Selected
          expectNear(color.a, 1.0, epsilon: 1e-4);
          expectNear(color.r, 0.4039, epsilon: 1e-4);
          expectNear(color.g, 0.3137, epsilon: 1e-4);
          expectNear(color.b, 0.6431, epsilon: 1e-4);
        }
        {
          expect(find.text('2'), findsOneWidget);
          final color = (tester
                  .widget<AnimatedContainer>(
                      find.byType(AnimatedContainer).last)
                  .decoration as BoxDecoration)
              .color!;
          // Not selected
          expectNear(color.a, 0.3800, epsilon: 1e-4);
          expectNear(color.r, 0.1137, epsilon: 1e-4);
          expectNear(color.g, 0.1059, epsilon: 1e-4);
          expectNear(color.b, 0.1255, epsilon: 1e-4);
        }

        // Retap on an open tile doest not close it
        await tester.tap(find.text('Title 0'));
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);
        {
          final color = (tester
                  .widget<AnimatedContainer>(
                      find.byType(AnimatedContainer).first)
                  .decoration as BoxDecoration)
              .color!;
          // Selected
          expectNear(color.a, 1.0, epsilon: 1e-4);
          expectNear(color.r, 0.4039, epsilon: 1e-4);
          expectNear(color.g, 0.3137, epsilon: 1e-4);
          expectNear(color.b, 0.6431, epsilon: 1e-4);
        }
      });

      testWidgets('callbacks work properly', (tester) async {
        bool tapTile = false;
        bool tapContinue = false;
        bool tapCancel = false;
        await tester.pumpWidget(declareWidget(
          _MyScrollableStepper(
            stepperType: StepperType.vertical,
            nbSteps: 2,
            initial: 1,
            onTapTile: () => tapTile = true,
            onTapContinue: () => tapContinue = true,
            onTapCancel: () => tapCancel = true,
          ),
        ));

        // Test the tap on the tile
        await tester.tap(find.text('Title 0'));
        await tester.pumpAndSettle();
        expect(tapTile, isTrue);

        // Scroll the stepper to the end
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Test the cancel button
        expect(find.text('Annuler'), findsNWidgets(2));
        await tester.tap(find.text('Annuler').first);
        await tester.pumpAndSettle();
        expect(tapCancel, isTrue);

        // Test the continue button
        expect(find.text('Continuer'), findsNWidgets(2));
        await tester.tap(find.text('Continuer').first);
        await tester.pumpAndSettle();
        expect(tapContinue, isTrue);
      });

      testWidgets('the proper status is showns', (tester) async {
        await tester.pumpWidget(declareWidget(
          const _MyScrollableStepper(
            stepperType: StepperType.horizontal,
            nbSteps: 3,
            initial: 0,
            stepsState: [
              StepState.complete,
              StepState.editing,
              StepState.error,
            ],
            smallContent: true,
          ),
        ));

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.text('!'), findsOneWidget);
      });
    });
  });
}
