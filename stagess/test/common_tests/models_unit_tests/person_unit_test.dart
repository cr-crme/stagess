import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/persons/person.dart';

import '../utils.dart';

void main() {
  group('Person', () {
    test('default is empty', () {
      final person = Person.empty;
      expect(person.firstName, '');
      expect(person.middleName, isNull);
      expect(person.lastName, '');
      expect(person.dateBirth, isNull);
      expect(person.phone, isNull);
      expect(person.email, isNull);
      expect(person.address, isNull);

      expect(person.toString(), Person.empty.toString());
      expect(person.fullName, '');
    });

    test('is shown properly', () {
      final person = dummyPerson();
      expect(person.toString(), 'Jeanne Kathlin Doe');
      expect(person.fullName, 'Jeanne Doe');
    });

    test('"copyWith" changes the requested elements', () {
      final person = dummyPerson();

      final personSame = person.copyWith();
      expect(personSame.id, person.id);
      expect(personSame.firstName, person.firstName);
      expect(personSame.lastName, person.lastName);
      expect(personSame.email, person.email);
      expect(personSame.phone, person.phone);
      expect(personSame.address, person.address);

      final personDifferent = person.copyWith(
        id: 'newId',
        firstName: 'newFirstName',
        lastName: 'newLastName',
        email: 'newEmail',
        phone: PhoneNumber.fromString('866-666-6666'),
        address: dummyAddress().copyWith(id: 'newAddressId'),
      );

      expect(personDifferent.id, 'newId');
      expect(personDifferent.firstName, 'newFirstName');
      expect(personDifferent.lastName, 'newLastName');
      expect(personDifferent.email, 'newEmail');
      expect(personDifferent.phone.toString(), '(866) 666-6666');
      expect(personDifferent.address?.id, 'newAddressId');
    });

    test('serialization and deserialization works', () {
      final person = dummyPerson();
      final serialized = person.serialize();
      final deserialized = Person.fromSerialized(serialized);

      expect(serialized, {
        'id': person.id,
        'first_name': person.firstName,
        'middle_name': person.middleName,
        'last_name': person.lastName,
        'date_birth': person.dateBirth?.serialize() ?? -1,
        'phone': person.phone?.serialize(),
        'email': person.email?.serialize(),
        'address': person.address?.serialize(),
      });

      expect(deserialized.id, person.id);
      expect(deserialized.firstName, person.firstName);
      expect(deserialized.middleName, person.middleName);
      expect(deserialized.lastName, person.lastName);
      expect(deserialized.dateBirth, person.dateBirth);
      expect(deserialized.phone.toString(), person.phone.toString());
      expect(deserialized.email, person.email);
      expect(deserialized.address?.id, person.address?.id);

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = Person.fromSerialized({'id': 'emptyId'});
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.firstName, '');
      expect(emptyDeserialized.middleName, isNull);
      expect(emptyDeserialized.lastName, '');
      expect(emptyDeserialized.dateBirth, isNull);
      expect(emptyDeserialized.phone, isNull);
      expect(emptyDeserialized.email, isNull);
      expect(emptyDeserialized.address, isNull);
    });
  });
}
