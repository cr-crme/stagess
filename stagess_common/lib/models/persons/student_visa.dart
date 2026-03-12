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

  ExperiencesAndAptitudes.fromItem(SelectableTextItem item)
      : super(id: item.id, text: item.text, isSelected: item.isSelected);

  static FetchableFields get fetchableFields =>
      SelectableTextItem.fetchableFields;
}

class AttestationsAndMentions extends SelectableTextItem {
  AttestationsAndMentions({
    super.id,
    super.text,
    super.isSelected,
  });
  AttestationsAndMentions.fromSerialized(super.map) : super.fromSerialized();

  AttestationsAndMentions.fromItem(SelectableTextItem item)
      : super(id: item.id, text: item.text, isSelected: item.isSelected);

  static FetchableFields get fetchableFields =>
      SelectableTextItem.fetchableFields;
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

  SstTraining.fromItem(SelectableTextItem item)
      : hide = false,
        super(id: item.id, text: item.text, isSelected: item.isSelected);

  static List<String> get availableTrainings => [
        'Manutention sécuritaire',
        'Utilisation d\'un exacto',
        'Prévention des troubles musculosquelettiques',
        'Substances potentiellement dangereuses pour la santé',
        'Utilisation exemplaire des EPI (raison, tâche, comment / quel modèle choisir)'
            'comment les entretenir, comment les ajuster, comment les nettoyer, '
            'comment les mettre / enlever)',
        'Conduite de chariot élévateur',
        'Utilisation d\'échelles ou d\'escabeaux',
      ];

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

class VisaEvaluation extends ItemSerializable {
  final List<ExperiencesAndAptitudes> experiencesAndAptitudes;
  final List<AttestationsAndMentions> attestationsAndMentions;
  final List<SstTraining> sstTrainings;

  VisaEvaluation({
    super.id,
    required this.experiencesAndAptitudes,
    required this.attestationsAndMentions,
    required this.sstTrainings,
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
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'experiences_and_aptitudes': experiencesAndAptitudes.serialize(),
      'attestation_and_mentions': attestationsAndMentions.serialize(),
      'sst_trainings': sstTrainings.serialize(),
    };
  }

  @override
  String toString() {
    return 'VisaEvaluation{'
        'experiencesAndAptitudes: ${experiencesAndAptitudes.toString()}'
        ', attestationsAndMentions: ${attestationsAndMentions.toString()}'
        ', sstTrainings: ${sstTrainings.toString()}'
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
