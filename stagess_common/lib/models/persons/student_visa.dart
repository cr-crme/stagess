import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';

class ExperiencesAndAptitudes extends ItemSerializable {
  String text;
  bool isSelected;
  ExperiencesAndAptitudes({
    super.id,
    required this.text,
    required this.isSelected,
  });
  ExperiencesAndAptitudes.fromSerialized(super.map)
      : text = map?['text'] ?? '',
        isSelected = map?['is_selected'] ?? false,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'text': text,
      'is_selected': isSelected,
    };
  }

  @override
  String toString() {
    return 'ExperiencesAndAptitudes(text: $text, isSelected: $isSelected)';
  }
}

class VisaEvaluation extends ItemSerializable {
  final List<ExperiencesAndAptitudes> experiencesAndAptitudes;

  VisaEvaluation({
    super.id,
    required this.experiencesAndAptitudes,
  });
  VisaEvaluation.fromSerialized(super.map)
      : experiencesAndAptitudes = (map?['experiences_and_aptitudes'] as List?)
                ?.map((e) => ExperiencesAndAptitudes.fromSerialized(e))
                .toList() ??
            [],
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'experiences_and_aptitudes': experiencesAndAptitudes.serialize(),
    };
  }

  @override
  String toString() {
    return 'VisaEvaluation{'
        'experiencesAndAptitudes: ${experiencesAndAptitudes.toString()}'
        '}';
  }
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
        'form': FetchableFields.optional,
        'form_version': FetchableFields.mandatory,
      });

  @override
  String toString() {
    return 'StudentEvaluationVisa(form: $form.toString(), ';
  }
}
