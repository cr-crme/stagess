import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/form_fields/low_high_slider_form_field.dart';

import '../utils.dart';

void main() {
  group('LowHighSliderFormField', () {
    testWidgets('renders labels by default', (tester) async {
      await tester.pumpWidget(declareWidget(LowHighSliderFormField()));

      expect(find.text('Faible'), findsOneWidget);
      expect(find.text('Élevé'), findsOneWidget);
    });

    testWidgets('renders custom labels', (tester) async {
      await tester.pumpWidget(declareWidget(LowHighSliderFormField(
          lowLabel: 'Low', highLabel: 'High', initialValue: 3)));

      expect(find.text('Low'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('renders an error message if value is too small',
        (tester) async {
      await tester
          .pumpWidget(declareWidget(LowHighSliderFormField(initialValue: 0)));

      expect(find.text('Aucune donnée pour l\'instant.'), findsOneWidget);
    });

    testWidgets('renders an error message if value is too big', (tester) async {
      await tester
          .pumpWidget(declareWidget(LowHighSliderFormField(initialValue: 6)));

      expect(find.text('Aucune donnée pour l\'instant.'), findsOneWidget);
    });

    testWidgets('has minimum and maximum by default', (tester) async {
      await tester.pumpWidget(declareWidget(LowHighSliderFormField()));

      final sliderFinder = find.byType(Slider);
      final slider = tester.widget<Slider>(sliderFinder);

      expect(slider.min, 1);
      expect(slider.max, 5);
    });

    testWidgets('integers are the default', (tester) async {
      await tester.pumpWidget(declareWidget(LowHighSliderFormField()));

      final sliderFinder = find.byType(Slider);
      final slider = tester.widget<Slider>(sliderFinder);

      expect(slider.divisions, 4);
    });

    testWidgets('can be decimal', (tester) async {
      await tester
          .pumpWidget(declareWidget(LowHighSliderFormField(decimal: 1)));

      final sliderFinder = find.byType(Slider);
      final slider = tester.widget<Slider>(sliderFinder);

      expect(slider.divisions, 40);
    });

    testWidgets('can fix the value while keeping the style of active',
        (tester) async {
      await tester
          .pumpWidget(declareWidget(LowHighSliderFormField(fixed: true)));

      final sliderFinder = find.byType(Slider);
      final slider = tester.widget<Slider>(sliderFinder);

      expect(slider.onChanged, isNotNull);
    });

    testWidgets('can drag the slider', (tester) async {
      await tester.pumpWidget(declareWidget(LowHighSliderFormField()));
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pump();

      expect(tester.widget<Slider>(find.byType(Slider)).value, 4);
    });

    testWidgets('cannot drag if fixed', (tester) async {
      await tester
          .pumpWidget(declareWidget(LowHighSliderFormField(fixed: true)));
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pump();

      expect(tester.widget<Slider>(find.byType(Slider)).value, 3);
    });
  });
}
