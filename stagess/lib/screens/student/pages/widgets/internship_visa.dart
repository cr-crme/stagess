import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/screens/internship_forms/student_steps/visa_evaluation_form_controller.dart';
import 'package:stagess/screens/internship_forms/student_steps/visa_evaluation_screen.dart';
import 'package:stagess_common/models/internships/internship_evaluation_visa.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('InternshipVisa');

class InternshipVisa extends StatefulWidget {
  const InternshipVisa({super.key, required this.internshipId});

  final String internshipId;

  @override
  State<InternshipVisa> createState() => _InternshipVisaState();
}

class _InternshipVisaState extends State<InternshipVisa> {
  static const _interline = 12.0;
  int _currentEvaluationIndex = -1;
  int _nbPreviousEvaluations = -1;

  List<InternshipEvaluationVisa> get _evaluations =>
      InternshipsProvider.of(context)
          .fromId(widget.internshipId)
          .visaEvaluations;

  void _resetIndex() {
    if (_nbPreviousEvaluations != _evaluations.length) {
      _currentEvaluationIndex = _evaluations.length - 1;
      _nbPreviousEvaluations = _evaluations.length;
    }
  }

  Widget _buildLastEvaluation() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Row(
        children: [
          const Text('Évaluation du\u00a0: '),
          DropdownButton<int>(
            value: _currentEvaluationIndex,
            onChanged: (value) =>
                setState(() => _currentEvaluationIndex = value!),
            items: _evaluations
                .asMap()
                .keys
                .map(
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(
                      DateFormat(
                        'dd MMMM yyyy',
                        'fr_CA',
                      ).format(_evaluations[index].date),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttitudeIsGood() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conformes aux exigences',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: ItemizedText(
              _evaluations[_currentEvaluationIndex].form.meetsRequirements,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttitudeIsBad() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À améliorer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: ItemizedText(
              _evaluations[_currentEvaluationIndex]
                  .form
                  .doesNotMeetRequirements,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralAppreciation() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appréciation générale',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              GeneralAppreciation
                  .values[_evaluations[_currentEvaluationIndex]
                      .form
                      .generalAppreciation
                      .index]
                  .name,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowOtherForms() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Center(
        child: OutlinedButton(
          onPressed: () => showVisaEvaluationDialog(
            context: context,
            formController: VisaEvaluationFormController.fromInternshipId(
              context,
              internshipId: widget.internshipId,
              evaluationIndex: _currentEvaluationIndex,
            ),
            editMode: false,
          ),
          child: const Text('Voir l\'évaluation détaillée'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building InternshipVisa for internship: ${widget.internshipId}',
    );

    _resetIndex();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: AnimatedExpandingCard(
        elevation: 0.0,
        header: (ctx, isExpanded) => Text(
          'VISA',
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(color: Colors.black),
        ),
        child: Column(
          children: [
            if (_evaluations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Text('Aucune évaluation disponible pour ce stage.'),
              ),
            if (_evaluations.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLastEvaluation(),
                  _buildAttitudeIsGood(),
                  _buildAttitudeIsBad(),
                  _buildGeneralAppreciation(),
                  _buildShowOtherForms(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
