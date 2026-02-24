import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/screens/internship_forms/student_steps/attitude_evaluation_form_controller.dart';
import 'package:stagess/screens/internship_forms/student_steps/attitude_evaluation_screen.dart';
import 'package:stagess/screens/student/pages/pdf/attitude_pdf_template.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('InternshipEvaluationAttitude');

class EvaluationAttitude extends StatefulWidget {
  const EvaluationAttitude({super.key, required this.internshipId});

  final String internshipId;

  @override
  State<EvaluationAttitude> createState() => _EvaluationAttitudeState();
}

class _EvaluationAttitudeState extends State<EvaluationAttitude> {
  static const _interline = 12.0;
  int _currentEvaluationIndex = -1;
  int _nbPreviousEvaluations = -1;

  List<InternshipEvaluationAttitude> get _evaluations =>
      InternshipsProvider.of(context)
          .fromId(widget.internshipId)
          .attitudeEvaluations;

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
              _evaluations[_currentEvaluationIndex].attitude.meetsRequirements,
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
                  .attitude
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
                      .attitude
                      .generalAppreciation
                      .index]
                  .name,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Commentaires sur le stage',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              _evaluations[_currentEvaluationIndex].comments.isEmpty
                  ? 'Aucun commentaire'
                  : _evaluations[_currentEvaluationIndex].comments,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowOtherForms() {
    final controller = AttitudeEvaluationFormController.fromInternshipId(
      context,
      internshipId: widget.internshipId,
      evaluationIndex: _currentEvaluationIndex,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () => showAttitudeEvaluationDialog(
                context: context,
                formController: controller,
                editMode: false,
              ),
              child: const Text('Voir l\'évaluation détaillée'),
            ),
            SizedBox(width: 12),
            IconButton(
                onPressed: () {
                  showPdfDialog(
                    context,
                    pdfGeneratorCallback: (context, format) =>
                        generateAttitudeEvaluationPdf(context, format,
                            controller: controller),
                  );
                },
                icon: Icon(
                  Icons.picture_as_pdf,
                  color: Theme.of(context).colorScheme.primary,
                ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building AttitudeEvaluation for internship: ${widget.internshipId}',
    );

    _resetIndex();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: AnimatedExpandingCard(
        elevation: 0.0,
        header: (ctx, isExpanded) => Text(
          'C2. Attitudes et comportements',
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
                  _buildComment(),
                  _buildShowOtherForms(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
