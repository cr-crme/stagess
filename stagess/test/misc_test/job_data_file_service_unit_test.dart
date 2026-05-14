import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/helpers/program_helpers.dart';
import 'package:stagess_common/services/job_data_file_service.dart';

void main() {
  group('ActivitySectorsService', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize();

    test('sectors are loaded properly', () async {
      await ActivitySectorsService.initialize();
      expect(ActivitySectorsService.activitySectors, isNotEmpty);
    });

    test('specializations are loaded properly', () async {
      await ActivitySectorsService.initialize();
      expect(ActivitySectorsService.allSpecializations, isNotEmpty);
    });

    test('can get a sector back from a specialization', () async {
      await ActivitySectorsService.initialize();

      final specialization = ActivitySectorsService.allSpecializations[10];
      expect(() => specialization.sector, returnsNormally);

      final serialized = specialization.serialize();
      serialized['id'] = 'bad sector';
      final specializationWithBadSector =
          Specialization.fromSerialized(serialized);
      expect(() => specializationWithBadSector.sector, throwsException);
    });

    test('can get all or specified specialization', () async {
      await ActivitySectorsService.initialize();

      final specialization = ActivitySectorsService.allSpecializations[10];

      expect(ActivitySectorsService.specialization(specialization.id),
          specialization);

      // Throw if not found
      expect(() => ActivitySectorsService.specialization('not found'),
          throwsException);
    });
  });

  group('Serialization and deserialization', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(
      useActivitySectorsService: false,
      useRiskDataFileService: false,
      useQuestionFileService: false,
    );

    test('ActivitySectorList can serialize and deserialize', () async {
      // This test effectively tests the full serialization and deserialization chain

      await ActivitySectorsService.initialize();

      final sectors = ActivitySectorsService.activitySectors;
      final serializedSectors = sectors.serializeList();
      expect(
          () => sectors.deserializeItem(serializedSectors[0]), returnsNormally);

      final specializations = sectors[0].specializations;
      final serializedSpecializations = specializations.serializeList();
      expect(
          () => specializations.deserializeItem(serializedSpecializations[0]),
          returnsNormally);

      final skills = specializations[0].skills;
      final serializedSkills = skills.serializeList();
      expect(
          () => skills.deserializeItem(serializedSkills[0]), returnsNormally);
    });

    test('Lists on which serialize should not be called', () async {
      await ActivitySectorsService.initialize();

      expect(() => ActivitySectorsService.activitySectors.serialize(),
          throwsException);

      expect(
          () => ActivitySectorsService.activitySectors[0].specializations
              .serialize(),
          throwsException);

      expect(
          () =>
              ActivitySectorsService.allSpecializations[10].skills.serialize(),
          throwsException);
    });
  });

  group('SkillList', () {
    test('can create an empty list', () {
      expect(SkillList.empty(), isEmpty);
    });
  });

  group('Task', () {
    test('string is formatted properly', () {
      final mandatoryTask = Task.fromSerialized({'t': 'My task', 'o': false});
      expect(mandatoryTask.toString(), 'My task');

      final optionalTask = Task.fromSerialized({'t': 'My task', 'o': true});
      expect(optionalTask.toString(), 'My task (Facultative)');
    });
  });
}
