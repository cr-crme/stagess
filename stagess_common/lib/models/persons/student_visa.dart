import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/repeatable_items.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

export 'package:stagess_common/models/generic/repeatable_items.dart';

class ExperiencesAndAptitudes extends RepeatableItem {
  final String text;

  ExperiencesAndAptitudes({
    super.id,
    required super.index,
    required super.isSelected,
    required this.text,
  });

  ExperiencesAndAptitudes.fromSerialized(super.map)
      : text = StringExt.from(map?['text']) ?? '',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() =>
      super.serializedMap()..addAll({'text': text.serialize()});

  static FetchableFields get fetchableFields => RepeatableItem.fetchableFields
    ..addAll(FetchableFields.reference({
      'text': FetchableFields.optional,
    }));

  @override
  ExperiencesAndAptitudes copyWith({
    int? index,
    bool? isSelected,
    String? text,
  }) =>
      ExperiencesAndAptitudes(
        id: id,
        index: index ?? this.index,
        isSelected: isSelected ?? this.isSelected,
        text: text ?? this.text,
      );
}

class AttestationsAndMentions extends RepeatableItem {
  final String text;

  AttestationsAndMentions({
    super.id,
    required super.index,
    required super.isSelected,
    required this.text,
  });

  AttestationsAndMentions.fromSerialized(super.map)
      : text = StringExt.from(map?['text']) ?? '',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() =>
      super.serializedMap()..addAll({'text': text.serialize()});

  static FetchableFields get fetchableFields => RepeatableItem.fetchableFields
    ..addAll(FetchableFields.reference({
      'text': FetchableFields.optional,
    }));

  @override
  AttestationsAndMentions copyWith({
    int? index,
    bool? isSelected,
    String? text,
  }) =>
      AttestationsAndMentions(
        id: id,
        index: index ?? this.index,
        isSelected: isSelected ?? this.isSelected,
        text: text ?? this.text,
      );
}

class SstTraining extends RepeatableItem {
  final String trainingId;
  bool isHidden;
  bool get isNotHidden => !isHidden;

  SstTraining({
    super.id,
    required super.index,
    required super.isSelected,
    required this.trainingId,
    required this.isHidden,
  });

  SstTraining.fromSerialized(super.map)
      : trainingId = StringExt.from(map?['training_id']) ?? '',
        isHidden = BoolExt.from(map?['is_hidden']) ?? false,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'training_id': trainingId.serialize(),
      'is_hidden': isHidden.serialize(),
    });

  static FetchableFields get fetchableFields => RepeatableItem.fetchableFields
    ..addAll(FetchableFields.reference({
      'training_id': FetchableFields.optional,
      'is_hidden': FetchableFields.optional,
    }));

  static Map<String, String> get availableTrainings => {
        '0001': 'Manutention sécuritaire',
        '0002': 'Utilisation d\'un exacto',
        '0003': 'Prévention des troubles musculosquelettiques',
        '0004': 'Substances potentiellement dangereuses pour la santé',
        '0005': 'Utilisation exemplaire des EPI (raison, tâche, comment / quel modèle choisir)'
            'comment les entretenir, comment les ajuster, comment les nettoyer, '
            'comment les mettre / enlever)',
        '0006': 'Conduite de chariot élévateur',
        '0007': 'Utilisation d\'échelles ou d\'escabeaux',
      };

  @override
  SstTraining copyWith({
    int? index,
    bool? isSelected,
    String? trainingId,
    bool? isHidden,
  }) {
    return SstTraining(
      id: id,
      index: index ?? this.index,
      isSelected: isSelected ?? this.isSelected,
      trainingId: trainingId ?? this.trainingId,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}

enum CertificateType {
  fpt,
  fms,
  none;

  static CertificateType fromString(String value) => switch (value) {
        'FPT' => CertificateType.fpt,
        'FMS' => CertificateType.fms,
        '__NONE__' => CertificateType.none,
        _ => throw ArgumentError('Invalid certificate type: $value')
      };

  String get name =>
      switch (this) { fpt => 'FPT', fms => 'FMS', none => '__NONE__' };
}

class Certificate extends RepeatableItem {
  final CertificateType certificateType;
  final int? year;
  final String? specializationId;

  Certificate({
    super.id,
    required super.index,
    required super.isSelected,
    required this.certificateType,
    this.specializationId,
    this.year,
  });

  Certificate.fromSerialized(super.map)
      : certificateType = CertificateType.fromString(
            StringExt.from(map?['certificate_type']) ?? '__NONE__'),
        specializationId = StringExt.from(map?['specialization_id']),
        year = IntExt.from(map?['year']),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'certificate_type': certificateType.name.serialize(),
      'specialization_id': specializationId?.serialize(),
      'year': year?.serialize(),
    });

  static FetchableFields get fetchableFields => RepeatableItem.fetchableFields
    ..addAll(FetchableFields.reference({
      'certificate_type': FetchableFields.optional,
      'specialization_id': FetchableFields.optional,
      'year': FetchableFields.optional,
    }));

  @override
  Certificate copyWith({
    int? index,
    bool? isSelected,
    CertificateType? certificateType,
    String? specializationId,
    int? year,
  }) {
    return Certificate(
      id: id,
      index: index ?? this.index,
      isSelected: isSelected ?? this.isSelected,
      certificateType: certificateType ?? this.certificateType,
      specializationId: specializationId ?? this.specializationId,
      year: year ?? this.year,
    );
  }
}

