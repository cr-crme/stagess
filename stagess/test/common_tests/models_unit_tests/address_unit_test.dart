import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common/models/generic/address.dart';

import '../utils.dart';

void main() {
  group('Address', () {
    test('is shown properly', () {
      expect(
          dummyAddress().toString(), '100 Wunderbar #A, Wonderland, H0H 0H0');
      expect(dummyAddress(skipApartment: true).toString(),
          '100 Wunderbar, Wonderland, H0H 0H0');
    });

    test('"copyWith" changes the requested elements', () {
      final address = dummyAddress();

      final addressSame = address.copyWith();
      expect(addressSame.id, address.id);
      expect(addressSame.civicNumber, address.civicNumber);
      expect(addressSame.street, address.street);
      expect(addressSame.apartment, address.apartment);
      expect(addressSame.city, address.city);
      expect(addressSame.postalCode, address.postalCode);

      final addressDifferent = address.copyWith(
        id: 'newId',
        civicNumber: 200,
        street: 'Wonderbar',
        apartment: 'B',
        city: 'Wunderland',
        postalCode: 'H0H 0H1',
      );
      expect(addressDifferent.id, 'newId');
      expect(addressDifferent.civicNumber, 200);
      expect(addressDifferent.street, 'Wonderbar');
      expect(addressDifferent.apartment, 'B');
      expect(addressDifferent.city, 'Wunderland');
      expect(addressDifferent.postalCode, 'H0H 0H1');
    });

    test('"isEmpty" returns true when all fields are null', () {
      expect(Address.empty.isEmpty, isTrue);
      expect(Address(civicNumber: 100).isEmpty, isFalse);
    });

    test('"isValid" if all fields are not null expect apartment', () {
      expect(dummyAddress().isValid, isTrue);
      expect(dummyAddress(skipCivicNumber: true).isValid, isFalse);
      expect(dummyAddress(skipApartment: true).isValid, isTrue);
      expect(dummyAddress(skipStreet: true).isValid, isFalse);
      expect(dummyAddress(skipCity: true).isValid, isFalse);
      expect(dummyAddress(skipPostalCode: true).isValid, isFalse);
    });

    test('serialization and deserialization works', () {
      final address = dummyAddress();
      final serialized = address.serialize();
      final deserialized = Address.fromSerialized(serialized);

      expect(serialized, {
        'id': address.id,
        'civic': address.civicNumber,
        'street': address.street,
        'apartment': address.apartment,
        'city': address.city,
        'latitude': null,
        'longitude': null,
        'postal_code': address.postalCode
      });

      expect(deserialized.id, address.id);
      expect(deserialized.civicNumber, address.civicNumber);
      expect(deserialized.street, address.street);
      expect(deserialized.apartment, address.apartment);
      expect(deserialized.city, address.city);
      expect(deserialized.postalCode, address.postalCode);

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = Address.fromSerialized({'id': 'emptyId'});
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.civicNumber, isNull);
      expect(emptyDeserialized.street, isNull);
      expect(emptyDeserialized.apartment, isNull);
      expect(emptyDeserialized.city, isNull);
      expect(emptyDeserialized.postalCode, isNull);
    });
  });
}
