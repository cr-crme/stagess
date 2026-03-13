import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/selectable_text_items.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

export 'package:stagess_common/models/generic/selectable_text_items.dart';

class ExperiencesAndAptitudes extends SelectableTextItem {
  ExperiencesAndAptitudes({
    super.id,
    super.text,
    super.isSelected,
  });
  ExperiencesAndAptitudes.fromSerialized(super.map) : super.fromSerialized();

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'text': FetchableFields.optional,
        'is_selected': FetchableFields.optional,
      });

  @override
  ExperiencesAndAptitudes copyWith({
    String? text,
    bool? isSelected,
  }) =>
      ExperiencesAndAptitudes(
        id: id,
        text: text ?? this.text,
        isSelected: isSelected ?? this.isSelected,
      );
}

class AttestationsAndMentions extends SelectableTextItem {
  AttestationsAndMentions({
    super.id,
    super.text,
    super.isSelected,
  });
  AttestationsAndMentions.fromSerialized(super.map) : super.fromSerialized();

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'text': FetchableFields.optional,
        'is_selected': FetchableFields.optional,
      });

  @override
  AttestationsAndMentions copyWith({
    String? text,
    bool? isSelected,
  }) =>
      AttestationsAndMentions(
        id: id,
        text: text ?? this.text,
        isSelected: isSelected ?? this.isSelected,
      );
}

class SstTraining extends SelectableTextItem {
  bool hide;

  SstTraining({
    super.id,
    required super.text,
    required super.isSelected,
    required this.hide,
  });
  SstTraining.fromSerialized(super.map)
      : hide = map?['hide'] ?? false,
        super.fromSerialized();

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

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'text': FetchableFields.optional,
        'is_selected': FetchableFields.optional,
        'hide': FetchableFields.optional,
      });

  @override
  SstTraining copyWith({
    String? text,
    bool? isSelected,
    bool? hide,
  }) {
    return SstTraining(
      id: id,
      text: text ?? this.text,
      isSelected: isSelected ?? this.isSelected,
      hide: hide ?? this.hide,
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

class Certificate extends SelectableTextItem {
  final int year;
  final String? specializationId;

  Certificate({
    super.id,
    required CertificateType certificateType,
    required super.isSelected,
    this.year = -1,
    this.specializationId,
  }) : super(text: certificateType.name);
  Certificate.fromSerialized(super.map)
      : year = map?['year'] ?? -1,
        specializationId = map?['specialization_id'],
        super.fromSerialized();

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'text': FetchableFields.optional,
        'year': FetchableFields.optional,
        'specialization_id': FetchableFields.optional,
      });

  @override
  Certificate copyWith({
    String? text,
    CertificateType? certificateType,
    bool? isSelected,
    int? year,
    String? specializationId,
  }) {
    if (text != null && certificateType != null) {
      throw Exception(
          'Cannot provide both text and certificateType when copying Certificate.');
    }
    return Certificate(
      id: id,
      certificateType:
          certificateType ?? CertificateType.fromString(text ?? this.text),
      isSelected: isSelected ?? this.isSelected,
      year: year ?? this.year,
      specializationId: specializationId ?? this.specializationId,
    );
  }

  CertificateType get certificateType => CertificateType.fromString(text);
}

class Skill extends SelectableTextItem {
  Skill({
    super.id,
    super.text,
    super.isSelected,
  });
  Skill.fromSerialized(super.map) : super.fromSerialized();

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'text': FetchableFields.optional,
        'is_selected': FetchableFields.optional,
      });

  @override
  Skill copyWith({
    String? text,
    bool? isSelected,
  }) =>
      Skill(
        id: id,
        text: text ?? this.text,
        isSelected: isSelected ?? this.isSelected,
      );
}

class Attitude extends SelectableTextItem {
  Attitude({
    super.id,
    super.text,
    super.isSelected,
  });
  Attitude.fromSerialized(super.map) : super.fromSerialized();

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'text': FetchableFields.optional,
        'is_selected': FetchableFields.optional,
      });

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
    String? text,
    bool? isSelected,
  }) =>
      Attitude(
        id: id,
        text: text ?? this.text,
        isSelected: isSelected ?? this.isSelected,
      );
}

