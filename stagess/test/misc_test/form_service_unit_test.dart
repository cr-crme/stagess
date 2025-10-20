import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';

void main() {
  group('FormService with widgets', () {
    testWidgets('validateForm with snackbar', (tester) async {
      final formKey = GlobalKey<FormState>();
      bool shouldValidate = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                validator: (text) => shouldValidate ? null : 'My error',
              ),
            ),
          ),
        ),
      );

      expect(FormService.validateForm(formKey), isTrue);

      shouldValidate = false;
      expect(
        FormService.validateForm(formKey, showSnackbarError: true),
        isFalse,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Remplir tous les champs avec un *.'), findsOneWidget);
    });

    testWidgets('validateForm without snackbar', (tester) async {
      final formKey = GlobalKey<FormState>();
      bool shouldValidate = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                validator: (text) => shouldValidate ? null : 'My error',
              ),
            ),
          ),
        ),
      );

      expect(FormService.validateForm(formKey), isTrue);

      shouldValidate = false;
      expect(
        FormService.validateForm(formKey, showSnackbarError: false),
        isFalse,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Remplir tous les champs avec un *.'), findsNothing);
    });

    testWidgets('calls save if validate and requested', (tester) async {
      final formKey = GlobalKey<FormState>();
      bool shouldValidate = true;
      String? savedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                validator: (text) => shouldValidate ? null : 'My error',
                onSaved: (text) => savedValue = 'Saved!',
              ),
            ),
          ),
        ),
      );

      shouldValidate = false;
      expect(FormService.validateForm(formKey, save: true), isFalse);
      expect(savedValue, isNull);

      shouldValidate = true;
      expect(FormService.validateForm(formKey, save: true), isTrue);
      expect(savedValue, 'Saved!');
    });

    testWidgets('should not call save if validate but not requested', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      bool shouldValidate = true;
      String? savedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                validator: (text) => shouldValidate ? null : 'My error',
                onSaved: (text) => savedValue = 'Saved!',
              ),
            ),
          ),
        ),
      );

      shouldValidate = false;
      expect(FormService.validateForm(formKey, save: false), isFalse);
      expect(savedValue, isNull);

      shouldValidate = true;
      expect(FormService.validateForm(formKey, save: false), isTrue);
      expect(savedValue, isNull);
    });
  });

  group('FormService without widgets', () {
    test('textNotEmptyValidator', () {
      expect(
        FormService.textNotEmptyValidator(''),
        'Le champ ne peut pas être vide.',
      );

      expect(FormService.textNotEmptyValidator('My text'), isNull);
    });

    test('neqValidator', () {
      const errorMessage = 'Le NEQ est composé de 10 chiffres.';
      expect(FormService.neqValidator(''), 'Un NEQ doit être spécifié');
      expect(FormService.neqValidator('1234567890'), isNull);
      expect(FormService.neqValidator('123456789'), errorMessage);
      expect(FormService.neqValidator('12345678901'), errorMessage);
      expect(FormService.neqValidator('abcdefghij'), errorMessage);
    });

    test('phoneValidator', () {
      const errorMessage = 'Le numéro entré n\'est pas valide.';
      expect(
        FormService.phoneValidator(''),
        'Un numéro de téléphone est obligatoire.',
      );
      expect(FormService.phoneValidator('1234567890'), isNull);
      expect(FormService.phoneValidator('123456789'), errorMessage);
      expect(FormService.phoneValidator('12345678901'), errorMessage);
      expect(FormService.phoneValidator('abcdefghij'), errorMessage);
    });

    test('emailValidator', () {
      const errorMessage = 'L\'adresse courriel n\'est pas valide.';
      expect(
        FormService.emailValidator(''),
        'Une adresse courriel est obligatoire.',
      );
      expect(FormService.emailValidator('aa@aa.aa'), isNull);
      expect(FormService.emailValidator('aa@aa'), errorMessage);
      expect(FormService.emailValidator('aa.aa'), errorMessage);
      expect(FormService.emailValidator('aa@aa.'), errorMessage);
      expect(FormService.emailValidator('aa@.aa'), errorMessage);
      expect(FormService.emailValidator('@aa.aa'), errorMessage);
    });

    test('usernameValidator', () {
      expect(
        FormService.usernameValidator(''),
        'Un nom d\'utilisateur est requis.',
      );
      expect(FormService.usernameValidator('My username'), isNull);
    });

    test('passwordValidator', () {
      const errorMessage = 'Le mot de passe ne répond pas aux critères.';
      expect(
        FormService.passwordValidator(''),
        'Le champ ne peut pas être vide.',
      );
      expect(FormService.passwordValidator('1234567'), errorMessage);
      expect(FormService.passwordValidator('12345678'), isNull);
    });

    test('passwordConfirmationValidator', () {
      expect(
        FormService.passwordConfirmationValidator('My password', ''),
        'Le mot de passe ne peut pas être vide.',
      );
      expect(
        FormService.passwordConfirmationValidator('', 'My password'),
        'Les mots de passe ne sont pas identiques.',
      );
      expect(
        FormService.passwordConfirmationValidator('My password', 'My password'),
        isNull,
      );
      expect(
        FormService.passwordConfirmationValidator(
          'My password',
          'My password2',
        ),
        'Les mots de passe ne sont pas identiques.',
      );
    });
  });
}
