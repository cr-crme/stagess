import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';

import '../../utils.dart';
import 'utils.dart';

void main() {
  group('EmailListTile', () {
    testWidgets('renders a title', (tester) async {
      await tester.pumpWidget(
        declareWidget(const EmailListTile(title: 'Mon courriel de test')),
      );

      expect(find.text('Mon courriel de test'), findsOneWidget);
    });

    testWidgets('renders a mandatory title if enabled', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          const EmailListTile(
            title: 'Mon courriel de test',
            isMandatory: true,
            enabled: true,
          ),
        ),
      );

      expect(find.text('* Mon courriel de test'), findsOneWidget);
    });

    testWidgets('does not render a mandatory title if not enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        declareWidget(
          const EmailListTile(
            title: 'Mon courriel de test',
            isMandatory: true,
            enabled: false,
          ),
        ),
      );

      expect(find.text('* Mon courriel de test'), findsNothing);
      expect(find.text('Mon courriel de test'), findsOneWidget);
    });

    testWidgets('renders an email if initialized', (tester) async {
      await tester.pumpWidget(
        declareWidget(const EmailListTile(initialValue: 'aa@aa.aa')),
      );

      expect(find.text('aa@aa.aa'), findsOneWidget);
    });

    testWidgets('renders an email icon', (tester) async {
      await tester.pumpWidget(declareWidget(const EmailListTile()));

      expect(find.byIcon(Icons.mail), findsOneWidget);
    });

    testWidgets('can write if "isEnable" is true', (tester) async {
      await tester.pumpWidget(
        declareWidget(const EmailListTile(enabled: true)),
      );

      final formField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(formField.enabled, true);
    });

    testWidgets('cannot write if "isEnable" is false', (tester) async {
      await tester.pumpWidget(
        declareWidget(const EmailListTile(enabled: false)),
      );

      final formField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(formField.enabled, false);
    });

    testWidgets(
      'cannot send a mail if "canMail" is true, but no email is entered',
      (tester) async {
        await tester.pumpWidget(
          declareWidget(const EmailListTile(canMail: true)),
        );

        final mailFinder = find.byIcon(Icons.mail);
        final mailIcon = tester.widget<Icon>(mailFinder);
        final mailInkwell = tester.ancestorByType<InkWell>(of: mailFinder);

        // Color of the icon should not be grey
        expect(mailIcon.color, Colors.grey);
        expect(mailInkwell.onTap, isNull);
      },
    );

    testWidgets(
      'can send a mail if "canMail" is true and an email is entered',
      (tester) async {
        await tester.pumpWidget(
          declareWidget(
            const EmailListTile(canMail: true, initialValue: 'dummy@email.com'),
          ),
        );

        final mailFinder = find.byIcon(Icons.mail);
        final mailIcon = tester.widget<Icon>(mailFinder);
        final mailInkwell = tester.ancestorByType<InkWell>(of: mailFinder);

        // Color of the icon should not be grey
        expect(mailIcon.color, isNot(Colors.grey));
        expect(mailInkwell.onTap, isNotNull);
      },
    );

    testWidgets('cannot send a mail if "canMail" is false', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          const EmailListTile(canMail: false, initialValue: 'dummy@email.com'),
        ),
      );

      final mailFinder = find.byIcon(Icons.mail);
      final mailIcon = tester.widget<Icon>(mailFinder);
      final mailInkwell = tester.ancestorByType<InkWell>(of: mailFinder);

      // Color of the icon should be grey
      expect(mailIcon.color, Colors.grey);
      expect(mailInkwell.onTap, isNull);
    });

    testWidgets('form properly validates email when is mandatory', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        declareWidget(
          Form(
            key: formKey,
            child: const EmailListTile(enabled: true, isMandatory: true),
          ),
        ),
      );

      // Empty email should not validate
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pumpAndSettle();
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(
        find.text('Une adresse courriel est obligatoire.'),
        findsOneWidget,
      );

      // Invalid email should not validate
      await tester.enterText(find.byType(TextFormField), 'aa');
      await tester.pumpAndSettle();
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(
        find.text('L\'adresse courriel n\'est pas valide.'),
        findsOneWidget,
      );

      // Valid email should validate
      await tester.enterText(find.byType(TextFormField), 'aa@aa.aa');
      await tester.pumpAndSettle();
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Une adresse courriel est obligatoire.'), findsNothing);
      expect(find.text('L\'adresse courriel n\'est pas valide.'), findsNothing);
    });
  });
}
