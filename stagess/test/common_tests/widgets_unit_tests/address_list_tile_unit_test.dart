import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/widgets/address_list_tile.dart';

import '../../utils.dart';
import '../utils.dart';
import 'utils.dart';

void main() {
  group('AddressListTile', () {
    testWidgets('renders a title', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          AddressListTile(
            title: 'Mon adresse de test',
            addressController: AddressController(),
            isMandatory: false,
            enabled: true,
          ),
        ),
      );

      expect(find.text('Mon adresse de test'), findsOneWidget);
    });

    testWidgets('renders a mandatory indicator', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          AddressListTile(
            title: 'Mon adresse de test',
            addressController: AddressController(),
            isMandatory: true,
            enabled: true,
          ),
        ),
      );

      expect(find.text('* Mon adresse de test'), findsOneWidget);
    });

    testWidgets('renders a search icon when address is empty', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          AddressListTile(
            addressController: AddressController(),
            isMandatory: false,
            enabled: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsNWidgets(1));
    });

    testWidgets('renders a map icon when address is not empty', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          AddressListTile(
            addressController: AddressController(initialValue: dummyAddress()),
            isMandatory: false,
            enabled: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.map), findsNWidgets(1));
    });

    testWidgets('icon is grey when address is empty, colored otherwise', (
      tester,
    ) async {
      final controller = AddressController();
      await tester.pumpWidget(
        declareWidget(
          AddressListTile(
            addressController: controller,
            isMandatory: false,
            enabled: true,
          ),
          loadTheme: true,
        ),
      );

      // Make sure the appareance is correct
      expect(
        tester.widget<Icon>(find.byIcon(Icons.search).last).color,
        Colors.grey,
      );

      // Type something in the text field
      final formFinder = find.byType(TextFormField);
      await tester.enterText(formFinder, 'My new address');
      await tester.pump();

      expect(
        tester.widget<Icon>(find.byIcon(Icons.search).last).color,
        Theme.of(tester.context(formFinder)).primaryColor,
      );
    });

    testWidgets('the form validates properly when not mandatory', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      bool first = true;
      final controller = AddressController(
        fromStringOverrideForDebug: (_) async {
          final out = dummyAddress(skipApartment: first);
          first = false;
          return out;
        },
        confirmAddressForDebug: (_) => true,
      );
      await tester.pumpWidget(
        declareWidget(
          Form(
            key: formKey,
            child: AddressListTile(
              addressController: controller,
              isMandatory: false,
              enabled: true,
            ),
          ),
        ),
      );
      // Submit the form
      await controller.requestValidation();
      await tester.runAsync(() async {
        await controller.waitForValidation();
      });
      expect(formKey.currentState!.validate(), isTrue);

      // Type something in the text field
      controller.address = dummyAddress();
      await tester.runAsync(() async {
        await controller.waitForValidation();
      });

      // Submit the form
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('the form validates properly when mandatory', (tester) async {
      final formKey = GlobalKey<FormState>();
      bool first = true;
      final controller = AddressController(
        fromStringOverrideForDebug: (_) async {
          final out = dummyAddress(skipApartment: first);
          first = false;
          return out;
        },
        confirmAddressForDebug: (_) => true,
      );
      await tester.pumpWidget(
        declareWidget(
          Form(
            key: formKey,
            child: AddressListTile(
              addressController: controller,
              isMandatory: true,
              enabled: true,
            ),
          ),
        ),
      );
      // Submit the form
      expect(formKey.currentState!.validate(), isFalse);

      // Type something in the text field
      controller.address = dummyAddress();
      await tester.runAsync(() async {
        await controller.waitForValidation();
      });

      // Submit the form
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('unfocussing the text field calls validate', (tester) async {
      final formKey = GlobalKey<FormState>();
      bool isValidated = false;
      final controller = AddressController(
        onAddressChangedCallback: () => isValidated = true,
        fromStringOverrideForDebug: (_) async => dummyAddress(),
        confirmAddressForDebug: (_) => true,
      );
      await tester.pumpWidget(
        declareWidget(
          Form(
            key: formKey,
            child: Column(
              children: [
                AddressListTile(
                  addressController: controller,
                  isMandatory: false,
                  enabled: true,
                ),
                const TextField(),
              ],
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        // Tapping in never triggers
        isValidated = false;
        await tester.tap(find.byType(TextFormField));
        await Future.delayed(const Duration(milliseconds: 5));
        expect(isValidated, isFalse);
      });
      await tester.runAsync(() async {
        // Tapping out the text field when empty does not validate
        isValidated = false;
        await tester.tap(find.byType(TextField).last);
        await Future.delayed(const Duration(milliseconds: 5));
        expect(isValidated, isFalse);
      });

      await tester.runAsync(() async {
        // Tapping in the text field when not empty does validate
        isValidated = false;
        await tester.enterText(find.byType(TextFormField), 'My new address');
        await tester.tap(find.byType(TextFormField).last);
        await Future.delayed(const Duration(milliseconds: 5));
        expect(isValidated, isFalse);
      });
      await tester.runAsync(() async {
        // Tapping out the text field when not empty does validate
        isValidated = false;
        await tester.enterText(find.byType(TextFormField), 'My new address');
        await tester.tap(find.byType(TextField).last);
        await Future.delayed(const Duration(milliseconds: 5));
        expect(isValidated, isTrue);
      });
    });

    testWidgets('renders a text field when enabled', (tester) async {
      await tester.pumpWidget(
        declareWidget(
          AddressListTile(
            addressController: AddressController(),
            isMandatory: false,
            enabled: true,
          ),
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);

      await tester.pumpWidget(
        declareWidget(
          AddressListTile(
            addressController: AddressController(),
            isMandatory: false,
            enabled: false,
          ),
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('can dynamically change the address', (tester) async {
      final addressController = AddressController(
        fromStringOverrideForDebug: (_) async => dummyAddress(),
        confirmAddressForDebug: (_) => true,
      );
      await tester.pumpWidget(
        declareWidget(
          AddressListTile(
            addressController: addressController,
            isMandatory: false,
            enabled: true,
          ),
        ),
      );

      expect(find.text(''), findsOneWidget);
      expect(addressController.address?.toString() ?? '', '');

      addressController.address = dummyAddress();
      await tester.runAsync(() async {
        await addressController.waitForValidation();
      });
      expect(addressController.address.toString(), dummyAddress().toString());
      await tester.pumpAndSettle();
      expect(find.text(dummyAddress().toString()), findsOneWidget);
    });

    testWidgets('can validate the address while not being mandatory', (
      tester,
    ) async {
      await tester.runAsync(() async {
        bool addressHasChanged = false;

        final addressController = AddressController(
          onAddressChangedCallback: () {
            return addressHasChanged = true;
          },
          fromStringOverrideForDebug: (_) async => dummyAddress(),
          confirmAddressForDebug: (_) => true,
        );
        await tester.pumpWidget(
          declareWidget(
            AddressListTile(
              addressController: addressController,
              isMandatory: false,
              enabled: true,
            ),
          ),
        );
        // Address is valid, even though it is empty
        expect(await addressController.requestValidation(), null);

        // Make a change to the address, which automatically triggers the
        // validation request. But also call it manually so they collide,
        // effectively testing the mutex
        addressHasChanged = false;
        addressController.address = dummyAddress(skipApartment: true);
        expect(await addressController.requestValidation(), null);
        expect(addressHasChanged, isTrue);
      });
    });

    testWidgets('can validate the address while being mandatory', (
      tester,
    ) async {
      final addressController = AddressController(
        fromStringOverrideForDebug: (_) async => dummyAddress(),
      );
      await tester.pumpWidget(
        declareWidget(
          AddressListTile(
            addressController: addressController,
            isMandatory: true,
            enabled: true,
          ),
        ),
      );
      // Address is valid, even though it is empty
      expect(
        await addressController.requestValidation(),
        'Entrer une adresse valide',
      );
    });

    testWidgets('refuses the validation if address is invalid', (tester) async {
      await tester.runAsync(() async {
        final addressController = AddressController(
          fromStringOverrideForDebug: (_) async => throw 'Invalid address',
        );
        await tester.pumpWidget(
          declareWidget(
            AddressListTile(
              addressController: addressController,
              isMandatory: false,
              enabled: true,
            ),
          ),
        );
        // Address is valid, even though it is empty
        addressController.address = dummyAddress(skipApartment: true);
        await Future.delayed(const Duration(milliseconds: 50));
        expect(
          await addressController.requestValidation(),
          'L\'adresse n\'a pu être trouvée',
        );
      });
    });

    testWidgets('refuses the validation if address is refused by the user', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final addressController = AddressController(
          fromStringOverrideForDebug: (_) async => dummyAddress(),
          confirmAddressForDebug: (_) => false,
        );
        await tester.pumpWidget(
          declareWidget(
            AddressListTile(
              addressController: addressController,
              isMandatory: false,
              enabled: true,
            ),
          ),
        );
        // Address is valid, even though it is empty
        addressController.address = dummyAddress(skipApartment: true);
        await Future.delayed(const Duration(milliseconds: 5));
        expect(
          await addressController.requestValidation(),
          'Essayer une nouvelle adresse',
        );
      });
    });
  });
}
