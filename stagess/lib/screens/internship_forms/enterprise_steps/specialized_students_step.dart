import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';

final _logger = Logger('SpecializedStudentsStep');

enum _Disabilities {
  autismSpectrumDisorder,
  languageDisorder,
  intellectualDisability,
  physicalDisability,
  mentalHealthDisorder,
  behavioralDifficulties;

  @override
  String toString() {
    switch (this) {
      case _Disabilities.autismSpectrumDisorder:
        return 'Un trouble du spectre de l\'autisme (TSA)';
      case _Disabilities.languageDisorder:
        return 'Un trouble du langage';
      case _Disabilities.intellectualDisability:
        return 'Une déficience intellectuelle';
      case _Disabilities.physicalDisability:
        return 'Une déficience physique';
      case _Disabilities.mentalHealthDisorder:
        return 'Un trouble de santé mentale';
      case _Disabilities.behavioralDifficulties:
        return 'Des difficultés comportementales';
    }
  }
}

class SpecializedStudentsStep extends StatefulWidget {
  const SpecializedStudentsStep({super.key});

  @override
  State<SpecializedStudentsStep> createState() =>
      SpecializedStudentsStepState();
}

class SpecializedStudentsStepState extends State<SpecializedStudentsStep> {
  final _formKey = GlobalKey<FormState>();
  final _hasDisabilitiesKey =
      GlobalKey<CheckboxWithOtherState<_Disabilities>>();

  bool _hasStudentHadDisabilities = false;
  List<_Disabilities> _disabilities = [];

  double _acceptanceTsa = -1;
  double get acceptanceTsa =>
      _disabilities.contains(_Disabilities.autismSpectrumDisorder)
          ? _acceptanceTsa
          : -1;

  double _acceptanceLanguageDisorder = -1;
  double get acceptanceLanguageDisorder =>
      _disabilities.contains(_Disabilities.languageDisorder)
          ? _acceptanceLanguageDisorder
          : -1;

  double _acceptanceIntellectualDisability = -1;
  double get acceptanceIntellectualDisability =>
      _disabilities.contains(_Disabilities.intellectualDisability)
          ? _acceptanceIntellectualDisability
          : -1;

  double _acceptancePhysicalDisability = -1;
  double get acceptancePhysicalDisability =>
      _disabilities.contains(_Disabilities.physicalDisability)
          ? _acceptancePhysicalDisability
          : -1;

  double _acceptanceMentalHealthDisorder = -1;
  double get acceptanceMentalHealthDisorder =>
      _disabilities.contains(_Disabilities.mentalHealthDisorder)
          ? _acceptanceMentalHealthDisorder
          : -1;

  double _acceptanceBehaviorDifficulties = -1;
  double get acceptanceBehaviorDifficulties =>
      _disabilities.contains(_Disabilities.behavioralDifficulties)
          ? _acceptanceBehaviorDifficulties
          : -1;

  Future<String?> validate() async {
    _logger.finer('Validating SpecializedStudentsStep');

    if (!_formKey.currentState!.validate()) {
      return 'Remplir tous les champs avec un *.';
    }
    _formKey.currentState!.save();
    return null;
  }

  Key _disabilityKey(_Disabilities disability) {
    switch (disability) {
      case _Disabilities.autismSpectrumDisorder:
        return const Key('acceptanceTSA');
      case _Disabilities.languageDisorder:
        return const Key('acceptanceLanguageDisorder');
      case _Disabilities.intellectualDisability:
        return const Key('acceptanceIntellectualDisability');
      case _Disabilities.physicalDisability:
        return const Key('acceptancePhysicalDisability');
      case _Disabilities.mentalHealthDisorder:
        return const Key('acceptanceMentalHealthDisorder');
      case _Disabilities.behavioralDifficulties:
        return const Key('acceptanceBehaviorDifficulties');
    }
  }

  double _getDisabilityValue(_Disabilities disability) {
    switch (disability) {
      case _Disabilities.autismSpectrumDisorder:
        return _acceptanceTsa;
      case _Disabilities.languageDisorder:
        return _acceptanceLanguageDisorder;
      case _Disabilities.intellectualDisability:
        return _acceptanceIntellectualDisability;
      case _Disabilities.physicalDisability:
        return _acceptancePhysicalDisability;
      case _Disabilities.mentalHealthDisorder:
        return _acceptanceMentalHealthDisorder;
      case _Disabilities.behavioralDifficulties:
        return _acceptanceBehaviorDifficulties;
    }
  }