class Skill extends RepeatableItem {
  final String skillId;

  Skill({
    super.id,
    required super.index,
    required super.isSelected,
    required this.skillId,
  });

  Skill.fromSerialized(super.map)
      : skillId = StringExt.from(map?['skill_id']) ?? '',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() =>
      super.serializedMap()..addAll({'skill_id': skillId.serialize()});

  static FetchableFields get fetchableFields => RepeatableItem.fetchableFields
    ..addAll(FetchableFields.reference({
      'skill_id': FetchableFields.optional,
    }));

  @override
  Skill copyWith({
    int? index,
    bool? isSelected,
    String? skillId,
  }) =>
      Skill(
        id: id,
        index: index ?? this.index,
        isSelected: isSelected ?? this.isSelected,
        skillId: skillId ?? this.skillId,
      );
}

class Reference extends RepeatableItem {
  final String referee;
  final String enterprise;
  final PhoneNumber phoneNumber;
  final String email;
  final String supplementaryInfo;

  Reference({
    super.id,
    required super.index,
    required super.isSelected,
    required this.referee,
    required this.enterprise,
    required this.phoneNumber,
    required this.email,
    required this.supplementaryInfo,
  });

  Reference.fromSerialized(super.map)
      : referee = StringExt.from(map?['referee']) ?? '',
        enterprise = StringExt.from(map?['enterprise']) ?? '',
        phoneNumber = PhoneNumber.fromString(map?['phone_number']),
        email = StringExt.from(map?['email']) ?? '',
        supplementaryInfo = StringExt.from(map?['supplementary_info']) ?? '',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'referee': referee.serialize(),
      'enterprise': enterprise.serialize(),
      'phone_number': phoneNumber.toString(),
      'email': email.serialize(),
      'supplementary_info': supplementaryInfo.serialize(),
    });

  static FetchableFields get fetchableFields => RepeatableItem.fetchableFields
    ..addAll(FetchableFields.reference({
      'referee': FetchableFields.optional,
      'enterprise': FetchableFields.optional,
      'phone_number': FetchableFields.optional,
      'email': FetchableFields.optional,
      'supplementary_info': FetchableFields.optional,
    }));

  @override
  Reference copyWith({
    int? index,
    bool? isSelected,
    String? referee,
    String? enterprise,
    PhoneNumber? phoneNumber,
    String? email,
    String? supplementaryInfo,
  }) {
    return Reference(
      id: id,
      index: index ?? this.index,
      isSelected: isSelected ?? this.isSelected,
      referee: referee ?? this.referee,
      enterprise: enterprise ?? this.enterprise,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      supplementaryInfo: supplementaryInfo ?? this.supplementaryInfo,
    );
  }
}

class Attitude extends RepeatableItem {
  final String attitudeId;

  Attitude({
    super.id,
    required super.index,
    required super.isSelected,
    required this.attitudeId,
  });

  Attitude.fromSerialized(super.map)
      : attitudeId = StringExt.from(map?['attitude_id']) ?? '',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() =>
      super.serializedMap()..addAll({'attitude_id': attitudeId.serialize()});

  static FetchableFields get fetchableFields => RepeatableItem.fetchableFields
    ..addAll(FetchableFields.reference({
      'attitude_id': FetchableFields.optional,
    }));

