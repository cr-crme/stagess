import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/form_fields/text_with_form.dart';

import '../utils.dart';

void main() {
  group('TextWithForm', () {
    testWidgets('renders a title', (tester) async {
      await tester
          .pumpWidget(declareWidget(const TextWithForm(title: 'My title')));

      expect(find.text('My title'), findsOneWidget);
    });

    testWidgets('can customize title style', (tester) async {
      await tester.pumpWidget(declareWidget(const TextWithForm(
        title: 'My title',
        titleStyle: TextStyle(color: Colors.red),
      )));

      expect(find.text('My title'), findsOneWidget);
      expect(
          tester.widget<Text>(find.text('My title')).style!.color, Colors.red);
    });

    testWidgets('the text field can be controller', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(declareWidget(
          TextWithForm(title: 'My title', controller: controller)));

      await tester.enterText(find.byType(TextField), 'My text');
      expect(controller.text, 'My text');

      controller.text = 'My new text';
      await tester.pump();
      expect(find.text('My new text'), findsOneWidget);
    });

    testWidgets('can initialize without controller', (tester) async {
      await tester.pumpWidget(declareWidget(const TextWithForm(
        title: 'My title',
        initialValue: 'My initial text',
      )));

      expect(find.text('My initial text'), findsOneWidget);
    });

    testWidgets('"onChanged" callback behaves properly', (tester) async {
      String? changedText;
      await tester.pumpWidget(declareWidget(TextWithForm(
        title: 'My title',
        onChanged: (text) => changedText = text,
      )));

      await tester.enterText(find.byType(TextField), 'My text');
      expect(changedText, 'My text');
    });

    testWidgets('validation works if no validator is sent', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(declareWidget(SingleChildScrollView(
          child: Form(
              key: formKey, child: const TextWithForm(title: 'My title')))));

      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('validation fails if validator returns a string',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(declareWidget(SingleChildScrollView(
          child: Form(
        key: formKey,
        child: TextWithForm(title: 'My title', validator: (text) => 'My error'),
      ))));

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('My error'), findsOneWidget);
    });

    testWidgets('validation succeeds if validator returns null',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(declareWidget(SingleChildScrollView(
          child: Form(
        key: formKey,
        child: TextWithForm(title: 'My title', validator: (text) => null),
      ))));

      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();

      expect(find.text('My error'), findsNothing);
    });

    testWidgets('"onSaved" callback is called if form is saved',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      String? savedText;
      await tester.pumpWidget(declareWidget(SingleChildScrollView(
          child: Form(
        key: formKey,
        child: TextWithForm(
          title: 'My title',
          onSaved: (text) => savedText = text,
        ),
      ))));

      await tester.enterText(find.byType(TextField), 'My text');
      await tester.pump();
      expect(savedText, isNull);

      formKey.currentState!.save();
      expect(savedText, 'My text');
    });
  });
}