class VisaEvaluation extends ItemSerializable {
  final List<ExperiencesAndAptitudes> experiencesAndAptitudes;
  final List<AttestationsAndMentions> attestationsAndMentions;
  final List<SstTraining> sstTrainings;

  final bool isGatewayToFmsAvailable;
  final List<Certificate> certificates;
  final List<Skill> skills;
  final String reference;

  final List<Attitude> forces;
  final List<Attitude> challenges;

  final String successConditions;

  VisaEvaluation({
    super.id,
    required this.experiencesAndAptitudes,
    required this.attestationsAndMentions,
    required this.sstTrainings,
    required this.isGatewayToFmsAvailable,
    required this.certificates,
    required this.skills,
    required this.reference,
    required this.forces,
    required this.challenges,
    required this.successConditions,
  });
  VisaEvaluation.fromSerialized(super.map)
      : experiencesAndAptitudes = (map?['experiences_and_aptitudes'] as List?)
                ?.map((e) => ExperiencesAndAptitudes.fromSerialized(e))
                .toList() ??
            [],
        attestationsAndMentions = (map?['attestation_and_mentions'] as List?)
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
        reference = StringExt.from(map?['reference']) ?? '',
        forces = (map?['forces'] as List?)
                ?.map((e) => Attitude.fromSerialized(e))
                .toList() ??
            [],
        challenges = (map?['challenges'] as List?)
                ?.map((e) => Attitude.fromSerialized(e))
                .toList() ??
            [],
        successConditions = StringExt.from(map?['success_conditions']) ?? '',
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'experiences_and_aptitudes': experiencesAndAptitudes.serialize(),
      'attestation_and_mentions': attestationsAndMentions.serialize(),
      'sst_trainings': sstTrainings.serialize(),
      'is_gateway_to_fms_available': isGatewayToFmsAvailable,
      'certificates': certificates.serialize(),
      'skills': skills.serialize(),
      'reference': reference.serialize(),
      'forces': forces.serialize(),
      'challenges': challenges.serialize(),
      'success_conditions': successConditions.serialize(),
    };
  }

  VisaEvaluation copyWith({
    List<ExperiencesAndAptitudes>? experiencesAndAptitudes,
    List<AttestationsAndMentions>? attestationsAndMentions,
    List<SstTraining>? sstTrainings,
    bool? isGatewayToFmsAvailable,
    List<Certificate>? certificates,
    List<Skill>? skills,
    String? reference,
    List<Attitude>? forces,
    List<Attitude>? challenges,
    String? successConditions,
  }) {
    return VisaEvaluation(
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
      reference: reference ?? this.reference,
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
        ', reference: $reference'
        ', forces: ${forces.toString()}'
        ', challenges: ${challenges.toString()}'
        ', successConditions: $successConditions'
        '}';
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'experiences_and_aptitudes': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': ExperiencesAndAptitudes.fetchableFields,
          })),
        'attestation_and_mentions': FetchableFields.mandatory
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
        'reference': FetchableFields.optional,
        'forces': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': Attitude.fetchableFields,
          })),
        'challenges': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': Attitude.fetchableFields,
          })),
        'success_conditions': FetchableFields.optional,
      });
}

class StudentVisa extends ItemSerializable {
  static const String currentVersion = '1.0.0';

  VisaEvaluation form;
  String
      formVersion; // The version of the evaluation form (so data can be parsed properly)

  StudentVisa({
    super.id,
    required this.form,
    required this.formVersion,
  });
  StudentVisa.fromSerialized(super.map)
      : form = VisaEvaluation.fromSerialized(map?['form'] ?? {}),
        formVersion = map?['form_version'] ?? currentVersion,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'form': form.serialize(),
      'form_version': formVersion,
    };
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'form': FetchableFields.mandatory
          ..addAll(
              FetchableFields.reference({'*': VisaEvaluation.fetchableFields})),
        'form_version': FetchableFields.mandatory,
      });

  @override
  String toString() {
    return 'StudentEvaluationVisa(form: $form.toString())';
  }
}