  static Map<String, String> get availableItems => {
        '0001': 'Ponctualité',
        '0002': 'Assuiduité',
        '0003': 'Qualité du travail',
        '0004': 'Rendement et constance',
        '0005': 'Communication avec l\'équipe',
        '0006': 'Respect des personnes en autorité',
        '0007': 'Communication au sujet de la SST',
        '0008': 'Matrise de soi',
        '0009': 'Prise d\'initiative',
        '0010': 'Adaptation aux changements',
      };

  @override
  Attitude copyWith({
    int? index,
    bool? isSelected,
    String? attitudeId,
  }) =>
      Attitude(
        id: id,
        index: index ?? this.index,
        isSelected: isSelected ?? this.isSelected,
        attitudeId: attitudeId ?? this.attitudeId,
      );
}

class SuccessConditions extends RepeatableItem {
  final String text;

  SuccessConditions({
    super.id,
    required super.index,
    required super.isSelected,
    required this.text,
  });

  SuccessConditions.fromSerialized(super.map)
      : text = StringExt.from(map?['text']) ?? '',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() =>
      super.serializedMap()..addAll({'text': text.serialize()});

  static FetchableFields get fetchableFields => RepeatableItem.fetchableFields
    ..addAll(FetchableFields.reference({
      'text': FetchableFields.optional,
    }));

  @override
  SuccessConditions copyWith({
    int? index,
    bool? isSelected,
    String? text,
  }) =>
      SuccessConditions(
        id: id,
        index: index ?? this.index,
        isSelected: isSelected ?? this.isSelected,
        text: text ?? this.text,
      );
}

class VisaForm extends ItemSerializable {
  final List<ExperiencesAndAptitudes> experiencesAndAptitudes;
  final List<AttestationsAndMentions> attestationsAndMentions;
  final List<SstTraining> sstTrainings;

  final bool isGatewayToFmsAvailable;
  final List<Certificate> certificates;
  final List<Skill> skills;
  final List<Reference> references;

  final List<Attitude> forces;
  final List<Attitude> challenges;

  final List<SuccessConditions> successConditions;

  VisaForm({
    super.id,
    required this.experiencesAndAptitudes,
    required this.attestationsAndMentions,
    required this.sstTrainings,
    required this.isGatewayToFmsAvailable,
    required this.certificates,
    required this.skills,
    required this.references,
    required this.forces,
    required this.challenges,
    required this.successConditions,
  }) {
    _sortAllByIndices();
  }

  VisaForm.fromSerialized(super.map)
      : experiencesAndAptitudes = (map?['experiences_and_aptitudes'] as List?)
                ?.map((e) => ExperiencesAndAptitudes.fromSerialized(e))
                .toList() ??
            [],
        attestationsAndMentions = (map?['attestations_and_mentions'] as List?)
                ?.map((e) => AttestationsAndMentions.fromSerialized(e))
                .toList() ??
            [],
        sstTrainings = (map?['sst_trainings'] as List?)
                ?.map((e) => SstTraining.fromSerialized(e))
                .toList() ??
            [],
        isGatewayToFmsAvailable =
            BoolExt.from(map?['is_gateway_to_fms_available']) ?? false,
        certificates = (map?['certificates'] as List?)
                ?.map((e) => Certificate.fromSerialized(e))
                .toList() ??
            [],
        skills = (map?['skills'] as List?)
                ?.map((e) => Skill.fromSerialized(e))
                .toList() ??
            [],
        references = (map?['references'] as List?)
                ?.map((e) => Reference.fromSerialized(e))
                .toList() ??
            [],
        forces = (map?['forces'] as List?)
                ?.map((e) => Attitude.fromSerialized(e))
                .toList() ??
            [],
        challenges = (map?['challenges'] as List?)
                ?.map((e) => Attitude.fromSerialized(e))
                .toList() ??
            [],
        successConditions = (map?['success_conditions'] as List?)
                ?.map((e) => SuccessConditions.fromSerialized(e))
                .toList() ??
            [],
        super.fromSerialized() {
    _sortAllByIndices();
  }