  void _setDisabilityValue(_Disabilities disability, double value) {
    switch (disability) {
      case _Disabilities.autismSpectrumDisorder:
        _acceptanceTsa = value;
        break;
      case _Disabilities.languageDisorder:
        _acceptanceLanguageDisorder = value;
        break;
      case _Disabilities.intellectualDisability:
        _acceptanceIntellectualDisability = value;
        break;
      case _Disabilities.physicalDisability:
        _acceptancePhysicalDisability = value;
        break;
      case _Disabilities.mentalHealthDisorder:
        _acceptanceMentalHealthDisorder = value;
        break;
      case _Disabilities.behavioralDifficulties:
        _acceptanceBehaviorDifficulties = value;
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building SpecializedStudentsStep');

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _YesOrNoRadioTile(
            title:
                '* Est-ce que le ou la stagiaire avait des besoins '
                'particuliers\u00a0?',
            value: _hasStudentHadDisabilities,
            onChanged:
                (value) => setState(() => _hasStudentHadDisabilities = value),
          ),
          if (_hasStudentHadDisabilities)
            FormField(
              validator: (value) {
                for (final element
                    in _hasDisabilitiesKey.currentState!.selected) {
                  if (_getDisabilityValue(element) <= 0) {
                    return 'Sélectionner une valeur pour $element';
                  }
                }
                return null;
              },
              builder:
                  (errorState) => CheckboxWithOther<_Disabilities>(
                    key: _hasDisabilitiesKey,
                    title:
                        '* Évaluer la prise en charge de l\'entreprise par rapport '
                        'aux différents besoins de l\'élève s\'il ou elle avait:\u00a0:',
                    titleStyle: Theme.of(context).textTheme.titleSmall,
                    elements: _Disabilities.values,
                    elementStyleBuilder: (element, isSelected) {
                      var out = Theme.of(context).textTheme.titleSmall!;

                      if (errorState.hasError &&
                          _hasDisabilitiesKey.currentState!.selected.contains(
                            element,
                          ) &&
                          _getDisabilityValue(element) <= 0) {
                        out = out.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        );
                      }

                      return out;
                    },
                    showOtherOption: false,
                    subWidgetBuilder: (element, isSelected) {
                      return isSelected
                          ? Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 24.0,
                                bottom: 8.0,
                              ),
                              child: _RatingBarForm(
                                key: _disabilityKey(element),
                                initialValue: _getDisabilityValue(element),
                                validator:
                                    (value) =>
                                        value! <= 0
                                            ? 'Sélectionner une valeur'
                                            : null,
                                onRatingChanged:
                                    (newValue) =>
                                        _setDisabilityValue(element, newValue!),
                              ),
                            ),
                          )
                          : Container();
                    },
                    onOptionSelected:
                        (value) => setState(
                          () =>
                              _disabilities =
                                  _hasDisabilitiesKey.currentState!.selected,
                        ),
                  ),
            ),
        ],
      ),
    );
  }
}

class _YesOrNoRadioTile extends StatelessWidget {
  const _YesOrNoRadioTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup(
      groupValue: value,
      onChanged: (newValue) => onChanged(newValue!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: RadioListTile(
                  title: Text(
                    'Oui',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  value: true,
                ),
              ),
              SizedBox(
                width: 150,
                child: RadioListTile(
                  title: Text(
                    'Non',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  value: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingBarForm extends FormField<double> {
  const _RatingBarForm({
    super.key,
    super.initialValue = -1,
    super.validator,
    required void Function(double? rating) onRatingChanged,
  }) : super(onSaved: onRatingChanged, builder: _builder);

  static Widget _builder(FormFieldState<double> state) {
    final onRatingChanged = state.widget.onSaved!;

    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 12.0),
      child: RatingBar(
        initialRating: state.value!,
        ratingWidget: RatingWidget(
          full: Icon(
            Icons.star,
            color: Theme.of(state.context).colorScheme.secondary,
          ),
          half: Icon(
            Icons.star_half,
            color: Theme.of(state.context).colorScheme.secondary,
          ),
          empty: Icon(
            Icons.star_border,
            color: Theme.of(state.context).colorScheme.secondary,
          ),
        ),
        onRatingUpdate: (double value) {
          state.didChange(value);
          onRatingChanged(value);
        },
      ),
    );
  }
}
