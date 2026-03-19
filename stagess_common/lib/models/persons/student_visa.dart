import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/selectable_text_items.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

export 'package:stagess_common/models/generic/selectable_text_items.dart';

class ExperiencesAndAptitudes extends SelectableTextItem {
  ExperiencesAndAptitudes({
    super.id,
    required super.index,
    required super.text,
    required super.isSelected,
  });

  ExperiencesAndAptitudes.fromSerialized(super.map) : super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()..addAll({});

  static FetchableFields get fetchableFields =>
      SelectableTextItem.fetchableFields..addAll(FetchableFields.reference({}));

  @override
  ExperiencesAndAptitudes copyWith({
    String? text,
    int? index,
    bool? isSelected,
  }) =>
      ExperiencesAndAptitudes(
        id: id,
        index: index ?? this.index,
        text: text ?? this.text,
        isSelected: isSelected ?? this.isSelected,
      );
}

class AttestationsAndMentions extends SelectableTextItem {
  AttestationsAndMentions({
    super.id,
    required super.index,
    required super.text,
    required super.isSelected,
  });

  AttestationsAndMentions.fromSerialized(super.map) : super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()..addAll({});

  static FetchableFields get fetchableFields =>
      SelectableTextItem.fetchableFields..addAll(FetchableFields.reference({}));

  @override
  AttestationsAndMentions copyWith({
    String? text,
    int? index,
    bool? isSelected,
  }) =>
      AttestationsAndMentions(
        id: id,
        index: index ?? this.index,
        text: text ?? this.text,
        isSelected: isSelected ?? this.isSelected,
      );
}

class SstTraining extends SelectableTextItem {
  bool isHidden;

  SstTraining({
    super.id,
    required super.index,
    required String trainingId,
    required super.isSelected,
    required this.isHidden,
  }) : super(text: trainingId);

  SstTraining.fromSerialized(super.map)
      : isHidden = BoolExt.from(map?['is_hidden']) ?? false,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'is_hidden': isHidden.serialize(),
    });

  static FetchableFields get fetchableFields =>
      SelectableTextItem.fetchableFields
        ..addAll(FetchableFields.reference({
          'hidden': FetchableFields.optional,
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
    String? text,
    int? index,
    bool? isSelected,
    bool? isHidden,
  }) {
    return SstTraining(
      id: id,
      index: index ?? this.index,
      trainingId: text ?? this.text,
      isSelected: isSelected ?? this.isSelected,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  String get trainingId => text;
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
  final int? year;
  final String? specializationId;

  Certificate({
    super.id,
    required super.index,
    required CertificateType certificateType,
    required super.isSelected,
    this.year,
    this.specializationId,
  }) : super(text: certificateType.name);

  Certificate.fromSerialized(super.map)
      : year = IntExt.from(map?['year']),
        specializationId = StringExt.from(map?['specialization_id']),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()
    ..addAll({
      'year': year?.serialize(),
      'specialization_id': specializationId?.serialize(),
    });

  static FetchableFields get fetchableFields =>
      SelectableTextItem.fetchableFields
        ..addAll(FetchableFields.reference({
          'year': FetchableFields.optional,
          'specialization_id': FetchableFields.optional,
        }));

  @override
  Certificate copyWith({
    String? text,
    int? index,
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
      index: index ?? this.index,
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
    required super.index,
    required String skillId,
    super.isSelected,
  }) : super(text: skillId);

  Skill.fromSerialized(super.map) : super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()..addAll({});

  static FetchableFields get fetchableFields =>
      SelectableTextItem.fetchableFields..addAll(FetchableFields.reference({}));

  @override
  Skill copyWith({
    String? text,
    int? index,
    bool? isSelected,
  }) =>
      Skill(
        id: id,
        index: index ?? this.index,
        skillId: text ?? this.text,
        isSelected: isSelected ?? this.isSelected,
      );

  String get skillId => text;
}

class Attitude extends SelectableTextItem {
  Attitude({
    super.id,
    required super.index,
    required String attitudeId,
    required super.isSelected,
  }) : super(text: attitudeId);

  Attitude.fromSerialized(super.map) : super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => super.serializedMap()..addAll({});

  static FetchableFields get fetchableFields =>
      SelectableTextItem.fetchableFields..addAll(FetchableFields.reference({}));

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
    int? index,
    bool? isSelected,
  }) =>
      Attitude(
        id: id,
        index: index ?? this.index,
        attitudeId: text ?? this.text,
        isSelected: isSelected ?? this.isSelected,
      );

  String get attitudeId => text;
}

class VisaForm extends ItemSerializable {
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

  VisaForm({
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
        super.fromSerialized() {
    _sortAllByIndices();
  }

  void _sortAllByIndices() {
    experiencesAndAptitudes.sort((a, b) => a.index.compareTo(b.index));
    attestationsAndMentions.sort((a, b) => a.index.compareTo(b.index));
    sstTrainings.sort((a, b) => a.index.compareTo(b.index));
    certificates.sort((a, b) => a.index.compareTo(b.index));
    skills.sort((a, b) => a.index.compareTo(b.index));
    forces.sort((a, b) => a.index.compareTo(b.index));
    challenges.sort((a, b) => a.index.compareTo(b.index));
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
      'reference': reference.serialize(),
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
    String? reference,
    List<Attitude>? forces,
    List<Attitude>? challenges,
    String? successConditions,
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