  void _sortAllByIndices() {
    experiencesAndAptitudes.sort((a, b) => a.index.compareTo(b.index));
    attestationsAndMentions.sort((a, b) => a.index.compareTo(b.index));
    sstTrainings.sort((a, b) => a.index.compareTo(b.index));
    certificates.sort((a, b) => a.index.compareTo(b.index));
    skills.sort((a, b) => a.index.compareTo(b.index));
    references.sort((a, b) => a.index.compareTo(b.index));
    forces.sort((a, b) => a.index.compareTo(b.index));
    challenges.sort((a, b) => a.index.compareTo(b.index));
    successConditions.sort((a, b) => a.index.compareTo(b.index));
  }

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'experiences_and_aptitudes': experiencesAndAptitudes.serialize(),
      'attestations_and_mentions': attestationsAndMentions.serialize(),
      'sst_trainings': sstTrainings.serialize(),
      'is_gateway_to_fms_available': isGatewayToFmsAvailable,
      'certificates': certificates.serialize(),
      'skills': skills.serialize(),
      'references': references.serialize(),
      'forces': forces.serialize(),
      'challenges': challenges.serialize(),
      'success_conditions': successConditions.serialize(),
    };
  }

  VisaForm copyWith({
    List<ExperiencesAndAptitudes>? experiencesAndAptitudes,
    List<AttestationsAndMentions>? attestationsAndMentions,
    List<SstTraining>? sstTrainings,
    bool? isGatewayToFmsAvailable,
    List<Certificate>? certificates,
    List<Skill>? skills,
    List<Reference>? references,
    List<Attitude>? forces,
    List<Attitude>? challenges,
    List<SuccessConditions>? successConditions,
  }) {
    return VisaForm(
      id: id,
      experiencesAndAptitudes:
          experiencesAndAptitudes ?? this.experiencesAndAptitudes,
      attestationsAndMentions:
          attestationsAndMentions ?? this.attestationsAndMentions,
      sstTrainings: sstTrainings ?? this.sstTrainings,
      isGatewayToFmsAvailable:
          isGatewayToFmsAvailable ?? this.isGatewayToFmsAvailable,
      certificates: certificates ?? this.certificates,
      skills: skills ?? this.skills,
      references: references ?? this.references,
      forces: forces ?? this.forces,
      challenges: challenges ?? this.challenges,
      successConditions: successConditions ?? this.successConditions,
    );
  }

  @override
  String toString() {
    return 'VisaEvaluation{'
        'experiencesAndAptitudes: ${experiencesAndAptitudes.toString()}'
        ', attestationsAndMentions: ${attestationsAndMentions.toString()}'
        ', sstTrainings: ${sstTrainings.toString()}'
        ', isGatewayToFmsAvailable: $isGatewayToFmsAvailable'
        ', certificates: ${certificates.toString()}'
        ', skills: ${skills.toString()}'
        ', references: ${references.toString()}'
        ', forces: ${forces.toString()}'
        ', challenges: ${challenges.toString()}'
        ', successConditions: ${successConditions.toString()}'
        '}';
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'experiences_and_aptitudes': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': ExperiencesAndAptitudes.fetchableFields,
          })),
        'attestations_and_mentions': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': AttestationsAndMentions.fetchableFields,
          })),
        'sst_trainings': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': SstTraining.fetchableFields,
          })),
        'is_gateway_to_fms_available': FetchableFields.optional,
        'certificates': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': Certificate.fetchableFields,
          })),
        'skills': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': Skill.fetchableFields,
          })),
        'references': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': Reference.fetchableFields,
          })),
        'forces': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': Attitude.fetchableFields,
          })),
        'challenges': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': Attitude.fetchableFields,
          })),
        'success_conditions': FetchableFields.optional
          ..addAll(FetchableFields.reference({
            '*': SuccessConditions.fetchableFields,
          })),
      });
}

class StudentVisa extends ItemSerializable {
  static const String currentVersion = '1.0.0';

  DateTime date;
  VisaForm form;
  // The version of the evaluation form (so data can be parsed properly)
  String formVersion;

  StudentVisa({
    super.id,
    required this.date,
    required this.form,
    required this.formVersion,
  });
  StudentVisa.fromSerialized(super.map)
      : date = DateTimeExt.from(map?['date']) ?? DateTime(0),
        form = VisaForm.fromSerialized(map?['form'] ?? {}),
        formVersion = map?['form_version'] ?? currentVersion,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id.serialize(),
      'date': date.serialize(),
      'form': form.serialize(),
      'form_version': formVersion.serialize(),
    };
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'date': FetchableFields.optional,
        'form': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({'*': VisaForm.fetchableFields})),
        'form_version': FetchableFields.mandatory,
      });

  @override
  String toString() {
    return 'StudentEvaluationVisa from $date, (form: ${form.toString()})';
  }
}
