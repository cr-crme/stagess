import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/screens/student/pages/form_dialogs/forms/visa_form_dialog.dart';
import 'package:stagess_common/models/persons/student_visa.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('StudentVisaForm');

class StudentVisaForm extends StatefulWidget {
  const StudentVisaForm({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentVisaForm> createState() => _StudentVisaFormState();
}

class _StudentVisaFormState extends State<StudentVisaForm> {
  static const _interline = 12.0;

  List<StudentVisa> get _evaluations =>
      StudentsProvider.of(context).fromId(widget.studentId).allVisa;
  // It is currently not possible to have more than one evaluation
  final int _currentEvaluationIndex = 0;

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
          onPressed: () => showVisaEvaluationFormDialog(
            context: context,
            formController: VisaFormController.fromStudentId(context,
                studentId: widget.studentId),
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
      'Building InternshipVisa for ${widget.studentId}',
    );

    return AnimatedExpandingCard(
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
                _buildAttitudeIsGood(),
                _buildAttitudeIsBad(),
                _buildGeneralAppreciation(),
                _buildShowOtherForms(),
              ],
            ),
        ],
      ),
    );
  }
}
