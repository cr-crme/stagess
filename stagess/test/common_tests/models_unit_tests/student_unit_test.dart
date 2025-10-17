import 'package:flutter_test/flutter_test.dart';
import 'package:stagess/common/extensions/students_extension.dart';
import 'package:stagess/program_helpers.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

import '../../utils.dart';
import '../utils.dart';

void main() {
  group('Student', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(mockMe: true);

    test('"Program" is shown properly', () {
      expect(Program.values.length, 3);
      expect(Program.fpt.toString(), 'FPT');
      expect(Program.fms.toString(), 'FMS');
      expect(Program.undefined.toString(), 'À déterminer');
    });

    testWidgets('"asActive" behaves properly', (tester) async {
      final context = await tester.contextWithNotifiers(withInternships: true);
      final student = dummyStudent();

      // Add an internship to another student
      InternshipsProvider.of(
        context,
        listen: false,
      ).add(dummyInternship(studentId: 'anotherStudentId'));

      // Start without an internship
      expect(student.hasActiveInternship(context), isFalse);

      // Add an internship to the student
      InternshipsProvider.of(
        context,
        listen: false,
      ).add(dummyInternship(studentId: student.id));

      // Now the student has an internship
      expect(student.hasActiveInternship(context), isTrue);
    });

    test('"limitedInfo" provides less information', () {
      final student = dummyStudent();
      final limitedInfo = student.limitedInfo;

      expect(limitedInfo.id, student.id);
      expect(limitedInfo.firstName, student.firstName);
      expect(limitedInfo.middleName, student.middleName);
      expect(limitedInfo.lastName, student.lastName);
      expect(limitedInfo.group, student.group);
      expect(limitedInfo.program, student.program);
      expect(limitedInfo.address.toString(), Address.empty.toString());
      expect(limitedInfo.contact.toString(), Person.empty.toString());
      expect(limitedInfo.contactLink, '');
      expect(limitedInfo.dateBirth, isNull);
      expect(limitedInfo.email, isNull);
      expect(limitedInfo.phone.toString(), PhoneNumber.empty.toString());
    });

    test('"copyWith" behave properly', () {
      final student = dummyStudent();

      final studentSame = student.copyWith();
      expect(studentSame.id, student.id);
      expect(studentSame.firstName, student.firstName);
      expect(studentSame.middleName, student.middleName);
      expect(studentSame.lastName, student.lastName);
      expect(studentSame.dateBirth, student.dateBirth);
      expect(studentSame.phone, student.phone);
      expect(studentSame.email, student.email);
      expect(studentSame.group, student.group);
      expect(studentSame.address, student.address);
      expect(studentSame.photo, student.photo);
      expect(studentSame.program, student.program);
      expect(studentSame.contact, student.contact);
      expect(studentSame.contactLink, student.contactLink);

      final studentDifferent = student.copyWith(
        id: 'newId',
        firstName: 'newFirstName',
        middleName: 'newMiddleName',
        lastName: 'newLastName',
        dateBirth: DateTime(2001, 1, 1),
        phone: PhoneNumber.fromString('866-666-6666'),
        email: 'newEmail',
        address: dummyAddress().copyWith(id: 'newAddressId'),
        photo: '0xFF0000',
        program: Program.fms,
        group: 'newGroup',
        contact: dummyPerson().copyWith(id: 'newContactId'),
        contactLink: 'newContactLink',
      );

      expect(studentDifferent.id, 'newId');
      expect(studentDifferent.firstName, 'newFirstName');
      expect(studentDifferent.middleName, 'newMiddleName');
      expect(studentDifferent.lastName, 'newLastName');
      expect(studentDifferent.dateBirth, DateTime(2001, 1, 1));
      expect(studentDifferent.phone.toString(), '(866) 666-6666');
      expect(studentDifferent.email, 'newEmail');
      expect(studentDifferent.address?.id, 'newAddressId');
      expect(studentDifferent.photo.toString(), '0xFF0000');
      expect(studentDifferent.program, Program.fms);
      expect(studentDifferent.group, 'newGroup');
      expect(studentDifferent.contact.id, 'newContactId');
      expect(studentDifferent.contactLink, 'newContactLink');
    });

    test('serialization and deserialization works', () {
      final student = dummyStudent();
      final serialized = student.serialize();
      final deserialized = Student.fromSerialized(serialized);

      expect(serialized, {
        'id': student.id,
        'version': Student.currentVersion,
        'school_board_id': student.schoolBoardId,
        'school_id': student.schoolId,
        'first_name': student.firstName,
        'middle_name': student.middleName,
        'last_name': student.lastName,
        'date_birth': student.dateBirth!.millisecondsSinceEpoch,
        'phone': student.phone?.serialize(),
        'email': student.email,
        'address': student.address?.serialize(),
        'photo': student.photo,
        'program': student.program.index,
        'group': student.group,
        'contact': student.contact.serialize(),
        'contact_link': student.contactLink,
      });

      expect(deserialized.id, student.id);
      expect(deserialized.schoolBoardId, student.schoolBoardId);
      expect(deserialized.schoolId, student.schoolId);
      expect(deserialized.firstName, student.firstName);
      expect(deserialized.middleName, student.middleName);
      expect(deserialized.lastName, student.lastName);
      expect(deserialized.dateBirth, student.dateBirth);
      expect(deserialized.phone.toString(), student.phone.toString());
      expect(deserialized.email, student.email);
      expect(deserialized.address?.id, student.address?.id);
      expect(deserialized.photo, student.photo);
      expect(deserialized.program, student.program);
      expect(deserialized.group, student.group);
      expect(deserialized.contact.id, student.contact.id);
      expect(deserialized.contactLink, student.contactLink);

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized = Student.fromSerialized({'id': 'emptyId'});
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.firstName, '');
      expect(emptyDeserialized.middleName, isNull);
      expect(emptyDeserialized.lastName, '');
      expect(emptyDeserialized.dateBirth, isNull);
      expect(emptyDeserialized.phone, isNull);
      expect(emptyDeserialized.email, isNull);
      expect(emptyDeserialized.address, isNull);
      expect(int.parse(emptyDeserialized.photo), greaterThanOrEqualTo(0));
      expect(int.parse(emptyDeserialized.photo), lessThanOrEqualTo(0xFFFFFF));
      expect(emptyDeserialized.program, Program.undefined);
      expect(emptyDeserialized.group, '-1');
      expect(emptyDeserialized.contact.toString(), Person.empty.toString());
      expect(emptyDeserialized.contactLink, '');
    });
  });
}
